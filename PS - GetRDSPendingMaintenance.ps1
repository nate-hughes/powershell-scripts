# PULL SBX 
$sbx_actions = aws rds describe-pending-maintenance-actions --profile=sbx | ConvertFrom-Json
$sbx_maint = aws rds describe-db-instances --profile=sbx --query "DBInstances[*].{InstanceIdentifier:DBInstanceIdentifier, EngineVersion:EngineVersion, MaintenanceWindow:PreferredMaintenanceWindow, PendingChanges:PendingModifiedValues}" | ConvertFrom-Json
# PULL UAT 
$uat_actions = aws rds describe-pending-maintenance-actions --profile=nonprod| ConvertFrom-Json
$uat_maint = aws rds describe-db-instances --profile=nonprod --query "DBInstances[*].{InstanceIdentifier:DBInstanceIdentifier, EngineVersion:EngineVersion, MaintenanceWindow:PreferredMaintenanceWindow, PendingChanges:PendingModifiedValues}" | ConvertFrom-Json
# PULL PRD 
$prd_actions = aws rds describe-pending-maintenance-actions --profile=prd | ConvertFrom-Json
$prd_maint = aws rds describe-db-instances --profile=prd --query "DBInstances[*].{InstanceIdentifier:DBInstanceIdentifier, EngineVersion:EngineVersion, MaintenanceWindow:PreferredMaintenanceWindow, PendingChanges:PendingModifiedValues}" | ConvertFrom-Json

$dataTable = New-Object System.Data.DataTable
$dataTable.Columns.Add("EnvOrder", [int])
$dataTable.Columns.Add("Environment", [string])
$dataTable.Columns.Add("ARN", [string])
$dataTable.Columns.Add("InstanceName", [string])
$dataTable.Columns.Add("Action", [string])
$dataTable.Columns.Add("Description", [string])
$dataTable.Columns.Add("MaintenanceWindow", [string])
$dataTable.Columns.Add("PendingChanges", [string])

$environment = "sbx"
foreach ($action in $sbx_actions.PendingMaintenanceActions) {
    $arn = $action.ResourceIdentifier
    $instanceName = ($arn -split ":")[-1]
    $details = $action.PendingMaintenanceActionDetails[0]
    $maintAction = $details.Action
    $description = $details.Description

    foreach ($maint in $sbx_maint | Where-Object {$_.InstanceIdentifier -eq $instanceName}) {
        $maintWindow = $maint.MaintenanceWindow
        $pendingChanges = $maint.PendingChanges
    }
    
    $row = $dataTable.NewRow()
    $row["EnvOrder"] = 1
    $row["Environment"] = $environment
    $row["ARN"] = $arn
    $row["InstanceName"] = $instanceName
    $row["Action"] = $maintAction
    $row["Description"] = $description
    $row["MaintenanceWindow"] = $maintWindow
    $row["PendingChanges"] = $pendingChanges
    $dataTable.Rows.Add($row)
}

$environment = "uat"
foreach ($action in $uat_actions.PendingMaintenanceActions) {
    $arn = $action.ResourceIdentifier
    $instanceName = ($arn -split ":")[-1]
    $details = $action.PendingMaintenanceActionDetails[0]
    $maintAction = $details.Action
    $description = $details.Description

    foreach ($maint in $uat_maint | Where-Object {$_.InstanceIdentifier -eq $instanceName}) {
        $maintWindow = $maint.MaintenanceWindow
        $pendingChanges = $maint.PendingChanges
    }

    $row = $dataTable.NewRow()
    $row["EnvOrder"] = 2
    $row["Environment"] = $environment
    $row["ARN"] = $arn
    $row["InstanceName"] = $instanceName
    $row["Action"] = $maintAction
    $row["Description"] = $description
    $row["MaintenanceWindow"] = $maintWindow
    $row["PendingChanges"] = $pendingChanges
    $dataTable.Rows.Add($row)
}

$environment = "prd"
foreach ($action in $prd_actions.PendingMaintenanceActions) {
    $arn = $action.ResourceIdentifier
    $instanceName = ($arn -split ":")[-1]
    $details = $action.PendingMaintenanceActionDetails[0]
    $maintAction = $details.Action
    $description = $details.Description

    foreach ($maint in $prd_maint | Where-Object {$_.InstanceIdentifier -eq $instanceName}) {
        $maintWindow = $maint.MaintenanceWindow
        $pendingChanges = $maint.PendingChanges
    }

    $row = $dataTable.NewRow()
    $row["EnvOrder"] = 3
    $row["Environment"] = $environment
    $row["ARN"] = $arn
    $row["InstanceName"] = $instanceName
    $row["Action"] = $maintAction
    $row["Description"] = $description
    $row["MaintenanceWindow"] = $maintWindow
    $row["PendingChanges"] = $pendingChanges
    $dataTable.Rows.Add($row)
}


$sortedTable = $dataTable | ForEach-Object {
    ## Extract base name (logical service) by stripping sbx/uat/prd prefix
    #$baseName = ($_.InstanceName -replace "^(?:sbx|uat|prd)-", "") -replace "-instance-[0-9]$", ""
    $environment = if ($_.Environment -eq "uat") { "nonprod" } else { $_.Environment }
    $applyCLI = if ($_.Action -eq "system-update") {
                    "aws rds apply-pending-maintenance-action --resource-identifier " + $_.ARN + " --apply-action system-update --opt-in-type next-maintenance --profile " + $environment
                } else {
                    $null
                }
    [PSCustomObject]@{
        EnvOrder          = $_.EnvOrder
        Environment       = $_.Environment
        InstanceName      = $_.InstanceName
        Action            = $_.Action
        Description       = $_.Description
        MaintenanceWindow = $_.MaintenanceWindow
        PendingChanges    = $_.PendingChanges
        #BaseName          = $baseName
        ApplyCLI          = $applyCLI
    }
} | Sort-Object EnvOrder, InstanceName

# Now display the sorted table (excluding the helper props)
$sortedTable | Select-Object Environment, InstanceName, Action, Description, MaintenanceWindow, PendingChanges, ApplyCLI | Format-Table -AutoSize

# Output to a CSV file
$today = Get-Date -Format "yyyyMMdd"
$exportPath = "D:\Temp\rds_maint_$today.csv"
$sortedTable | Select-Object Environment, InstanceName, Action, Description, MaintenanceWindow, PendingChanges, ApplyCLI | Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8

