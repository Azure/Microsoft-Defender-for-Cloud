# Configure a custom Log Analytics workspace
This ARM template allows you to configure a custom (central) workspace.<br>
By default, it configures the autoprovision settings to "Off".
You can change this to "On" (case sensitive). <br><br>

The ARM template also sets all bundle pricings to "Standard", you can update this template for each and every bundle type.

### Deployment
This is a subscription level deployment, so please use the following PowerShell command example to customize your deployment:
```csharp
New-AzDeployment -name <yourDeploymentName> `
 -Location '<yourLocation>' `
 -TemplateFile '<thePathToYourTemplateJSON' `
 -workspaceName: 'yourRegionalWorkspaceName' `
 -workspaceResourceGroup: 'workspaceResourceGroupName' `
 -azureSubscriptionId: 'subscriptionIdOfTheWorkspace' `
 -Verbose
```

