Project title
Author: Michael Morten Sonne

PowerShell script to create custom Azure RBAC role based on output from Cloud Infrastructure Entitlement Management (CIEM) access report in .CSV format.

## How to use the script ##

Input data:

Create a custom Azure RBAC role based on CIEM access report in .CSV format and display the unique access scopes and count in the console
> PS C:\> .\'Create Azure RBAC Role based on CIEM access report - used access scopes.ps1' -CsvFilePath "C:\Temp\Actions.csv"

Create a custom Azure RBAC role based on CIEM access report in .CSV format and display the unique access scopes and count in a grid view (usefull for large datasets)
> PS C:\> .\'Create Azure RBAC Role based on CIEM access report - used access scopes.ps1' -GridView -CsvFilePath "C:\Temp\Actions.csv"

How to create Azure RBAC role based on report:

1. Connect to Azure via Az module in PowerShell (Connect-AzAccount - if not logged in, a login promt will show up automaticly..)
2. The script will prompt for the name and description of the custom role to be created.
3. The script will prompt for confirmation before creating the custom role.
4. The script will prompt for the path to the CSV file containing the CIEM access report.
5. The script will prompt for the resource group or subscription to scope the custom role to.
6. The script will prompt for confirmation before creating the custom role.
7. Role is now created in Azure - check in your selected Azure Subscription you selected to create the new RBAC role

## Read more ##

https://blog.sonnes.cloud/defender-for-cloud-permissions-management-new-features-added-to-cloud-infrastructure-entitlement-management-ciem/

https://learn.microsoft.com/en-us/azure/defender-for-cloud/enable-permissions-management
