<# 
.SYNOPSIS
  Check Aurora clusters for MySQL Slow Query Log and PostgreSQL pg_stat_statements.

.PARAMETER Profile
  Optional AWS CLI profile name.

.PARAMETER Region
  Optional AWS region (e.g., us-east-1). Uses CLI/Env defaults if omitted.

.PARAMETER Output
  One of: table (default), json, csv

.PARAMETER OutFile
  When -Output csv, path to write the CSV.

.PARAMETER IncludeInstanceChecks
  Additionally check instance-level parameter groups (slower; helpful if your org sets MySQL slow_query_log at the instance level).
#>

[CmdletBinding()]
param(
  [string]$Profile,
  [string]$Region,
  [ValidateSet('table','json','csv')]
  [string]$Output = 'table',
  [string]$OutFile,
  [switch]$IncludeInstanceChecks
)

# Build common AWS CLI args
$awsArgs = @()
if ($Profile) { $awsArgs += @('--profile', $Profile) }
if ($Region)  { $awsArgs += @('--region',  $Region)  }

function Get-ClusterParamRecord {
  param([string]$GroupName, [string]$ParamName)
  $query = "Parameters[?ParameterName=='$ParamName']|[0]"
  try {
    $json = aws rds describe-db-cluster-parameters `
      --db-cluster-parameter-group-name $GroupName `
      --query $query @awsArgs | ConvertFrom-Json
    return $json
  } catch {
    return $null
  }
}

function Get-DBParamRecord {
  param([string]$GroupName, [string]$ParamName)
  $query = "Parameters[?ParameterName=='$ParamName']|[0]"
  try {
    $json = aws rds describe-db-parameters `
      --db-parameter-group-name $GroupName `
      --query $query @awsArgs | ConvertFrom-Json
    return $json
  } catch {
    return $null
  }
}

function Test-Truthy {
  param($Value)
  if ($null -eq $Value) { return $false }
  $s = "$Value".ToLower()
  return @('1','on','true','yes','enabled') -contains $s
}

$results = @()

# Get all Aurora DB clusters
try {
  $clusters = aws rds describe-db-clusters @awsArgs | ConvertFrom-Json
} catch {
  Write-Error "Failed to call 'aws rds describe-db-clusters'. Ensure AWS CLI is installed/configured. $_"
  exit 1
}

foreach ($c in $clusters.DBClusters) {
  $clusterId = $c.DBClusterIdentifier
  $engine    = $c.Engine
  $clusterPG = $c.DBClusterParameterGroup
  $cwSlowExport = ($c.EnabledCloudwatchLogsExports -contains 'slowquery')

  if ($engine -like 'aurora-mysql*') {
    # Prefer cluster-level check; also optionally check instance-level
    $p = Get-ClusterParamRecord -GroupName $clusterPG -ParamName 'slow_query_log'
    $val = if ($p) { $p.ParameterValue } else { $null }
    $enabled = Test-Truthy $val

    $results += [pscustomobject]@{
      Scope        = 'Cluster'
      ClusterId    = $clusterId
      Engine       = $engine
      Parameter    = 'slow_query_log'
      Value        = $val
      Enabled      = $enabled
      ParamGroup   = $clusterPG
      CWLogExport  = if ($cwSlowExport) { 'slowquery' } else { '' }
      Notes        = if ($cwSlowExport) { 'CloudWatch export for slowquery is enabled' } else { '' }
    }

    if ($IncludeInstanceChecks) {
      foreach ($m in $c.DBClusterMembers) {
        $instId = $m.DBInstanceIdentifier
        try {
          $inst = aws rds describe-db-instances --db-instance-identifier $instId @awsArgs | ConvertFrom-Json
          $dbPGs = $inst.DBInstances[0].DBParameterGroups
        } catch {
          $dbPGs = @()
        }
        foreach ($g in $dbPGs) {
          $gname = $g.DBParameterGroupName
          $pi = Get-DBParamRecord -GroupName $gname -ParamName 'slow_query_log'
          $ival = if ($pi) { $pi.ParameterValue } else { $null }
          $ien = Test-Truthy $ival
          $results += [pscustomobject]@{
            Scope        = 'Instance'
            ClusterId    = $clusterId
            InstanceId   = $instId
            Engine       = $engine
            Parameter    = 'slow_query_log'
            Value        = $ival
            Enabled      = $ien
            ParamGroup   = $gname
            CWLogExport  = if ($cwSlowExport) { 'slowquery' } else { '' }
            Notes        = if ($null -eq $ival) { 'Parameter not found in instance PG (may be cluster-level)' } else { '' }
          }
        }
      }
    }

  } elseif ($engine -like 'aurora-postgresql*') {
    # Check shared_preload_libraries for pg_stat_statements at cluster level
    $p = Get-ClusterParamRecord -GroupName $clusterPG -ParamName 'shared_preload_libraries'
    $val = if ($p) { $p.ParameterValue } else { $null }
    $pgssEnabled = $false
    if ($val) {
      $pgssEnabled = $val -match '(^|,)\s*pg_stat_statements(\s*|,|$)'
    }

    $results += [pscustomobject]@{
      Scope        = 'Cluster'
      ClusterId    = $clusterId
      Engine       = $engine
      Parameter    = 'shared_preload_libraries'
      Value        = $val
      Enabled      = $pgssEnabled
      ParamGroup   = $clusterPG
      CWLogExport  = ''
      Notes        = if ($pgssEnabled) { 'pg_stat_statements present' } else { 'pg_stat_statements missing' }
    }

    if ($IncludeInstanceChecks) {
      foreach ($m in $c.DBClusterMembers) {
        $instId = $m.DBInstanceIdentifier
        try {
          $inst = aws rds describe-db-instances --db-instance-identifier $instId @awsArgs | ConvertFrom-Json
          $dbPGs = $inst.DBInstances[0].DBParameterGroups
        } catch {
          $dbPGs = @()
        }
        foreach ($g in $dbPGs) {
          $gname = $g.DBParameterGroupName
          $pi = Get-DBParamRecord -GroupName $gname -ParamName 'shared_preload_libraries'
          $ival = if ($pi) { $pi.ParameterValue } else { $null }
          $ien = $false
          if ($ival) { $ien = $ival -match '(^|,)\s*pg_stat_statements(\s*|,|$)' }
          $results += [pscustomobject]@{
            Scope        = 'Instance'
            ClusterId    = $clusterId
            InstanceId   = $instId
            Engine       = $engine
            Parameter    = 'shared_preload_libraries'
            Value        = $ival
            Enabled      = $ien
            ParamGroup   = $gname
            CWLogExport  = ''
            Notes        = if ($null -eq $ival) { 'Not typically set at instance level for Aurora PG' } else { '' }
          }
        }
      }
    }
  }
}

# Output
if ($Output -eq 'json') {
  $results | ConvertTo-Json -Depth 6
} elseif ($Output -eq 'csv') {
  if (-not $OutFile) { Write-Error "When -Output csv, you must supply -OutFile."; exit 2 }
  $results | Export-Csv -NoTypeInformation -Path $OutFile
  Write-Host "Wrote $OutFile"
} else {
  $results | Sort-Object Engine, ClusterId, Scope, Parameter |
    Format-Table ClusterId, Engine, Scope, InstanceId, Parameter, Value, Enabled, ParamGroup, CWLogExport, Notes -AutoSize
}
