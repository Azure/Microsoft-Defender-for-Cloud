function New-EPDSCAzureGuestConfigurationPolicyPackage {
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
        [string]$storageSKUName = 'Standard_LRS',
        [Parameter(Mandatory = $false,
            HelpMessage = '[string] Provide policy scope, default to same subscription of target Resource Group, can also choose Management Group')]
        [ValidateSet('subscription', 'managementGroup')]
        [string]$policyScope = 'subscription'
    )

    Write-Host "Connecting to Azure..." -NoNewLine
    Connect-AzAccount | Out-Null

    # Select Management Group for policy scope
    $managementGroupId = $null
    if ($policyScope -eq 'managementGroup') {
        $managementGroupId = Select-ManagementGroup
    }

    # Select a subscription to create Resource Group and Storage Account
    Select-Subscription
    
    Write-Host "Done" -ForegroundColor Green

    Write-Host "Checking if policy already published, if so incrementing version..."
    $PublishedPolicy = $null
    $PublishedPolicy = Get-AzPolicyDefinition | Where-Object {$_.Properties.DisplayName -eq 'Monitor Antivirus'}
    if ($PublishedPolicy) {
        $PreviousVersion = $null
        [version]$PreviousVersion = $PublishedPolicy.Properties.Metadata.guestConfiguration.version
        [version]$NewVersion = [version]::new($PreviousVersion.Major,$PreviousVersion.Minor,$PreviousVersion.Build+1)
    } else {
        [version]$NewVersion = [version]::new(1,0,0)
    }

    [string]$Version = $NewVersion.ToString()

    $PackageName = "MonitorAntivirus_$Version" 

    Write-Host "Compiling Configuration into a MOF file..." -NoNewLine
    if (Test-Path 'MonitorAntivirus') {
        Remove-Item "MonitorAntivirus" -Recurse -Force -Confirm:$false
    }
    & "$PSScriptRoot/Configurations/MonitorAntivirus.ps1" | Out-Null
    Write-Host "Done" -ForegroundColor Green

    Write-Host "Generating Guest Configuration Package..." -NoNewLine
    
    New-GuestConfigurationPackage -Name $PackageName `
        -Configuration "$env:Temp/MonitorAntivirus/MonitorAntivirus.mof" -Force | Out-Null
    Write-Host "Done" -ForegroundColor Green

    Write-Host "Publishing Package to Azure Storage..." -NoNewLine
    $Url = Publish-EPDSCPackage -ResourceGroupName $ResourceGroupName `
        -StorageAccountName $StorageAccountName.ToLower() `
        -StorageSKUName $StorageSKUName `
        -ResourceGroupLocation $ResourceGroupLocation `
        -Version $Version
    Write-Host "Done" -ForegroundColor Green

    Write-Host "Generating Guest Configuration Policy..." -NoNewLine
    if (Test-Path 'policies') {
        Remove-Item "policies" -Recurse -Force -Confirm:$false
    }
    Import-LocalizedData -BaseDirectory "$PSScriptRoot/ParameterFiles/" `
        -FileName "EPAntivirusStatus.Params.psd1" `
        -BindingVariable ParameterValues | Out-Null
    
    New-GuestConfigurationPolicy `
        -ContentUri $Url `
        -DisplayName 'Monitor Antivirus' `
        -Description 'Audit if a given Antivirus Software is not enabled on Windows machine.' `
        -Path './policies' `
        -Platform 'Windows' `
        -Version $Version `
        -Parameter $ParameterValues -Verbose | Out-Null
    Write-Host "Done" -ForegroundColor Green

    Write-Host "Publishing Guest Configuration Policy..." -NoNewLine
    switch ($policyScope) {
        subscription { Publish-GuestConfigurationPolicy -Path ".\policies" -Verbose | Out-Null }
        managementGroup { Publish-GuestConfigurationPolicy -Path ".\policies" -ManagementGroupName $managementGroupId -Verbose | Out-Null }
    }
    Write-Host "Done" -ForegroundColor Green
}

