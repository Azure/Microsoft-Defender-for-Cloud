Write-Verbose "Checking for Azure module..."
$AzModule = Get-Module -Name "Az.*" -ListAvailable
if ($AzModule -eq $null) {
    Write-Verbose "Azure PowerShell module not found"
    #check for Admin Privleges
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if(-not ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))){
        #No Admin, install to current user
        Write-Warning -Message "Can not install Az Module.  You are not running as Administrator"
        Write-Warning -Message "Installing Az Module to Current User Scope"
        Install-Module Az -Scope CurrentUser -Force
        Install-Module Az.Security -Scope CurrentUser -Force

    }
    Else{
        #Admin, install to all users
        Install-Module Az -Force
        Install-Module Az.Security -Force
    }
}

#Login to Azure
Login-AzAccount

#Get All Subs
$Subscriptions = Get-AzSubscription

#Loop Through Subs
foreach($Subscription in $Subscriptions){
    $Id = ($Subscription.Id)
    Select-AzSubscription $Id
    #Get Security Task for Storage Security
    $SecurityTasks += Get-AzSecurityTask | Where-Object {$_.RecommendationType -eq "Enable Network Security Groups on subnet"}
}

#Loop Thru tasks
foreach($SecurityTask in $SecurityTasks){
    $SecurityTask.ResourceId
    # Select Azure Virtual Network
    $vnetName = (Get-AzureRmVirtualNetwork -ResourceGroupName $rgName).Name | Out-GridView -Title 'Select an Azure Virtual Network:' -PassThru
    $vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $rgName -Name $vnetName
    # Select Subnet that you want to associate the NSG
    $subnetName = $vnet.Subnets.Name | Out-GridView -Title 'Select an Azure Subnet:' -PassThru
    $subnet = $vnet.Subnets | Where-Object Name -eq $subnetName
    # Associate an existing NSG to subnet
    Set-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnetName -AddressPrefix $subnet.AddressPrefix -NetworkSecurityGroup $nsg | Set-AzureRmVirtualNetwork
}
