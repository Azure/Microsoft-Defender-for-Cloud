param (
    [parameter(Mandatory=$true)]
    [Object]$RecoveryPlanContext,
    
    [parameter(Mandatory=$true)]
    [Object]$VaultId,
	
	[parameter(Mandatory=$true)]
    [Object]$ChangePit
)

# ToDo: Alerts detection conditions need to update.

<#
.SYNOPSIS
    Waits for ASR job completion
#>
Function WaitForJobCompletion { 
    param(
        [parameter(Mandatory = $True)] [string] $JobId,
        [int] $JobQueryWaitTimeInSeconds = 30
    )

    $isJobLeftForProcessing = $true
    Write-Output "Job -  $JobId is in-Progress"

    do {
        $azJob = Get-AzRecoveryServicesAsrJob -Name $JobId
        $azJob
        
        if ($azJob.State -eq "InProgress" -or $azJob.State -eq "NotStarted") {
            $isJobLeftForProcessing = $true
        }
        else {
            $isJobLeftForProcessing = $false
        }

        if ($isJobLeftForProcessing) {
            $azJob
            Start-Sleep -Seconds $JobQueryWaitTimeInSeconds
        }
        else {
            if ($null -eq $azJob.DisplayName -or $azJob.DisplayName -eq '') {
                $messageToDisplay = "NA"
            }
            else {
                $messageToDisplay = $azJob.DisplayName
            }

            if ($azJob.State -eq "Failed") {
                $azJob
                $errorMessage = ($azJob.Errors.ServiceErrorDetails | ConvertTo-json -Depth 1)
                throw $errorMessage
            }
            else {
                $azJob
            }
            
        }
    }While ($isJobLeftForProcessing)
}

<#
.SYNOPSIS
    Triggers ASR Change Recovery Point operation.
#>
Function ChangeRecoveryPoint {
    param(
        [parameter(Mandatory = $True)] [string] $VmIdentifier,
        [parameter(Mandatory = $True)] [string] $DetectionTime
    )
    
    Write-Output "Getting the VmIdentifier"
    $VmIdentifier
    
    Write-Output "Getting the vault"
    $VaultId
    $resource = Get-AzResource -ResourceId $VaultId
    
    $vault = Get-AzRecoveryServicesVault -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name
    Set-AzRecoveryServicesAsrVaultContext -Vault $vault
    
    $fabrics = Get-AzRecoveryServicesAsrFabric
    if ($null -ne $fabrics) {
        foreach ($fabric in $fabrics) {
            $containers = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $fabric
            foreach ($container in $containers) {
                $protectedItems = Get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $container                
                foreach ($protectedItem in $protectedItems) {
                    $rpi = Get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $container -Name $protectedItem.Name
                    
                    # Identifying the Replicated item using Azure VM Id in ASR.
                    if (($rpi.ProviderSpecificDetails.LifecycleId -eq $VmIdentifier) -or # Azure to Azure scenario.
                        ($rpi.ProviderSpecificDetails.internalIdentifier -eq $VmIdentifier)) #VMware to Azure scenario.
                    {
                        #Replicated item found for Failed over azure VM.
                        Write-Output "Protected item found."
                        $rpi
                        
                        #get recovery points
                        $recoveryPoints = Get-AzRecoveryServicesAsrRecoveryPoint -ReplicationProtectedItem $protectedItem | Sort-Object RecoveryPointTime -Descending
                        $recoveryPoints
                        
                        # Going to back to the Recovery point older then detection time.
                        $ChangeRP = $recoveryPoints | Where-Object{ $_.RecoveryPointTime -le $DetectionTime} | Select-Object -First 1
                        Write-Output "Changing the recovery point."
                        $ChangeRP
                        
                        if (($ChangeRP -ne $null) -and ($ChangePit -eq $True))
                        {
                            #Retry the failover with new recovery point.
                            $asrJob = Start-AzRecoveryServicesAsrApplyRecoveryPoint -ReplicationProtectedItem $protectedItem -RecoveryPoint $ChangeRP
                            
                            WaitForJobCompletion -JobId $asrJob.Name
                        }
                        
                        break
                    }
                }
            }
        }
    }   
}

