$failureCount = 0
$successCount = 0
$vmSuccessCount = 0
$vmssSuccessCount = 0
$arcSuccessCount = 0
$vmCount = 0
$vmssCount = 0
$arcCount = 0
$vmResponseMachines = $null
$vmssResponseMachines = $null
$arcResponseMachines = $null
$pricingReport = [System.Collections.Generic.List[object]]::new()

function Get-PricingReportEntry {
	param (
		[Parameter(Mandatory = $true)]
		$Machine,

		[Parameter(Mandatory = $true)]
		[string]$ResourceType,

		[Parameter(Mandatory = $true)]
		[string]$PricingUrl,

		[Parameter(Mandatory = $true)]
		$Token,

		[Parameter(Mandatory = $true)]
		[string]$RequestedOperation,

		[Parameter(Mandatory = $true)]
		[string]$OperationStatus,

		$OperationError
	)

	$resourceGroup = $null
	if ($Machine.id -match '/resourceGroups/([^/]+)') {
		$resourceGroup = $Matches[1]
	}

	try {
		$pricingResponse = Invoke-RestMethod -Method Get -Uri $PricingUrl -Token $Token -Authentication Bearer -ContentType "application/json" -TimeoutSec 120
		$pricingTier = $pricingResponse.properties.pricingTier
		$subPlan = $pricingResponse.properties.subPlan
		$effectivePlan = if ([string]::IsNullOrEmpty($subPlan)) { $pricingTier } else { "$pricingTier/$subPlan" }
		$inherited = if ($null -eq $pricingResponse.properties.inherited) { $null } else { [System.Convert]::ToBoolean($pricingResponse.properties.inherited) }

		return [PSCustomObject][ordered]@{
			serverName          = $Machine.name
			resourceType        = $ResourceType
			resourceGroup       = $resourceGroup
			resourceId          = $Machine.id
			requestedOperation  = $RequestedOperation
			operationStatus     = $OperationStatus
			operationError      = $OperationError
			effectivePlan       = $effectivePlan
			pricingTier         = $pricingTier
			subPlan             = $subPlan
			inherited           = $inherited
			inheritedFrom       = $pricingResponse.properties.inheritedFrom
			pricingQueryStatus  = "Succeeded"
			pricingQueryError   = $null
		}
	}
	catch {
		return [PSCustomObject][ordered]@{
			serverName          = $Machine.name
			resourceType        = $ResourceType
			resourceGroup       = $resourceGroup
			resourceId          = $Machine.id
			requestedOperation  = $RequestedOperation
			operationStatus     = $OperationStatus
			operationError      = $OperationError
			effectivePlan       = $null
			pricingTier         = $null
			subPlan             = $null
			inherited           = $null
			inheritedFrom       = $null
			pricingQueryStatus  = "Failed"
			pricingQueryError   = $_.Exception.Message
		}
	}
}

function Write-AzureRestError {
	param (
		[Parameter(Mandatory = $true)]
		[System.Management.Automation.ErrorRecord]$ErrorRecord,

		[Parameter(Mandatory = $true)]
		[string]$Context,

		[string]$Uri
	)

	Write-Host $Context -ForegroundColor Red
	if (-not [string]::IsNullOrEmpty($Uri)) {
		Write-Host "Request URI: $Uri" -ForegroundColor Red
	}
	Write-Host "Error: $($ErrorRecord.Exception.Message)" -ForegroundColor Red

	$responseProperty = $ErrorRecord.Exception.PSObject.Properties['Response']
	if ($null -ne $responseProperty -and $null -ne $responseProperty.Value) {
		$response = $responseProperty.Value
		$statusCodeProperty = $response.PSObject.Properties['StatusCode']
		if ($null -ne $statusCodeProperty) {
			Write-Host "Response StatusCode: $($statusCodeProperty.Value)" -ForegroundColor Red
		}

		$statusDescriptionProperty = $response.PSObject.Properties['StatusDescription']
		if ($null -eq $statusDescriptionProperty) {
			$statusDescriptionProperty = $response.PSObject.Properties['ReasonPhrase']
		}
		if ($null -ne $statusDescriptionProperty) {
			Write-Host "Response StatusDescription: $($statusDescriptionProperty.Value)" -ForegroundColor Red
		}
	}

	if ($null -ne $ErrorRecord.ErrorDetails -and -not [string]::IsNullOrEmpty($ErrorRecord.ErrorDetails.Message)) {
		Write-Host "Response details: $($ErrorRecord.ErrorDetails.Message)" -ForegroundColor Red
	}
}

