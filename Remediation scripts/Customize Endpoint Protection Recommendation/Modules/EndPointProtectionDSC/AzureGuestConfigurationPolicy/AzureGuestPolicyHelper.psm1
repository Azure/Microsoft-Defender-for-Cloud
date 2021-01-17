function New-EPDSCAzureGuestConfigurationPolicyPackage
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true,
            HelpMessage = '[string] Resource Group Name')]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroupName,
        [Parameter(Mandatory = $false,
            HelpMessage = '[string] Location')]
        [string]$ResourceGroupLocation = 'eastus',
        [Parameter(Mandatory = $true,
            HelpMessage = '[string] Storage Account Name')]
        [ValidateNotNullOrEmpty()]
        [string]$storageAccountName,
        [Parameter(Mandatory = $false,
            HelpMessage = '[string] Storage SKU Name')]
        [string]$storageSKUName = 'Standard_LRS'
    )

    Write-Host "Connecting to Azure..." -NoNewLine
    Connect-AzAccount | Out-Null
    $subscriptions = Get-AzSubscription | Where-Object {$_.State -eq "Enabled"}

    # If there are more than one subscriptions, select which one to deploy to
    if ($subscriptions.count -gt 1) {
        $numberedSubscriptions = @()
        For ($i=0; $i -lt $subscriptions.count; $i++) {
            $numberedSubscriptions += $subscriptions[$i] | Select-Object @{Name = 'No'; Expression = {$i+1}},Name,Id, TenantId
        }
        
        Write-Host "Select from following subscriptions"
        $numberedSubscriptions | Format-Table

        $subNumber = Read-Host "Select No"
        Set-AzContext $numberedSubscriptions[$subNumber-1].Name | Out-Null
    }
    
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

    # Wait until storage account is successfully created
    do {
        Start-Sleep -Seconds 3
    } until (Get-AzStorageAccount -Name $StorageAccountName `
    -ResourceGroupName $ResourceGroupName -ErrorAction "SilentlyContinue")
    # Get Storage Context
    $storageContext = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName `
        -Name $StorageAccountName | `
        ForEach-Object { $_.Context }

    # Enable Static Web
    Enable-AzStorageStaticWebsite -Context $storageContext
    
    # Upload to static web
    $blobName = "MonitorAntivirus.zip"

    Set-AzStorageblobcontent -File $($env:Temp + "/MonitorAntivirus/MonitorAntivirus.zip") `
        -Container `$web `
        -Blob $blobName `
        -Context $storageContext `
        -Force | Out-Null

    # Re-read Storage account and obtain static web URL
    $storageAccount = Get-AzStorageAccount -Name $StorageAccountName `
        -ResourceGroupName $ResourceGroupName
    
    $url = $storageAccount.PrimaryEndpoints.Web + $blobName
    
    # Check to make sure the url is good

    $response = $null
    do {
        try { $response = Invoke-WebRequest -Uri $url -UseBasicParsing } catch {}           
        Start-Sleep -Seconds 3
    } until ($response -and ($response.StatusCode -eq 200))

    return $url
}