# Recovery plan context, this value coming from the Recovery plan.
Write-Output $RecoveryPlanContext
Write-Output "checking variable"

$RecoveryPlanContextObj = ""
try
{
    $RecoveryPlanContextObj = $RecoveryPlanContext | ConvertFrom-Json
}
catch {
    $RecoveryPlanContextObj = $RecoveryPlanContext
    Write-Output -Message $_.Exception
}

Write-Output "getting VM map object"
$VMMapColl = $RecoveryPlanContextObj.VmMap
Write-Output $VMMapColl

$SubscriptionId = ""
$ResourceGroupName = ""
$VMCollection = @()

if($VMMapColl -ne $null)
{
    Write-Output "VMMapColl Variable is Not Null"
    $VMinfo = $VMMapColl | Get-Member | Where-Object MemberType -EQ NoteProperty | select -ExpandProperty Name
    #$vmMap = $RecoveryPlanContextObj.VmMap
    Write-Output "VMinfo: $VMinfo"

    foreach($VMID in $VMinfo)
    {
        $VM = $VMMapColl.$VMID
        Write-Output $VM
                
        if( !(($VM -eq $Null) -Or ($VM.ResourceGroupName -eq $Null) -Or ($VM.RoleName -eq $Null))) 
        {
            $VM | Add-Member NoteProperty RecoveryPlanName $RecoveryPlanContextObj.RecoveryPlanName
            $VM | Add-Member NoteProperty FailoverType $RecoveryPlanContextObj.FailoverType
            $VM | Add-Member NoteProperty FailoverDirection $RecoveryPlanContextObj.FailoverDirection
            $VM | Add-Member NoteProperty GroupId $RecoveryPlanContextObj.GroupId
            $VM | Add-Member NoteProperty VMId $VMID
            $VM | Add-Member NoteProperty VmRg $VM.ResourceGroupName
            $VM | Add-Member NoteProperty VmName $VM.RoleName

            $VMCollection += $VM
            $SubscriptionId = $VM.SubscriptionId
            $ResourceGroupName = $VM.ResourceGroupName
        }
    }
}
else
{
     Write-Output "VMMapColl Variable is Null"
}

$CollectionCount = $VMCollection.Count
Write-Output "Collection Count: $CollectionCount" 

#Returning Collection
Write-Output $VMCollection

if ($SubscriptionId -eq "")
{
    Write-Output "SubscriptionId not found."
    exit
}

Write-Output "SubscriptionId : $SubscriptionId"

try
{
    "Logging in to Azure..."
    Connect-AzAccount -Identity
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

Get-AzContext
Set-AzContext -SubscriptionId $SubscriptionId

foreach ($vmDetails in $VMCollection)
{
    $azureVm = Get-AzVM -Name $vmDetails.VmName -ResourceGroupName $vmDetails.VmRg -ErrorAction SilentlyContinue
    if ($null -ne $azureVm) { 
        Write-Output "Found Azure VM."
        $azureVm.Name 
    }
    else
    {
        Write-Output "Not found Azure VM."
        $vmDetails.VmName
        continue
    }
    
    $alertFound = $false
    $alerts = Get-AzSecurityAlert -ResourceGroupName $azureVm.ResourceGroupName
    foreach ($alert in $alerts)
    {
        try
        {
            Write-Output "Validating alert "
            # alert filter – need to update the alert conditions.
            if (($alert.ResourceIdentifiers.AzureResourceId -ne $null) -and 
                ($alert.ResourceIdentifiers.AzureResourceId -ieq $azureVm.Id) -and
                ($alert.Severity -ieq "High")) #High, Medium, Low, Informational
            { 
                Write-Output "Found alert for the VM" 
                $vmDetails.VmName
                $alert
                $alertFound = $true
                
                #Change recovery point only if your VM wants to go back to old date.
                ChangeRecoveryPoint -VmIdentifier $vmDetails.VMID -DetectionTime $alert.startTimeUtc 
                break
            }
        }
        catch 
        {
            Write-Error -Message $_.Exception
            continue
        }
    }

    if ($alertFound -eq $false)
    {
        Write-Output "No alerts found" 
        $vmDetails.VmName
    }
}