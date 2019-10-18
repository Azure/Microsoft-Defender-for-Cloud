param(
    [parameter(Mandatory=$true)]
    [string]$SqlServerName,
    [parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    [parameter(Mandatory=$true)]
    [string]$DatabaseName
)
$ErrorActionPreference = "Stop"

# Get the current Transparent Data Encryption status
Get-AzSqlDatabaseTransparentDataEncryption -ServerName $SqlServerName -ResourceGroupName $ResourceGroupName -DatabaseName $DatabaseName

# Set the current Transparent Data Encryption status to Enabled
Set-AzSqlDatabaseTransparentDataEncryption -ServerName $SqlServerName -ResourceGroupName $ResourceGroupName -DatabaseName $DatabaseName -State "Enabled"