# login:
$needLogin = $true
Try {
	$content = Get-AzContext
	if ($content)
	{
		$needLogin = ([string]::IsNullOrEmpty($content.Account))
	}
}
Catch
{
	if ($_ -like "*Login-AzAccount to login*")
	{
		$needLogin = $true
	}
	else
	{
		throw
	}
}

if ($needLogin)
{
	Write-Host -ForegroundColor "yellow" "Need to log in now! Look for login window!"
	Connect-Azaccount
}
# login - end

# get token
$token = (Get-AzAccessToken -AsSecureString).token
$expireson = Get-AzAccessToken | Select-Object -ExpandProperty expireson | Select-Object -ExpandProperty LocalDateTime

# Define variables for authentication and resource group
$SubscriptionId = Read-Host "Enter your SubscriptionId"
$mode = Read-Host "Enter 'RG' to set pricing for all resourced under a given Resource Group, or 'TAG' to set pricing for all resources with a given tagName and tagValue"
while($mode.ToLower() -ne "rg" -and $mode.ToLower() -ne "tag"){
	$mode = Read-Host "Enter 'RG' to set pricing for all resources under a given Resource Group, or 'TAG' to set pricing for all resources with a given tagName and tagValue"
}

if ($mode.ToLower() -eq "rg") {
    # Fetch resources under a given Resource Group
	$resourceGroupName = Read-Host "Enter the name of the resource group"
	$currentResourceUrl = $null
	try
	{
		# Get all virtual machines, VMSSs, and ARC machines in the resource group
		$vmUrl = "https://management.azure.com/subscriptions/" + $SubscriptionId + "/resourceGroups/$resourceGroupName/providers/Microsoft.Compute/virtualMachines?api-version=2021-04-01"
		do{
			$currentResourceUrl = $vmUrl
			$vmResponse = Invoke-RestMethod -Method Get -Uri $vmUrl -Token $token -Authentication Bearer
			$vmResponseMachines += $vmResponse.value 
			$vmUrl = $vmResponse.nextLink
		} while (![string]::IsNullOrEmpty($vmUrl))

		$vmssUrl = "https://management.azure.com/subscriptions/" + $SubscriptionId + "/resourceGroups/$resourceGroupName/providers/Microsoft.Compute/virtualMachineScaleSets?api-version=2021-04-01"
		do{
			$currentResourceUrl = $vmssUrl
			$vmssResponse = Invoke-RestMethod -Method Get -Uri $vmssUrl -Token $token -Authentication Bearer
			$vmssResponseMachines += $vmssResponse.value
			$vmssUrl = $vmssResponse.nextLink
		} while (![string]::IsNullOrEmpty($vmssUrl))
		
		$arcUrl = "https://management.azure.com/subscriptions/" + $SubscriptionId + "/resourceGroups/$resourceGroupName/providers/Microsoft.HybridCompute/machines?api-version=2022-12-27"
		do{
			$currentResourceUrl = $arcUrl
			$arcResponse = Invoke-RestMethod -Method Get -Uri $arcUrl -Token $token -Authentication Bearer
			$arcResponseMachines += $arcResponse.value
			write-host $arcUrl
			$arcUrl = $arcResponse.nextLink
		} while (![string]::IsNullOrEmpty($arcUrl))
	}
	catch 
	{
		Write-AzureRestError -ErrorRecord $_ -Context "Failed to get resources." -Uri $currentResourceUrl
		exit 1
	}
} elseif ($mode.ToLower() -eq "tag") {
    # Fetch resources with a given tagName and tagValue
    $tagName = Read-Host "Enter the name of the tag"
    $tagValue = Read-Host "Enter the value of the tag"
	$currentResourceUrl = $null
	
	try
	{
		# Get all virtual machines, VMSSs, and ARC machines in the resource group based on the given tag
		$vmUrl = "https://management.azure.com/subscriptions/" + $SubscriptionId + "/resources?`$filter=resourceType eq 'Microsoft.Compute/virtualMachines'&api-version=2021-04-01"
		do{
			$currentResourceUrl = $vmUrl
			$vmResponse = Invoke-RestMethod -Method Get -Uri $vmUrl -Token $token -Authentication Bearer
			$vmResponseMachines += $vmResponse.value | Where-Object {$_.tags.$tagName -eq $tagValue}
			$vmUrl = $vmResponse.nextLink
		} while (![string]::IsNullOrEmpty($vmUrl))
		
		$vmssUrl = "https://management.azure.com/subscriptions/" + $SubscriptionId + "/resources?`$filter=resourceType eq 'Microsoft.Compute/virtualMachineScaleSets'&api-version=2021-04-01"
		do{
			$currentResourceUrl = $vmssUrl
			$vmssResponse = Invoke-RestMethod -Method Get -Uri $vmssUrl -Token $token -Authentication Bearer
			$vmssResponseMachines += $vmssResponse.value | Where-Object {$_.tags.$tagName -eq $tagValue}
			$vmssUrl = $vmssResponse.nextLink
		} while (![string]::IsNullOrEmpty($vmssUrl))
		
		$arcUrl = "https://management.azure.com/subscriptions/" + $SubscriptionId + "/resources?`$filter=resourceType eq 'Microsoft.HybridCompute/machines'&api-version=2023-07-01"
		do{
			$currentResourceUrl = $arcUrl
			$arcResponse = Invoke-RestMethod -Method Get -Uri $arcUrl -Token $token -Authentication Bearer
			$arcResponseMachines += $arcResponse.value | Where-Object {$_.tags.$tagName -eq $tagValue}
			$arcUrl = $arcResponse.nextLink
		} while (![string]::IsNullOrEmpty($arcUrl))
	}
	catch 
	{
		Write-AzureRestError -ErrorRecord $_ -Context "Failed to get resources." -Uri $currentResourceUrl
		exit 1
	}
} else {
    Write-Host "Entered invalid mode. Exiting script."
	exit 1;
}
# Finished fetching machines, display found machines:
Write-Host "Found the following resources:" -ForegroundColor Green
write-host "Virtual Machines:"
$count = 0
foreach ($machine in $vmResponseMachines) {
	$count++
	Write-Host $count ": " ($machine.name)
	$vmCount = $count
}
Write-Host "-------------------"
write-host "Virtual Machine Scale Sets:"
$count = 0
foreach ($machine in $vmssResponseMachines) {
	$count++
	Write-Host $count ": " ($machine.name)
	$vmssCount = $count
}
Write-Host "-------------------"
write-host "ARC Machines:"
$count = 0
foreach ($machine in $arcResponseMachines) {
	$count++
	Write-Host $count ": " ($machine.name)
	$arcCount = $count
}
Write-Host "-----------------------------------------------------------------------"
write-host "`n"

