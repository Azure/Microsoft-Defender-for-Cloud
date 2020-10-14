function New-EPDSCAzureGuestConfigurationPolicyPackage
{
    [CmdletBinding()]
    param()

    $ResourceGroupName     = Read-Host "Resource Group Name"
    $ResourceGroupLocation = Read-Host "Location"
    $storageContainerName  = Read-Host "Storage Container Name"
    $storageAccountName    = Read-Host "Storage Account Name"
    $storageSKUName        = Read-Host "Storage SKU Name"

    if ([System.String]::IsNullOrEmpty($storageSKUName))
    {
        $storageSKUName = "Standard_LRS"
    }

    if ([System.String]::IsNullOrEmpty($ResourceGroupLocation))
    {
        $storageSKUName = "eastus"
    }

    Write-Host "Connecting to Azure..." -NoNewLine
    Connect-AzAccount | Out-Null
    Write-Host "Done" -ForegroundColor Green

    Write-Host "Compiling Configuration into a MOF file..." -NoNewLine
    if (Test-Path 'MonitorAntivirus')
    {
        Remove-Item "MonitorAntivirus" -Recurse -Force -Confirm:$false
    }
    & "$PSScriptRoot/Configurations/MonitorAntivirus.ps1" | Out-Null
    Write-Host "Done" -ForegroundColor Green

    Write-Host "Generating Guest Configuration Package..." -NoNewLine
    $package = New-GuestConfigurationPackage -Name MonitorAntivirus `
                                  -Configuration "$env:Temp/MonitorAntivirus/MonitorAntivirus.mof"
    Write-Host "Done" -ForegroundColor Green

    Write-Host "Publishing Package to Azure Storage..." -NoNewLine
    $Url = Publish-EPDSCPackage -ResourceGroupName $ResourceGroupName `
        -StorageAccountName $StorageAccountName.ToLower() `
        -StorageContainerName $StorageContainerName.ToLower() `
        -StorageSKUName $StorageSKUName `
        -ResourceGroupLocation $ResourceGroupLocation
    Write-Host "Done" -ForegroundColor Green

    Write-Host "Generating Guest Configuration Policy..." -NoNewLine
    if (Test-Path 'policies')
    {
        Remove-Item "policies" -Recurse -Force -Confirm:$false
    }
    Import-LocalizedData -BaseDirectory "$PSScriptRoot/ParameterFiles/" `
        -FileName "EPAntivirusStatus.Params.psd1" `
        -BindingVariable ParameterValues
    $policy = New-GuestConfigurationPolicy `
        -ContentUri $Url `
        -DisplayName 'Monitor Antivirus' `
        -Description 'Audit if a given Antivirus Software is not enabled on Windows machine.' `
        -Path './policies' `
        -Platform 'Windows' `
        -Version 1.0.0 `
        -Parameter $ParameterValues -Verbose
    Write-Host "Done" -ForegroundColor Green

    Write-Host "Publishing Guest Configuration Policy..." -NoNewLine
    $publishedPolicies = Publish-GuestConfigurationPolicy -Path ".\policies" -Verbose
    Write-Host "Done" -ForegroundColor Green
}

function Publish-EPDSCPackage 
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param(
        [Parameter(Mandatory = $true)]
        [System.String]
        $ResourceGroupName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $StorageAccountName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $StorageContainerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $StorageSKUName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ResourceGroupLocation
    )

    $resourceGroup     = Get-AzResourceGroup $ResourceGroupName -ErrorAction "SilentlyContinue"
    if ($null -eq $resourceGroup)
    {
        $resourceGroup = New-AzResourceGroup -Name $ResourceGroupName `
            -Location $ResourceGroupLocation
    }

    $storageAccount = Get-AzStorageAccount -Name $StorageAccountName `
        -ResourceGroupName $ResourceGroupName -ErrorAction "SilentlyContinue"
    if ($null -eq $storageAccount)
    {
        $storageAccount = New-AzStorageAccount -Name $StorageAccountName `
            -ResourceGroupName $ResourceGroupName `
            -SkuName $StorageSKUName `
            -Location $ResourceGroupLocation
    }

    # Get Storage Context
    $storageContext = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName `
        -Name $StorageAccountName | `
        ForEach-Object { $_.Context }

    $storageContainer = Get-AzStorageContainer $StorageContainerName `
        -Context $storageContext -ErrorAction "SilentlyContinue"
    if ($null -ne $storageContainer)
    {
        while ($null -ne $storageContainer)
        {
            Start-Sleep 2
            $storageContainer = Get-AzStorageContainer $StorageContainerName `
                -Context $storageContext -ErrorAction "SilentlyContinue"
        }
        Remove-AzStorageContainer -Name $StorageContainerName `
            -Context $storageContext -Force -Confirm:$false
    }

    $storageContainer = New-AzStorageContainer -Name $StorageContainerName `
            -Context $storageContext -Permission Container

    # Upload file
    $blobName = "MonitorAntivirus.zip"
    $Blob = Set-AzStorageBlobContent -Context $storageContext `
        -Container $StorageContainerName `
        -File $($env:Temp + "/MonitorAntivirus/MonitorAntivirus.zip") `
        -Blob $blobName `
        -Force

    # Get url with SAS token
    $StartTime = (Get-Date)
    $ExpiryTime = $StartTime.AddYears('3')  # THREE YEAR EXPIRATION
    $SAS = New-AzStorageBlobSASToken -Context $storageContext `
        -Container $StorageContainerName `
        -Blob $blobName `
        -StartTime $StartTime `
        -ExpiryTime $ExpiryTime `
        -Permission rl `
        -FullUri

    # Output
    return $SAS
}