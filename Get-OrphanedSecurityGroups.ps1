$profile = "env"
$security_group_id = "sg-"

# Run the AWS CLI command to describe security groups
$security_group_json = aws ec2 describe-security-groups --output json --profile $profile --group-ids $security_group_id

# Convert the JSON output to PowerShell objects
$security_group = $security_group_json | ConvertFrom-Json

$security_group.SecurityGroups.IpPermissions.UserIdGroupPairs | Sort-Object -Property GroupId | Select-Object @{Name='CheckedGroupId'; Expression={$_.GroupId}} -Unique

Write-Output ""
Write-Output "OrphanedGroupId:"
Write-Output "----------------"

foreach ($group_id in $security_group.SecurityGroups.IpPermissions.UserIdGroupPairs | Sort-Object -Property GroupId | Select-Object GroupId -Unique) {
    $GroupId = $group_id.GroupId
    $network_interfaces = aws ec2 describe-network-interfaces --profile $profile --filters Name=group-id,Values=$GroupId | ConvertFrom-Json
    if ($network_interfaces.NetworkInterfaces.Length -eq 0) {
        $GroupId
    }
}