$continue = Read-Host "Press any key to proceed or press 'N' to exit"

if ($continue.ToLower() -eq "n") {
	exit 0
}

Write-Host "-------------------"
$PricingTier = Read-Host "Enter the command set these resources - 'Free' or 'Standard' or 'Delete' or 'Read' (choosing 'Free' will remove the Defender protection; 'Standard' will enable the 'P1' subplan; 'Delete' will remove any explicitly set configuration (the resource will inherit the parent's configuration); 'Read' will read the current configuration)"
while($PricingTier.ToLower() -ne "free" -and $PricingTier.ToLower() -ne "standard" -and $PricingTier.ToLower() -ne "delete" -and $PricingTier.ToLower() -ne "read"){
$PricingTier = Read-Host "Enter the command for these resources - 'Free' or 'Standard' or 'Delete' or 'Read' (choosing 'Free' will remove the Defender protection; 'Standard' will enable the 'P1' subplan; 'Delete' will remove any explicitly set configuration (the resource will inherit the parent's configuration); 'Read' will read the current configuration)"
}

# Loop through each machine and update the pricing configuration
write-host "`n"
Write-Host "-------------------"
Write-Host "Processing (setting or reading) Virtual Machines:"
foreach ($machine in $vmResponseMachines) {
	# Check if need to renew the token	
    $currentTime = Get-Date
    
    Write-host "Token expires on: $expireson - currentTime: $currentTime"
    if ((get-date $currentTime) -ge (get-date $expireson)) {
		Start-Sleep -Seconds 2
        Write-host "Token expired - refreshing token:"
        $token = (Get-AzAccessToken -AsSecureString).token
        $expireson = Get-AzAccessToken | Select-Object -ExpandProperty expireson | Select-Object -ExpandProperty LocalDateTime

		Write-host "New token expires on: $expireson - currentTime: $currentTime"
    }
	
    $pricingUrl = "https://management.azure.com$($machine.id)/providers/Microsoft.Security/pricings/virtualMachines?api-version=2024-01-01"
    if($PricingTier.ToLower() -eq "free")
	{
		$pricingBody = @{
			"properties" = @{
				"pricingTier" = $PricingTier
			}
		}
	} else 
	{
		$subplan = "P1"
		$pricingBody = @{
			"properties" = @{
				"pricingTier" = $PricingTier
				"subPlan" = $subplan
			}
		}
	}
	Write-Host "Processing (setting or reading) pricing configuration for '$($machine.name)':"
	$operationStatus = "Failed"
	$operationError = $null
	try 
	{
		if($PricingTier.ToLower() -eq "delete")
		{
			$pricingResponse = Invoke-RestMethod -Method Delete -Uri $pricingUrl -Token $token -Authentication Bearer -ContentType "application/json" -TimeoutSec 120
			Write-Host "Successfully deleted pricing configuration for $($machine.name)" -ForegroundColor Green
			$successCount++
			$vmSuccessCount++
		} elseif ($PricingTier.ToLower() -eq "read")
        {
            $pricingResponse = Invoke-RestMethod -Method Get -Uri $pricingUrl -Token $token -Authentication Bearer -ContentType "application/json" -TimeoutSec 120
			Write-Host "Successfully read pricing configuration for $($machine.name): " -ForegroundColor Green
            Write-Host ($pricingResponse | ConvertTo-Json -Depth 100)
			$successCount++
			$vmSuccessCount++
        }
		else
		{
			$pricingResponse = Invoke-RestMethod -Method Put -Uri $pricingUrl -Token $token -Authentication Bearer -Body ($pricingBody | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 120
			Write-Host "Successfully updated pricing configuration for $($machine.name)" -ForegroundColor Green
			$successCount++
			$vmSuccessCount++
		}
		$operationStatus = "Succeeded"
	}
	catch {
		$failureCount++
		$operationError = $_.Exception.Message
		Write-AzureRestError -ErrorRecord $_ -Context "Failed to process pricing configuration for $($machine.name)." -Uri $pricingUrl
	}
	finally {
		[void]$pricingReport.Add((Get-PricingReportEntry -Machine $machine -ResourceType "VirtualMachine" -PricingUrl $pricingUrl -Token $token -RequestedOperation $PricingTier -OperationStatus $operationStatus -OperationError $operationError))
	}
	write-host "`n"
	Start-Sleep -Seconds 0.3
}

Write-Host "-------------------"
Write-Host "Processing (setting or reading) Virtual Machine Scale Sets:"
foreach ($machine in $vmssResponseMachines) {
	# Check if need to renew the token
    $currentTime = Get-Date
    
    Write-host "Token expires on: $expireson - currentTime: $currentTime"
    if ((get-date $currentTime) -ge (get-date $expireson)) {
		Start-Sleep -Seconds 2
        Write-host "Token expired - refreshing token:"
        $token = (Get-AzAccessToken -AsSecureString).token
        $expireson = Get-AzAccessToken | Select-Object -ExpandProperty expireson | Select-Object -ExpandProperty LocalDateTime

		Write-host "New token expires on: $expireson - currentTime: $currentTime"
    }
	
    $pricingUrl = "https://management.azure.com$($machine.id)/providers/Microsoft.Security/pricings/virtualMachines?api-version=2024-01-01"
    if($PricingTier.ToLower() -eq "free")
	{
		$pricingBody = @{
			"properties" = @{
				"pricingTier" = $PricingTier
			}
		}
	} else 
	{
		$subplan = "P1"
		$pricingBody = @{
			"properties" = @{
				"pricingTier" = $PricingTier
				"subPlan" = $subplan
			}
		}
	}
	Write-Host "Processing (setting or reading) pricing configuration for '$($machine.name)':"
	$operationStatus = "Failed"
	$operationError = $null
	try 
	{
		
		if($PricingTier.ToLower() -eq "delete")
		{
			$pricingResponse = Invoke-RestMethod -Method Delete -Uri $pricingUrl -Token $token -Authentication Bearer -ContentType "application/json" -TimeoutSec 120
			Write-Host "Successfully deleted pricing configuration for $($machine.name)" -ForegroundColor Green
			$successCount++
			$vmssSuccessCount++
		} elseif ($PricingTier.ToLower() -eq "read")
        {
            $pricingResponse = Invoke-RestMethod -Method Get -Uri $pricingUrl -Token $token -Authentication Bearer -ContentType "application/json" -TimeoutSec 120
			Write-Host "Successfully read pricing configuration for $($machine.name): " -ForegroundColor Green
            Write-Host ($pricingResponse | ConvertTo-Json -Depth 100)
			$successCount++
			$vmssSuccessCount++
        }
		else
		{
            $pricingResponse = Invoke-RestMethod -Method Put -Uri $pricingUrl -Token $token -Authentication Bearer -Body ($pricingBody | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 120
            Write-Host "Successfully updated pricing configuration for $($machine.name)" -ForegroundColor Green
            $successCount++
            $vmssSuccessCount++
        }
		$operationStatus = "Succeeded"
	}
	catch {
		$failureCount++
		$operationError = $_.Exception.Message
		Write-AzureRestError -ErrorRecord $_ -Context "Failed to process pricing configuration for $($machine.name)." -Uri $pricingUrl
	}
	finally {
		[void]$pricingReport.Add((Get-PricingReportEntry -Machine $machine -ResourceType "VirtualMachineScaleSet" -PricingUrl $pricingUrl -Token $token -RequestedOperation $PricingTier -OperationStatus $operationStatus -OperationError $operationError))
	}
	write-host "`n"
	Start-Sleep -Seconds 0.3
}

Write-Host "-------------------"
Write-Host "Processing (setting or reading) ARC Machine:"
foreach ($machine in $arcResponseMachines) {
	# Check if need to renew the token
    $currentTime = Get-Date
    
    Write-host "Token expires on: $expireson - currentTime: $currentTime"
    if ((get-date $currentTime) -ge (get-date $expireson)) {
		Start-Sleep -Seconds 2
        Write-host "Token expired - refreshing token:"
        $token = (Get-AzAccessToken -AsSecureString).token
        $expireson = Get-AzAccessToken | Select-Object -ExpandProperty expireson | Select-Object -ExpandProperty LocalDateTime

		Write-host "New token expires on: $expireson - currentTime: $currentTime"
    }
	
    $pricingUrl = "https://management.azure.com$($machine.id)/providers/Microsoft.Security/pricings/virtualMachines?api-version=2024-01-01"
    if($PricingTier.ToLower() -eq "free")
	{
		$pricingBody = @{
			"properties" = @{
				"pricingTier" = $PricingTier
			}
		}
	} else 
	{
		$subplan = "P1"
		$pricingBody = @{
			"properties" = @{
				"pricingTier" = $PricingTier
				"subPlan" = $subplan
			}
		}
	}
	Write-Host "Processing (setting or reading) pricing configuration for '$($machine.name)':"
	$operationStatus = "Failed"
	$operationError = $null
	try 
	{
		
		if($PricingTier.ToLower() -eq "delete")
		{
			$pricingResponse = Invoke-RestMethod -Method Delete -Uri $pricingUrl -Token $token -Authentication Bearer -ContentType "application/json" -TimeoutSec 120
			Write-Host "Successfully deleted pricing configuration for $($machine.name)" -ForegroundColor Green
			$successCount++
			$arcSuccessCount++
		} elseif ($PricingTier.ToLower() -eq "read")
        {
            $pricingResponse = Invoke-RestMethod -Method Get -Uri $pricingUrl -Token $token -Authentication Bearer -ContentType "application/json" -TimeoutSec 120
			Write-Host "Successfully read pricing configuration for $($machine.name): " -ForegroundColor Green
            Write-Host ($pricingResponse | ConvertTo-Json -Depth 100)
			$successCount++
			$arcSuccessCount++
        }
		else
		{
            $pricingResponse = Invoke-RestMethod -Method Put -Uri $pricingUrl -Token $token -Authentication Bearer -Body ($pricingBody | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 120
            Write-Host "Successfully updated pricing configuration for $($machine.name)" -ForegroundColor Green
            $successCount++
            $arcSuccessCount++
        }
		$operationStatus = "Succeeded"
	}
	catch {
		$failureCount++
		$operationError = $_.Exception.Message
		Write-AzureRestError -ErrorRecord $_ -Context "Failed to process pricing configuration for $($machine.name)." -Uri $pricingUrl
	}
	finally {
		[void]$pricingReport.Add((Get-PricingReportEntry -Machine $machine -ResourceType "ArcMachine" -PricingUrl $pricingUrl -Token $token -RequestedOperation $PricingTier -OperationStatus $operationStatus -OperationError $operationError))
	}
	write-host "`n"
	Start-Sleep -Seconds 0.3
}


Write-Host "-----------------------------------------------------------------------"
Write-Host "-----------------------------------------------------------------------"
write-host "`n"
# Write a conclusion of all what the script did
Write-Host "Summary of Pricing API results:"
Write-Host "-------------------"
Write-Host "Found Virtual Machines count:" $vmCount
Write-Host "Successfully processed (set or read) Virtual Machines count:" $vmSuccessCount -ForegroundColor Green
Write-Host "Failed processing (setting or reading) Virtual Machines count:" $($vmCount - $vmSuccessCount) -ForegroundColor $(if ($($vmCount - $vmSuccessCount) -gt 0) {'Red'} else {'Green'})
write-host "`n"
Write-Host "Found Virtual Machine Scale Sets count:" $vmssCount
Write-Host "Successfully processed (set or read) Virtual Machine Scale Sets result:" $vmssSuccessCount -ForegroundColor Green
Write-Host "Failed processing (setting or reading) Virtual Machine Scale Sets count:" $($vmssCount - $vmssSuccessCount) -ForegroundColor $(if ($($vmssCount - $vmssSuccessCount) -gt 0) {'Red'} else {'Green'})
write-host "`n"
Write-Host "Found ARC machines count:" $arcCount
Write-Host "Successfully processed (set or read) ARC Machines count:" $arcSuccessCount -ForegroundColor Green
Write-Host "Failed processing (setting or reading) ARC Machines count:" $($arcCount - $arcSuccessCount) -ForegroundColor $(if ($($arcCount - $arcSuccessCount) -gt 0) {'Red'} else {'Green'})
write-host "`n"
Write-Host "-------------------"
Write-Host "Overall"
Write-Host "Successfully processed (set or read) resources: $successCount" -ForegroundColor Green
Write-Host "Failures processing (setting or reading) resources: $failureCount" -ForegroundColor $(if ($failureCount -gt 0) {'Red'} else {'Green'})

$jsonReport = [PSCustomObject][ordered]@{
	generatedAtUtc     = (Get-Date).ToUniversalTime().ToString("o")
	subscriptionId     = $SubscriptionId
	requestedOperation = $PricingTier
	resourceCount      = $pricingReport.Count
	servers            = @($pricingReport)
}

write-host "`n"
Write-Host "JSON Pricing Report:"
$jsonReport | ConvertTo-Json -Depth 10

$tableProperties = @(
	@{ Label = "VM Name"; Expression = { $_.serverName } }
	@{ Label = "Resource Group"; Expression = { $_.resourceGroup } }
	@{ Label = "Type"; Expression = { $_.resourceType } }
	@{ Label = "Pricing Tier"; Expression = { $_.pricingTier } }
	@{ Label = "Effective Plan"; Expression = { $_.effectivePlan } }
	@{ Label = "Inherited"; Expression = { $_.inherited } }
	@{ Label = "Query Status"; Expression = { $_.pricingQueryStatus } }
)

write-host "`n"
Write-Host "Pricing Plan Summary:"
$pricingReport | Sort-Object serverName | Format-Table -AutoSize -Property $tableProperties
