$SubscriptionId="<subscriptionId>"
$ResourceGroupName="<resourceGroupName>"
$NetworkSecurityGroupName="<nsgName>"
$InboundRuleName="<nsgRuleName>"
$ManagementPort="<managementPort>"

Login-AzAccount
Get-AzSubscription
Set-AzContext -SubscriptionId $SubscriptionId

# Get the NSG resource
$nsg = Get-AzNetworkSecurityGroup -Name $NetworkSecurityGroupName -ResourceGroupName $ResourceGroupName

# Add the inbound security rule.
$nsg | Add-AzNetworkSecurityRuleConfig -Name $InboundRuleName -Description "Block management port" -Access Deny `
    -Protocol * -Direction Inbound -Priority 3891 -SourceAddressPrefix "*" -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange $ManagementPort

# Update the NSG.
$nsg | Set-AzNetworkSecurityGroup