function Publish-EPDSCPackage {
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
        $ResourceGroupLocation,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Version
    )

    $resourceGroup = Get-AzResourceGroup $ResourceGroupName -ErrorAction "SilentlyContinue"
    if ($null -eq $resourceGroup) {
        $resourceGroup = New-AzResourceGroup -Name $ResourceGroupName `
            -Location $ResourceGroupLocation
    }

    $storageAccount = Get-AzStorageAccount -Name $StorageAccountName `
        -ResourceGroupName $ResourceGroupName -ErrorAction "SilentlyContinue"
    if ($null -eq $storageAccount) {
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
    $blobName = "MonitorAntivirus_$Version.zip"

    Set-AzStorageblobcontent -File $($env:Temp + "/MonitorAntivirus_$Version/MonitorAntivirus_$Version.zip") `
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

function Select-Subscription {
    $subscriptions = Get-AzSubscription | Where-Object { $_.State -eq "Enabled" }

    # If there are more than one subscriptions, select which one to deploy to
    if ($subscriptions.count -gt 1) {
        $numberedSubscriptions = @()
        For ($i = 0; $i -lt $subscriptions.count; $i++) {
            $numberedSubscriptions += $subscriptions[$i] | Select-Object @{Name = 'No'; Expression = { $i + 1 } }, Name, Id, TenantId
        }
        
        [int]$subNumber = $null
        do {
            Write-Host "Select from following subscriptions to create Resource Group and Storage Account"
            Write-Host ($numberedSubscriptions | Format-Table | Out-String)
    
            $subNumber = Read-Host "Select No"
        } until ($subNumber -and ($subNumber -match "^\d+$") -and ($subNumber -le ($numberedSubscriptions.count)) -and ($subNumber -ge 1))

        Set-AzContext $numberedSubscriptions[$subNumber - 1].Name | Out-Null
    }
    else {
        Write-Error "Cannot find any subscription"
        exit
    }
}

function Get-AzCachedAccessToken() {
    $ErrorActionPreference = 'Stop'
  
    if (-not (Get-Module Az.Accounts)) {
        Import-Module Az.Accounts
    }
    $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    if (-not $azProfile.Accounts.Count) {
        Write-Error "Ensure you have logged in before calling this function."    
    }
  
    $currentAzureContext = Get-AzContext
    $profileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azProfile)
    Write-Debug ("Getting access token for tenant" + $currentAzureContext.Tenant.TenantId)
    $token = $profileClient.AcquireAccessToken($currentAzureContext.Tenant.TenantId)
    $token.AccessToken
}

function Get-AzBearerToken() {
    $ErrorActionPreference = 'Stop'
    ('Bearer {0}' -f (Get-AzCachedAccessToken))
}

function Select-ManagementGroup {

    # Get authentication token from cached credential
    $bearerToken = Get-AzBearerToken
    $authHeader = @{ }
    $authHeader.Add('authorization', $bearerToken)

    $managementGroups = @()

    # Get top manamgenet groups names
    $uri = "https://management.azure.com/providers/Microsoft.Management/managementGroups?api-version=2020-02-01"

    $topMGsResponse = @()
    $topMGsResponse = Invoke-RestMethod -Method Get -Uri $uri -Headers $authHeader

    if ($topMGsResponse) {
        $topMGs = @()
        foreach ($topMG in $topMGsResponse.value) {
            $topMGs += $topMG | Select-Object name, @{Name = 'displayName'; Expression = { $_.properties | Select-Object -ExpandProperty displayName } }, id
        }
        $managementGroups += $topMGs
    }
    else {
        Write-Error "Unable to find any top level management groups"
        exit
    }

    # Get descendants management groups
    foreach ($topMG in $topMGs) {
        $topMGId = $topMG.name
        $uri = "https://management.azure.com/providers/Microsoft.Management/managementGroups/$topMGId/descendants?api-version=2020-02-01"
        $descendantMGsResponse = $null
        $descendantMGsResponse = Invoke-RestMethod -Method Get -Uri $uri -Headers $authHeader
        if ($descendantMGsResponse) {
            foreach ($descendantMG in $descendantMGsResponse.value) {
                if ($descendantMG.type -eq 'Microsoft.Management/managementGroups') {
                    $managementGroups += $descendantMG | Select-Object name, @{Name = 'displayName'; Expression = { $_.properties | Select-Object -ExpandProperty displayName } }, id
                }
            }
        }
    }

    # Add number to each management group
    $numberedMGs = @()
    For ($i = 0; $i -lt $managementGroups.count; $i++) {
        $numberedMGs += $managementGroups[$i] | Select-Object @{Name = 'No'; Expression = { $i + 1 } }, Name, displayName, id
    }

    # Select which management group you want to deploy the policy into:
    [int]$subNumber = $null
    do {
        Write-Host "Select from following management groups"
        Write-Host ($numberedMGs | Format-Table | Out-String)

        $subNumber = Read-Host "Select No"
    } until ($subNumber -and ($subNumber -match "^\d+$") -and ($subNumber -le ($numberedMGs.count)) -and ($subNumber -ge 1))
    
    $numberedMGs[$subNumber - 1].name
}