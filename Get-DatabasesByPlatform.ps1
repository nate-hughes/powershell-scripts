
#Import-Module SimplySql
#Remove-Module SimplySql

<#
#Run to create encrypted password file(s).
$credential = Get-Credential
$credential.Password | ConvertFrom-SecureString | Set-Content D:\CredStore\sbx.txt
#>

$mysql_array = @(
    [pscustomobject]@{name="prd-agent-desk";hostname="prd-agent-desk.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com";Platform="PL"}
    [pscustomobject]@{name="prd-agentdesk-queue-service-mysql";hostname="prd-agentdesk-queue-service-mysql.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com";Platform="PL"}
    [pscustomobject]@{name="prd-auth-identity-service";hostname="prd-auth-identity-service.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com";Platform="PL"}
    [pscustomobject]@{name="prd-bestegg-web";hostname="prd-bestegg-web.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com";Platform="PL"}
    [pscustomobject]@{name="prd-card";hostname="prd-card.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com";Platform="CC"}
    [pscustomobject]@{name="prd-collections";hostname="prd-collections.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com";Platform="PL"}
    [pscustomobject]@{name="prd-comm";hostname="prd-comm.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com";Platform="PL"}
    [pscustomobject]@{name="prd-csw";hostname="prd-csw.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com";Platform="PL"}
    [pscustomobject]@{name="prd-insights";hostname="prd-insights.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com";Platform="PL"}
    [pscustomobject]@{name="prd-loanpro-data-import-serverless";hostname="prd-loanpro-data-import-serverless.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com";Platform="PL"}
    [pscustomobject]@{name="prd-logging";hostname="prd-logging.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com";Platform="PL"}
    [pscustomobject]@{name="prd-mfgds";hostname="prd-mfgds.cnepzt3ilsdr.us-east-1.rds.amazonaws.com";Platform="PL"}
    [pscustomobject]@{name="prd-note-service";hostname="prd-note-service.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com";Platform="PL"}
    [pscustomobject]@{name="prd-ods-internal-tools";hostname="prd-ods-internal-tools.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com";Platform="PL"}
    [pscustomobject]@{name="prd-payment-domain-db";hostname="prd-payment-domain-db.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com";Platform="PL"}
    [pscustomobject]@{name="prd-payment-recon-db";hostname="prd-payment-recon-db.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com";Platform="PL"}
    [pscustomobject]@{name="prd-statements-api";hostname="prd-statements-api.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com";Platform="PL"}
)
$mysql_query = "SHOW DATABASES;"

$postgresql_array = @(
    [pscustomobject]@{name="prd-card-postgres";hostname="prd-card-postgres.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com";Platform="CC"}
    [pscustomobject]@{name="prd-customer-journey";hostname="prd-customer-journey.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com";Platform="PL"}
    [pscustomobject]@{name="prd-data-fabric";hostname="prd-data-fabric.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com";Platform="PL"}
    [pscustomobject]@{name="prd-opportunity";hostname="prd-opportunity.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com";Platform="PL"}
    [pscustomobject]@{name="prd-servicing-postgresql";hostname="prd-servicing-postgresql.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com";Platform="PL"}
    [pscustomobject]@{name="prd-twig";hostname="prd-twig.cluster-cnepzt3ilsdr.us-east-1.rds.amazonaws.com";Platform="PL"}
)
$postgresql_query = "select datname from pg_database where datistemplate = false and datname <> 'rdsadmin' order by datname;"

$sqlserver_array = @(
    [pscustomobject]@{name="PRDEGGDBS01";hostname="PRDEGGDBS01.mf.dou"}
    [pscustomobject]@{name="PRDEGGDBS02";hostname="PRDEGGDBS02.mf.dou"}
)
$sql_query = "SELECT db.name as [Database] FROM sys.availability_groups ag JOIN sys.dm_hadr_availability_replica_states ar ON ag.group_id = ar.group_id JOIN sys.databases db ON ar.replica_id = db.replica_id WHERE ar.role_desc = 'PRIMARY';"

$rds_username = "nate.hughes"
$rds_encrypted_password = Get-Content C:\CredStore\prd.txt | ConvertTo-SecureString
$rds_credential = New-Object System.Management.Automation.PsCredential($rds_username, $rds_encrypted_password)

$list_of_dbs = @()

$mysql_array | ForEach {
    $mysql_name = $_.name
    $mysql_hostname = $_.hostname
    $mysql_platform = $_.platform

    Try {        
        $mysql = Open-MySqlConnection  -Credential $rds_credential -Server $mysql_hostname -Port "3306"

        $mysql_databases = Invoke-SQLQuery -Query $mysql_query | Where-Object {$_.Database -notin ('tmp','sys','performance_schema','mysql')}

        $list_of_dbs += $mysql_databases | Select -Property @{Name = "Server"; Expression = {$mysql_name}}, @{Name = "Engine"; Expression = {"Aurora MySQL"}}, Database, @{Name = "Platform"; Expression = {$mysql_platform}}
    } Catch {
        
        Write-Host "Server: $mysql_name  Error: $_.Exception.Message" -ForegroundColor Red
    }
}

$postgresql_array | ForEach {
    $postgresql_name = $_.name
    $postgresql_hostname = $_.hostname
    $postgresql_platform = $_.platform

    Try {
        $pwd = $rds_credential.GetNetworkCredential().Password

        $DBConnectionString = "Driver={PostgreSQL Unicode(x64)};Server=$postgresql_hostname;Port=5432;Database=postgres;Uid=$rds_username;Pwd=$pwd;"
        $DBConn = New-Object System.Data.Odbc.OdbcConnection;
        $DBConn.ConnectionString = $DBConnectionString;
        $DBConn.Open();
        $DBCmd = $DBConn.CreateCommand();
        $DBCmd.CommandText = $postgresql_query;
        $postgresql_databases = $DBCmd.ExecuteReader();
        $Datatable = New-Object System.Data.DataTable
        $DataTable.Load($postgresql_databases)
        $DBConn.Close();

        ForEach ($row in $DataTable.Rows) {
            $customObject = [PSCustomObject]@{
                Server   = $postgresql_name
                Engine   = "Aurora PostgreSQL"
                Database = $row["datname"]
                Platform = $postgresql_platform
            }
    
            $list_of_dbs += $customObject
        }

    } Catch {
        
        Write-Host "Server: $postgresql_name  Error: $_.Exception.Message" -ForegroundColor Red
    }
}

$sqlserver_array | ForEach {
    $sqlserver = $_.hostname
    $sqlname = $_.name

    $sql_databases = Invoke-Sqlcmd -ServerInstance $sqlserver -Query $sql_query
    $list_of_dbs += $sql_databases | Select -Property @{Name = "Server"; Expression = {$sqlname}}, @{Name = "Engine"; Expression = {"SQL Server"}}, Database, @{Name = "Platform"; Expression = {"PL"}}
}

$list_of_dbs | Where-Object {$_.Platform -eq "PL"} | Export-Csv -Path C:\Temp\Loan.csv -NoTypeInformation
$list_of_dbs | Where-Object {$_.Platform -eq "CC"} | Export-Csv -Path C:\Temp\CreditCard.csv -NoTypeInformation
