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
$accessToken = Get-AzAccessToken | Select-Object -ExpandProperty token
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
	try
	{
		# Get all virtual machines, VMSSs, and ARC machines in the resource group
		$vmUrl = "https://management.azure.com/subscriptions/" + $SubscriptionId + "/resourceGroups/$resourceGroupName/providers/Microsoft.Compute/virtualMachines?api-version=2021-04-01"
		do{
			$vmResponse = Invoke-RestMethod -Method Get -Uri $vmUrl -Headers @{Authorization = "Bearer $accessToken"}
			$vmResponseMachines += $vmResponse.value 
			$vmUrl = $vmResponse.nextLink
		} while (![string]::IsNullOrEmpty($vmUrl))

		$vmssUrl = "https://management.azure.com/subscriptions/" + $SubscriptionId + "/resourceGroups/$resourceGroupName/providers/Microsoft.Compute/virtualMachineScaleSets?api-version=2021-04-01"
		do{
			$vmssResponse = Invoke-RestMethod -Method Get -Uri $vmssUrl -Headers @{Authorization = "Bearer $accessToken"}
			$vmssResponseMachines += $vmssResponse.value
			$vmssUrl = $vmssResponse.nextLink
		} while (![string]::IsNullOrEmpty($vmssUrl))
		
		$arcUrl = "https://management.azure.com/subscriptions/" + $SubscriptionId + "/resourceGroups/$resourceGroupName/providers/Microsoft.HybridCompute/machines?api-version=2022-12-27"
		do{
			$arcResponse = Invoke-RestMethod -Method Get -Uri $arcUrl -Headers @{Authorization = "Bearer $accessToken"}
			$arcResponseMachines += $arcResponse.value
			write-host $arcUrl
			$arcUrl = $arcResponse.nextLink
		} while (![string]::IsNullOrEmpty($arcUrl))
	}
	catch 
	{
		Write-Host "Failed to Get resources! " -ForegroundColor Red
		Write-Host "Response StatusCode:" $_.Exception.Response.StatusCode.value__  -ForegroundColor Red
		Write-Host "Response StatusDescription:" $_.Exception.Response.StatusDescription -ForegroundColor Red
		Write-Host "Error from response:" $_.ErrorDetails -ForegroundColor Red
	}
} elseif ($mode.ToLower() -eq "tag") {
    # Fetch resources with a given tagName and tagValue
    $tagName = Read-Host "Enter the name of the tag"
    $tagValue = Read-Host "Enter the value of the tag"
	
	try
	{
		# Get all virtual machines, VMSSs, and ARC machines in the resource group based on the given tag
		$vmUrl = "https://management.azure.com/subscriptions/" + $SubscriptionId + "/resources?`$filter=resourceType eq 'Microsoft.Compute/virtualMachines'&api-version=2021-04-01"
		do{
			$vmResponse = Invoke-RestMethod -Method Get -Uri $vmUrl -Headers @{Authorization = "Bearer $accessToken"}
			$vmResponseMachines += $vmResponse.value | where {$_.tags.$tagName -eq $tagValue}
			$vmUrl = $vmResponse.nextLink
		} while (![string]::IsNullOrEmpty($vmUrl))
		
		$vmssUrl = "https://management.azure.com/subscriptions/" + $SubscriptionId + "/resources?`$filter=resourceType eq 'Microsoft.Compute/virtualMachineScaleSets'&api-version=2021-04-01"
		do{
			$vmssResponse = Invoke-RestMethod -Method Get -Uri $vmssUrl -Headers @{Authorization = "Bearer $accessToken"}
			$vmssResponseMachines += $vmssResponse.value | where {$_.tags.$tagName -eq $tagValue}
			$vmssUrl = $vmssResponse.nextLink
		} while (![string]::IsNullOrEmpty($vmssUrl))
		
		$arcUrl = "https://management.azure.com/subscriptions/" + $SubscriptionId + "/resources?`$filter=resourceType eq 'Microsoft.HybridCompute/machines'&api-version=2023-07-01"
		do{
			$arcResponse = Invoke-RestMethod -Method Get -Uri $arcUrl -Headers @{Authorization = "Bearer $accessToken"}
			$arcResponseMachines += $arcResponse.value | where {$_.tags.$tagName -eq $tagValue}
			$arcUrl = $arcResponse.nextLink
		} while (![string]::IsNullOrEmpty($arcUrl))
	}
	catch 
	{
		Write-Host "Failed to Get resources! " -ForegroundColor Red
		Write-Host "Response StatusCode:" $_.Exception.Response.StatusCode.value__  -ForegroundColor Red
		Write-Host "Response StatusDescription:" $_.Exception.Response.StatusDescription -ForegroundColor Red
		Write-Host "Error from response:" $_.ErrorDetails -ForegroundColor Red
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
        $accessToken = Get-AzAccessToken | Select-Object -ExpandProperty token
        $expireson = Get-AzAccessToken | Select-Object -ExpandProperty expireson | Select-Object -ExpandProperty LocalDateTime

        Write-host "New token expires on: $expireson - currentTime: $currentTime - New Token is: $accessToken"
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
	try 
	{
		if($PricingTier.ToLower() -eq "delete")
		{
			$pricingResponse = Invoke-RestMethod -Method Delete -Uri $pricingUrl -Headers @{Authorization = "Bearer $accessToken"} -ContentType "application/json" -TimeoutSec 120
			Write-Host "Successfully deleted pricing configuration for $($machine.name)" -ForegroundColor Green
			$successCount++
			$vmSuccessCount++
		} elseif ($PricingTier.ToLower() -eq "read")
        {
            $pricingResponse = Invoke-RestMethod -Method Get -Uri $pricingUrl -Headers @{Authorization = "Bearer $accessToken"} -ContentType "application/json" -TimeoutSec 120
			Write-Host "Successfully read pricing configuration for $($machine.name): " -ForegroundColor Green
            Write-Host ($pricingResponse | ConvertTo-Json -Depth 100)
			$successCount++
			$vmSuccessCount++
        }
		else
		{
			$pricingResponse = Invoke-RestMethod -Method Put -Uri $pricingUrl -Headers @{Authorization = "Bearer $accessToken"} -Body ($pricingBody | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 120
			Write-Host "Successfully updated pricing configuration for $($machine.name)" -ForegroundColor Green
			$successCount++
			$vmSuccessCount++
		}
	}
	catch {
		$failureCount++
		Write-Host "Failed to update pricing configuration for $($machine.name)" -ForegroundColor Red
		Write-Host "Response StatusCode:" $_.Exception.Response.StatusCode.value__  -ForegroundColor Red
		Write-Host "Response StatusDescription:" $_.Exception.Response.StatusDescription -ForegroundColor Red
		Write-Host "Error from response:" $_.ErrorDetails -ForegroundColor Red
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
        $accessToken = Get-AzAccessToken | Select-Object -ExpandProperty token
        $expireson = Get-AzAccessToken | Select-Object -ExpandProperty expireson | Select-Object -ExpandProperty LocalDateTime

        Write-host "New token expires on: $expireson - currentTime: $currentTime - New Token is: $accessToken"
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
	try 
	{
		
		if($PricingTier.ToLower() -eq "delete")
		{
			$pricingResponse = Invoke-RestMethod -Method Delete -Uri $pricingUrl -Headers @{Authorization = "Bearer $accessToken"} -ContentType "application/json" -TimeoutSec 120
			Write-Host "Successfully deleted pricing configuration for $($machine.name)" -ForegroundColor Green
			$successCount++
			$vmssSuccessCount++
		} elseif ($PricingTier.ToLower() -eq "read")
        {
            $pricingResponse = Invoke-RestMethod -Method Get -Uri $pricingUrl -Headers @{Authorization = "Bearer $accessToken"} -ContentType "application/json" -TimeoutSec 120
			Write-Host "Successfully read pricing configuration for $($machine.name): " -ForegroundColor Green
            Write-Host ($pricingResponse | ConvertTo-Json -Depth 100)
			$successCount++
			$vmssSuccessCount++
        }
		else
		{
            $pricingResponse = Invoke-RestMethod -Method Put -Uri $pricingUrl -Headers @{Authorization = "Bearer $accessToken"} -Body ($pricingBody | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 120
            Write-Host "Successfully updated pricing configuration for $($machine.name)" -ForegroundColor Green
            $successCount++
            $vmssSuccessCount++
        }
	}
	catch {
		$failureCount++
		Write-Host "Failed to update pricing configuration for $($machine.name)" -ForegroundColor Red
		Write-Host "Response StatusCode:" $_.Exception.Response.StatusCode.value__  -ForegroundColor Red
		Write-Host "Response StatusDescription:" $_.Exception.Response.StatusDescription -ForegroundColor Red
		Write-Host "Error from response:" $_.ErrorDetails -ForegroundColor Red
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
        $accessToken = Get-AzAccessToken | Select-Object -ExpandProperty token
        $expireson = Get-AzAccessToken | Select-Object -ExpandProperty expireson | Select-Object -ExpandProperty LocalDateTime

        Write-host "New token expires on: $expireson - currentTime: $currentTime - New Token is: $accessToken"
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
	try 
	{
		
		if($PricingTier.ToLower() -eq "delete")
		{
			$pricingResponse = Invoke-RestMethod -Method Delete -Uri $pricingUrl -Headers @{Authorization = "Bearer $accessToken"} -ContentType "application/json" -TimeoutSec 120
			Write-Host "Successfully deleted pricing configuration for $($machine.name)" -ForegroundColor Green
			$successCount++
			$arcSuccessCount++
		} elseif ($PricingTier.ToLower() -eq "read")
        {
            $pricingResponse = Invoke-RestMethod -Method Get -Uri $pricingUrl -Headers @{Authorization = "Bearer $accessToken"} -ContentType "application/json" -TimeoutSec 120
			Write-Host "Successfully read pricing configuration for $($machine.name): " -ForegroundColor Green
            Write-Host ($pricingResponse | ConvertTo-Json -Depth 100)
			$successCount++
			$arcSuccessCount++
        }
		else
		{
            $pricingResponse = Invoke-RestMethod -Method Put -Uri $pricingUrl -Headers @{Authorization = "Bearer $accessToken"} -Body ($pricingBody | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 120
            Write-Host "Successfully updated pricing configuration for $($machine.name)" -ForegroundColor Green
            $successCount++
            $arcSuccessCount++
        }
	}
	catch {
		$failureCount++
		Write-Host "Failed to update pricing configuration for $($machine.name)" -ForegroundColor Red
		Write-Host "Response StatusCode:" $_.Exception.Response.StatusCode.value__  -ForegroundColor Red
		Write-Host "Response StatusDescription:" $_.Exception.Response.StatusDescription -ForegroundColor Red
		Write-Host "Error from response:" $_.ErrorDetails -ForegroundColor Red
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
