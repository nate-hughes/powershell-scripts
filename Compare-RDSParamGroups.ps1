$profile = "prd"
$src_param_group = "default.mysql5.7-db-ffjrpcyrm4apcvmvfupmozcate-upgrade"
$tgt_param_group = "default.aurora-mysql5.7"

$tgt_params = aws rds describe-db-parameters --db-parameter-group-name $tgt_param_group --query "Parameters[*].{Name:ParameterName,Value:ParameterValue}" --profile $profile | ConvertFrom-Json
$src_params = aws rds describe-db-parameters --db-parameter-group-name $src_param_group --query "Parameters[*].{Name:ParameterName,Value:ParameterValue}" --profile $profile | ConvertFrom-Json

$tgt_params | ForEach {
    $tgt_name = $_.Name
    $tgt_value = $_.Value

    $src_params | Where {$_.Name -eq $tgt_name -and $_.Value -ne $tgt_value} | Select -Property Name, Value, @{Name = "Target Value"; Expression = {$tgt_value}}
}
