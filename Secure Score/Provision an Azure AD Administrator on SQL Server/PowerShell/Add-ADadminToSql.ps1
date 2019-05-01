Login-AzAccount
Set-AzContext -Subscription <yourSubscription>

param(
    [parameter(Mandatory=$true)]
    [string]$SqlServerName,
    [parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    [parameter(Mandatory=$true)]
    [string]$DatabaseName,
    [parameter(Mandatory=$true)]
    [string]$AdUser
)
$ErrorActionPreference = "Stop"

# First get the SqlServer, then get the database(s)
try {$myDBs = Get-AzSqlServer -ServerName $SqlServerName -ResourceGroupName $ResourceGroupName | Get-AzSqlDatabase}
catch
{
    Write-Output "Something went wrong!"
    $ErrorMessage = $_.Exception.Message
    Write-Output ("Error Message: " + $ErrorMessage)
    Break
}

# Set the AzureAD admin account (or group) for each database (or a single one)
foreach($Db in $myDBs){
    if ($Db.DatabaseName -eq $DatabaseName){
        Write-Output ("Found database: " + $Db.DatabaseName)
        Write-Output ("Setting $AdUser as the SQL Admin....")
        try
        {
            Set-AzSqlServerActiveDirectoryAdministrator -ResourceGroupName $Db.ResourceGroupName -ServerName $Db.ServerName -DisplayName $AdUser
            Write-Output "Done...verifying..."
            Get-AzSqlServerActiveDirectoryAdministrator -ResourceGroupName $Db.ResourceGroupName -ServerName $Db.ServerName | Format-List
        }
        catch
        {
            Write-Output "Something went wrong!"
            $ErrorMessage = $_.Exception.Message
            Write-Output ("Error Message: " + $ErrorMessage)
            Break
        }
    }
}


