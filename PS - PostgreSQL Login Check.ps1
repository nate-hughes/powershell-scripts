
<#
#Run to create encrypted password file(s).
$credential = Get-Credential
$credential.Password | ConvertFrom-SecureString | Set-Content D:\CredStore\sbx.txt
#>

$search = "hughes"

$postgresql_array = @(
    [pscustomobject]@{name="sbx-card-postgres";hostname="sbx-card-postgres.cluster-cweluei2okuj.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="sbx-data-fabric";hostname="sbx-data-fabric.cluster-cweluei2okuj.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="sbx-mxlevel0-postgres";hostname="sbx-mxlevel0-postgres.cluster-cweluei2okuj.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="sbx-opportunity";hostname="sbx-opportunity.cluster-cweluei2okuj.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="sbx-servicing-postgresql";hostname="sbx-servicing-postgresql.cluster-cweluei2okuj.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="sbx-twig";hostname="sbx-twig.cluster-cweluei2okuj.us-east-1.rds.amazonaws.com"}
    
    [pscustomobject]@{name="uat-card-postgres";hostname="uat-card-postgres.cluster-cnnwq2bskppf.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="uat-customer-journey";hostname="uat-customer-journey.cluster-cnnwq2bskppf.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="uat-data-fabric";hostname="uat-data-fabric.cluster-cnnwq2bskppf.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="uat-mxlevel0-postgres";hostname="uat-mxlevel0-postgres.cluster-cnnwq2bskppf.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="uat-opportunity";hostname="uat-opportunity.cluster-cnnwq2bskppf.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="uat-servicing-postgresql";hostname="uat-servicing-postgresql.cluster-cnnwq2bskppf.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="uat-twig";hostname="uat-twig.cluster-cnnwq2bskppf.us-east-1.rds.amazonaws.com"}
    
    [pscustomobject]@{name="prd-card-postgres";hostname="prd-card-postgres.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="prd-customer-journey";hostname="prd-customer-journey.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="prd-data-fabric";hostname="prd-data-fabric.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="prd-mxlevel0-postgres";hostname="prd-mxlevel0-postgres.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="prd-opportunity";hostname="prd-opportunity.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="prd-powercurve";hostname="prd-powercurve.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="prd-servicing-postgresql";hostname="prd-servicing-postgresql.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com"}
    [pscustomobject]@{name="prd-twig";hostname="prd-twig.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com"}
)
$query = "select usename from pg_user where usename like '%$search%'"

$username = "nate.hughes"
$sbx_encrypted_password = Get-Content D:\CredStore\sbx.txt | ConvertTo-SecureString
$uat_encrypted_password = Get-Content D:\CredStore\uat.txt | ConvertTo-SecureString
$prd_encrypted_password = Get-Content D:\CredStore\prd.txt | ConvertTo-SecureString

$postgresql_array | ForEach {
    $postgresql_name = $_.name
    $postgresql_hostname = $_.hostname
    $environment = $postgresql_name.substring(0,3)
    
    $encrypted_password = Switch ($environment) {
        "sbx" {$sbx_encrypted_password;break}
        "uat" {$uat_encrypted_password;break}
        "prd" {$prd_encrypted_password;break}
    }

    Try {
        $credential = New-Object System.Management.Automation.PsCredential($username, $encrypted_password)
        $pwd = $credential.GetNetworkCredential().Password

        $DBConnectionString = "Driver={PostgreSQL Unicode(x64)};Server=$postgresql_hostname;Port=5432;Database=postgres;Uid=$username;Pwd=$pwd;"
        $DBConn = New-Object System.Data.Odbc.OdbcConnection;
        $DBConn.ConnectionString = $DBConnectionString;
        $DBConn.Open();
        $DBCmd = $DBConn.CreateCommand();
        $DBCmd.CommandText = $query;
        $users = $DBCmd.ExecuteReader();
        $Datatable = New-Object System.Data.DataTable
        $DataTable.Load($users)
        $DBConn.Close();

        $DataTable | Select -Property @{Name = "Server"; Expression = {$postgresql_name}}, @{Name = "User"; Expression = {$DataTable.usename}}, @{Name = "Drop"; Expression = {"DROP USER '" + $DataTable.usename + "';"}}
    } Catch {
        
        Write-Host "Server: $postgresql_name  Error: $_.Exception.Message" -ForegroundColor Red
    }
}
