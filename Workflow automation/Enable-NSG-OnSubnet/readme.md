

# Enable a Network Security Group on a Subnet

## Overview

This workflow responds to the following recommendations by creating a network security group and associating it with the subnet. 
- **Non-internet-facing virtual machines should be protected with network security groups** 
- **Internet-facing virtual machines should be protected with network security groups** 

> When a NSG is associated with a subnet, the ACL rules apply to all the VM instances and integrated services in that subnet, but don't apply to internal traffic inside the subnet. 

## Requirements

- Resource Group **Contributor** rights to deploy the ARM Template
- The Logic App uses a system-assigned Managed Identity. You will need to assign the **Network Contributor** and **Reader** role to applicable subscriptions to create and associate network security groups. 

## Expected Impact
There is no expected impact that will occur on existing resources when the network security group is created and associated with an existing subnets. The nsg created will only have the [default network security group rules](https://learn.microsoft.com/azure/virtual-network/network-security-groups-overview#default-security-rules). 

Please test appropriately. 

## Deployment

You can deploy the main template by clicking on the button below:

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FMicrosoft-Defender-for-Cloud%2Fmain%2FWorkflow%2520automation%2FEnable-NSG-OnSubnet%2FazureDeploy.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>

1. After you have deployed the logic app assign the system managed identity the following roles
    - Network Contributor
    - Reader
    
2. Create a new Workflow Automation in Defender for Cloud
    - Trigger Conditions
        - **Defender for Cloud data type:** Recommendation
        - **Recommendation name:** Non-internet-facing virtual machines should be protected with network security groups and Internet-facing virtual machines should be protected with network security groups
        - **Recommendation State:** Unhealthy

## Configuration Options

### Network Security Group Name
The logic app leverages the parameter **defaultNSGName** which is used as the nsg name during creation. By default this is set to "default-nsg-" and appended with the subnet name during creation. 

``` 
default-nsg-<subnet name>
```

### Default Rules

By default the network security group created will only have the [default network security group rules](https://learn.microsoft.com/azure/virtual-network/network-security-groups-overview#default-security-rules). If desired you can modify the logic app to include deny or allow rules during creation. 

1. From the Logic app > Log app designer select **Parameters**
2. Update the **securityRules** parameters with properly formatted json
    * See [examples](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Workflow%20automation/Enable-NSG-OnSubnet/exampleRules.json)
3. Click **Save**
