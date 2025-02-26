# Logic App based on Microsoft Defender for Cloud security alerts

The ARM template DeleteBlobLogicApp will create a LogicApp that removes malicious files that trigger the security alert "Malicious file uploaded to storage account".


## Instructions
1. Deploy the DeleteBlobLogicApp Azure Resource Manager (ARM) template using the Azure portal.
    <a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FMicrosoft-Defender-for-Cloud%2Fmain%2FWorkflow%20automation%2FDelete%20Blob%20LogicApp%20Defender%20for%20Storage%2Ftemplate.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
    </a>

2. Select the Logic App you deployed.

3. Add a role assignment to the Logic App to allow it to delete blobs from your storage account:

    1. Go to **Identity** in the side menu and select **Azure role assignments**.
    ![Screenshot that shows how to set up a role assignment for workflow automation to respond to scan results](Figures/system-assigned-managed-identity.png)
    2. Add a role assignment in the subscription level with the **Storage Blob Data Contributor** role.
    3. Create workflow automation for Microsoft Defender for Cloud alerts:
        1. Go to Microsoft Defender for Cloud in the Azure portal.
        2. Go to Workflow automation in the side menu.
        3. Add a new workflow: In the Alert name contains field, fill in Malicious file uploaded to storage account and choose your Logic app in the Actions section.
        4. Select Create.
           
        ![Screenshot that shows how to set up workflow automation to respond to scan results](Figures/workflow-automation.png)











