# Step 1: Azure Login)
$subscriptionId = "<Subscription ID>"

# Azure PowerShell module "Az" and "Az.ResourceGraph" might need to be installed. Run "Install-Module Az.ResourceGraph" to install it. Also Install-Module AzTable.

# Step 2: Query data from Azure Resource Graph (ARG)
$storageAccountName = "<Storage Account Name>"
$tableName = "attackPaths"

Connect-AzAccount -SubscriptionId $subscriptionId

$query = "securityresources | where type == 'microsoft.security/attackpaths' | project name, display=tostring(properties.displayName)"
$argResults = Search-AzGraph -Subscription $subscriptionId -Query $query -First 1000

# Check if storage account exists
$storageAccount = Get-AzStorageAccount | Where-Object { $_.StorageAccountName -eq $storageAccountName }

if ($storageAccount -eq $null) {
    # Storage account doesn't exist, create a new one
    # Prompt for resource group name
    $resourceGroupName = Read-Host "Storage Account $storageAccountName not Found - Create New. Enter the Resource Group Name"
    # Check if resource group exists
    $resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
    if ($resourceGroup -eq $null) {
        # Resource group doesn't exist, create a new one
        # Prompt for resource group location
        $resourceGroupLocation = Read-Host "Resource Group not Found. Create New - Enter the Resource Group Location"
        $resourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation
        Write-Host "Resource group '$resourceGroupName' created successfully."
    } else {
        Write-Host "Using existing resource group '$resourceGroupName'."
    }    
    $storageAccount = New-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -SkuName Standard_LRS -Location $resourceGroupLocation
    Write-Host "Storage account '$storageAccountName' created successfully."
}

# Check if table exists
$tableExists = Get-AzStorageTable -Name $tableName -Context $storageAccount.Context -ErrorAction SilentlyContinue

if ($tableExists -eq $null) {
    # Table doesn't exist, create a new one
    Write-Host "Table $tableName not found. Create New"
    $table = New-AzStorageTable -Name $tableName -Context $storageAccount.Context
    Write-Host "Table '$tableName' created successfully."
}

# Import the AzTable module
Import-Module AzTable
# Create the storage context
$storageContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -AccountName $storageAccountName).Value[0]
# Retrieve a reference to a specific table
$storageTable = Get-AzStorageTable –Name $tableName –Context $storageContext
# Reference the CloudTable property of a specific table
$cloudTable = $storageTable.CloudTable


$currentTime = (Get-Date).ToUniversalTime()
$currentTimeFormatted = $currentTime.ToString("yyyy-MM-ddTHH:mm:ssZ")

# Step 3: Populate the table with data from ARG results
foreach ($result in $argResults) {
    $entityProperties = @{
        DisplayName = $result.display;
        LastUpdate = $currentTimeFormatted;
        Notified = "False";
        TimeGenerated = $currentTimeFormatted
    }

    Add-AzTableRow -Table $cloudTable -partitionKey "AttackPath" -rowKey $result.name -Property $entityProperties
}

Write-Host "Data populated successfully in table '$tableName'."