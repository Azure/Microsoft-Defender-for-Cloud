# Assign an existing Network Security Group to subnets
Author: Lior Arviv

This policy enables you to protect virtual network subnets with an existing network security group (NSG) found in the same subscription.

### Please note
The current version of this policy will query out all subnets without NSG including subnets for VPN gateway, Azure Bastion, etc.