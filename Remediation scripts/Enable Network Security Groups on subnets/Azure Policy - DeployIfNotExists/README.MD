# Assign an existing Network Security Group to subnets
Author: Lior Arviv

This policy enables you to protect virtual network subnets with an existing network security group (NSG) found in the same subscription.

### Please note
The current version of this policy will query out all subnets without NSG including subnets for VPN gateway, Azure Bastion, etc.

## Try on Portal

<a href="https://portal.azure.com/#blade/Microsoft_Azure_Policy/CreatePolicyDefinitionBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FRemediation%2520scripts%2FEnable%2520Network%2520Security%2520Groups%2520on%2520subnets%2FAzure%2520Policy%2520-%2520DeployIfNotExists%2Fazurepolicy.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>