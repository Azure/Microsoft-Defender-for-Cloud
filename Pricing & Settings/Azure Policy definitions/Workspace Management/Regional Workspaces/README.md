# Azure Policy sample to support regional workspaces and agent deployment
One of the Log Analytics workspace best practices is to consolidate the number of workspaces where possible.<br>
A common use case is to leverage "regional workspaces" to prevent additional network bandwidth costs, in the case that your Azure Virtual Machine is not located in the same region as your Log Analytics workspace.<br>
Based on the regions that your company uses, you create 1 workspace per region so that your Virtual Machine always communicates with a workspace in the same region.<br>

To automate and manage this at scale, you can leverage Azure Policy, which will deploy the Azure Monitor VM Extension, based on the location of the Virtual Machine, configured to report to a workspace in the same region.<br>

The Azure Policy definition sample (for Windows) shows how the "location" property is used to configure the correct workspace, based on where the Virtual Machine is going to be deployed, or has been deployed (using a remediation task).<br>
This sample can easily be updated for Linux, or any other criteria based on the image publisher or image type.


