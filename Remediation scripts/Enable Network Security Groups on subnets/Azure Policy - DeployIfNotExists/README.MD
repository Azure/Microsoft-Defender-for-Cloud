# Assign an existing Network Security Group to subnets
Author: Lior Arviv

This policy enables you to protect virtual network subnets with an existing network security group (NSG) found in the same subscription.

### Please note
The current version of this policy will query out all subnets without NSG including subnets for VPN gateway, Azure Bastion, etc.

## Try on Portal

<a href="https://portal.azure.com/#blade/Microsoft_Azure_Policy/CreatePolicyDefinitionBlade/uri/https://github.com/Azure/Azure-Security-Center/blob/master/Remediation%20scripts/Enable%20Network%20Security%20Groups%20on%20subnets/Azure%20Policy%20-%20DeployIfNotExists/azurepolicy.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>