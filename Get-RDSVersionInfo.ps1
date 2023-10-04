$region = "us-east-1"

# get available Aurora MySQL and Aurora PostgreSQL versions
$aurora_mysql_versions = aws rds describe-db-engine-versions --engine aurora-mysql --query '*[].[EngineVersion]' --output text --region $region
$aurora_postgresql_versions = aws rds describe-db-engine-versions --engine aurora-postgresql --query '*[].[EngineVersion]' --output text --region $region
# aws rds describe-db-engine-versions --engine sqlserver-ex --query '*[].[EngineVersion]' --output text --region $region
# aws rds describe-db-engine-versions --engine sqlserver-se --query '*[].[EngineVersion]' --output text --region $region


# get latest Aurora MySQL versions
$latest_versions = @($aurora_mysql_versions | Where-Object {$_ -like "5.7*"} | Sort-Object -Descending |
  Select-Object @{label='engine';expression={"aurora-mysql"}}, @{label='major_version';expression={"5.7"}}, @{label='version';expression={$_}} -First 1)
$latest_versions += @($aurora_mysql_versions | Where-Object {$_ -like "8.0*"} | Sort-Object -Descending |
  Select-Object @{label='engine';expression={"aurora-mysql"}}, @{label='major_version';expression={"8.0"}}, @{label='version';expression={$_}} -First 1)

# get latest Aurora PostgreSQL versions
$aurora_postgresql_versions | ForEach {
  $_.Substring(0,2)
} | Get-Unique |
  ForEach {
    $major_version = $_
    $latest_versions += @($aurora_postgresql_versions | Where-Object {$_ -like "$major_version*"} | Sort-Object {[Int]($_.Substring(3,$_.Length-3))} -Descending |
      Select-Object @{label='engine';expression={"aurora-postgresql"}}, @{label='major_version';expression={$major_version}}, @{label='version';expression={$_}} -First 1)
  }

$results = @()
$environments = @("sbx", "nonprod", "prd")
ForEach ($environment in $environments) {
    # get a complete list of RDS instances
    $aws_rds_instances = aws rds describe-db-instances --profile=$environment
    $rds_instances = $aws_rds_instances | ConvertFrom-Json

  # loop through RDS instances list and check for potential upgrades
  $rds_instances | ForEach-Object {$_.DBInstances} | Where-Object {$_.Engine -in ("aurora-mysql","aurora-postgresql")} |
    Select DBInstanceIdentifier,DBClusterIdentifier,Engine,EngineVersion,AutoMinorVersionUpgrade | ForEach-Object {
      $DBInstance = $_.DBInstanceIdentifier
      $DBCluster = $_.DBClusterIdentifier
      $DBEngine = $_.Engine
      $DBEngineVersion = $_.EngineVersion
      $AutoUpgradeEnabled = $_.AutoMinorVersionUpgrade
      $SortString = (($DBInstance.Replace("sbx-","")).Replace("uat-","")).Replace("prd-","")

      If ($latest_versions | Where-Object {($_.engine -eq $DBEngine) -and ($_.version -eq $DBEngineVersion)}) {
        $results += @([pscustomobject]@{Environment=$environment;DBInstance=$DBInstance;DBEngine=$DBEngine;CurrentVersion=$DBEngineVersion;AutoUpgradeEnabled=$AutoUpgradeEnabled;Action=" ";SortString=$SortString})
      } Else {
        [string]$max_version = $latest_versions | Where-Object {($_.engine -eq $DBEngine) -and (($_.major_version -eq $DBEngineVersion.Substring(0,3)) -or ($_.major_version -eq $DBEngineVersion.Substring(0,2)))} |
          Select-Object -ExpandProperty version
        $results += @([pscustomobject]@{Environment=$environment;DBInstance=$DBInstance;DBEngine=$DBEngine;CurrentVersion=$DBEngineVersion;AutoUpgradeEnabled=$AutoUpgradeEnabled ;Action="UPGRADE to $($max_version)";SortString=$SortString})
      }
    }
  }

$report = $results | Sort-Object SortString,{switch($_.Environment){"sbx" {1} "nonprod" {2} "prd" {3}}} |
  Select-Object @{Name="Environment";Expression={$_.Environment.Replace("nonprod","uat")}}, DBInstance, DBEngine, CurrentVersion, AutoUpgradeEnabled, Action

<#
$report = $results | Where-Object {($_.Environment -eq "sbx")} | Sort-Object DBInstance |
  Select-Object Environment, DBInstance, DBEngine, CurrentVersion, AutoUpgradeEnabled, Action

$report += $results | Where-Object {($_.Environment -eq "nonprod")} | Sort-Object DBInstance |
  Select-Object Environment, DBInstance, DBEngine, CurrentVersion, AutoUpgradeEnabled, Action

$report += $results | Where-Object {($_.Environment -eq "prd")} | Sort-Object DBInstance |
  Select-Object Environment, DBInstance, DBEngine, CurrentVersion, AutoUpgradeEnabled, Action
#>

$report | Format-Table -AutoSize
# $report | Export-Csv -Path D:\Temp\RDSVersionInfo.csv -NoTypeInformation
