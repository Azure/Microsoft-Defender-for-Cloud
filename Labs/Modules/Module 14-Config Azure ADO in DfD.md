# Module 14 – Configuring Azure ADO Connector in Defender for DevOps

<p align="left"><img src="../Images/asc-labs-intermediate.gif?raw=true"></p>

#### 🎓 Level: 200 (Intermediate)
#### ⌛ Estimated time to complete this lab: 30 minutes

## Objectives
In this exercise, you will learn how to configure Azure ADO Connector in Defender for DevOps.

### Exercise 1: Preparing the Environment

If you alredy finished [Module 1](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module-1-Preparing-the-Environment.md) of this lab, you can skip this exercise, otherwise plesae finish at least Exercise 1, 2 and 3 from Module 1.

### Exercise 2: Creating an Azure ADO Trial Subscription

1.	Open an In-Private session in your web browser and navigate to [https://dev.azure.com](https://dev.azure.com)
2.	On the main part of this page, click Start free and use your Microsoft account credentials to login. If you don’t want to use your existing credentials, use the Azure Trial subscription account in order to login.
3.	Type your Account email address and Password and login to your DevOps environment..

### Exercise 3: Configuring Azure ADO Connector

1.	Login to your Azure Portal and open Defender for Cloud dashboard
2.	In the left navigation pane, click **Environment settings** option
3.	Click the **Add environment** button and click **Azure DevOps (preview)** option. The **Create Azure DevOps connection** page appears as shown the sample below.

![Azure ADO Connector](../Images/M14_Fig1.PNG?raw=true)

4.	Type the name for the connector, select the subscription, select the Resource Group, which can be the same you used in this lab and the region. 
11.	Click **Next:select plans >** button to continue.
12.	In the next page leave the default selection with **DevOps** selected and click **Next: Authorize connection >** button to continue. The following page appears:

![Azure ADO Connector - Authorize](../Images/M14_Fig2.PNG?raw=true)


13.	Click **Authorize** button. If this is the first time you’re authorizing your DevOps connection, you’ll receive a pop-up screen, that will ask your permission to authorize. Scroll down the popped up window screen and click the **Accept** button as shown in the sample below:

![Azure ADO Connector - Accept](../Images/M14_Fig3.PNG?raw=true)


> **Note** When you click **Accept** in your Azure DevOps, you’ll notice the proof of Authorization to the **Microsoft Security DevOps** App. You can find this in your Azure ADO organization, under the **Personal Access tokens** / **User Settings** / **Authorizatons**.  


14.	After the authorization is complete, you will need to select your Azure ADO organization and projects as shown in the sample below:

![Azure ADO Connector - Completed](../Images/M14_Fig4.PNG?raw=true)

15.	After selecting the organization, keep the option **Auto discovery of projects** enabled.
16.	Click **Review and create** button to continue.


> **Note** You need to be a **Project Collection Admin** in the Azure DevOps organization that you selected to complete this process. Learn more about this role [here](https://learn.microsoft.com/en-us/azure/devops/organizations/settings/about-settings?view=azure-devops&WT.mc_id=Portal-Microsoft_Azure_Security_DevOps#project-collection-administrator-pca-role-and-managing-collections-of-projects)


17.	After some minutes you will see the Azure DevOps connector in the **Environment settings** page and in about 15 minutes, you will start to seeing the total resources number populating.

### Exercise 4: Configure the Microsoft Security DevOps Azure DevOps Extension

1.	Login to the Azure DevOps organization that you created in Exercise 3.
2.	In the right corner, click in the shopping bag icon and click **Browse marketplace** option.
3.	In the search field, type ***Microsoft Security DevOps extension*** and click the search button.
4.	Click in the extension, select Install. Choose appropriate Organization from the dropdown menu, select Install and Proceed to Organization.
5.	 you have it installed, you’ll notice the Extension under ‘Installed’ section in the organization level settings as shown the example below:

![Azure ADO Connector - Extension](../Images/M14_Fig5.PNG?raw=true)


> **Note** Admin privileges to the Azure DevOps organization are required to install the extension. If you don’t have access to install the extension, you must request access from your Azure DevOps organization’s administrator during the installation process


### Exercise 5: Install Free extension SARIF SAST Scans Tab

In order to view the scan results (when you execute the pipelines), in an easier and readable format, install this free extension in your Azure DevOps organization.

1.	Login to the Azure DevOps organization that you created in Exercise 3 and open the marketplace using the same steps that were descrivbed in the previous exercise.
2.	In the search field, type ***SARIF SANST Scans*** and click the search button.
3.	Follow the same steps as shown in the previous exercise to install this extension in your Azure ADO organization.
4.	After finishing installing you should see two extensions as shown in the example below:

![Azure ADO Connector - SANS](../Images/M14_Fig6.PNG?raw=true)

### Exercise 6: Configure your pipeline using YAML 

The purpose of this exercise is to allow you to see how the extension used by Defender for DevOps will check your pipeline. Before start this exercise review the following observations:
- If you are using the free version of Azure DevOps you will receive an error message when executing the pipeline. This message will ask you to visit  https://aka.ms/azpipelines-parallelism-request/ and request increased parallelism in Azure DevOps. This can take 2 to 4 days to occur.
- An alternative way to create a pipeline is by using a Hosted Build Agent, which is the method used in this exercise. To create your hosted build agent follow the steps from [Module 14 - Appendix 1](Module14-Appendix1.pdf). After finishing these steps, you can continue

1. Login to the Azure DevOps organization that you created in Exercise 3 and open your project.
2. In the left navigation pane, click **Pipelines** as shown below:

![Azure ADO Connector - Pipeline](../Images/M14_Fig7.PNG?raw=true)

3. In the right pane, click **New pipeline** button.
4. In the **Where is your code?** page, click **Azure Repos Git** as shown below: 

![Azure ADO Connector - where](../Images/M14_Fig8.PNG?raw=true)

5. Click the appropriate repository.
6. In the **Configure your pipeline** page, click **Starter pipeline** as shown below: 

![Azure ADO Connector - starter](../Images/M14_Fig9.PNG?raw=true)

7. In the page that opens up, replace the YAML code for the one below:

```
# Starter pipeline
# Start with a minimal pipeline that you can customize to build and deploy your code.
# Add steps that build, run tests, deploy, and more:
# https://aka.ms/yaml
trigger: none
pool: windows-build-agents
steps:
- task: UseDotNet@2
  displayName: 'Use dotnet'
  inputs:
    version: 3.1.x
- task: UseDotNet@2
  displayName: 'Use dotnet'
  inputs:
    version: 5.0.x
- task: UseDotNet@2
  displayName: 'Use dotnet'
  inputs:
    version: 6.0.x
- task: MicrosoftSecurityDevOps@1
  displayName: 'Microsoft Security DevOps'
```

> **Note** Observe that the pool is pointing to windows-build-agents, which is the VMSS that you created.

8. Click **Save and run** button and then click Save and run button again.


> **Note** At this point the job will queue up to run. This step may take some time to spin up a build agent in the VMSS. During this time, if you go back to VMSS dashboard you will see that the instance is getting created

9. In a few more minutes, the job will start to have some activity as shown the example below:

![Azure ADO Connector - result](../Images/M14_Fig10.PNG?raw=true)

10. After it finishes you can see scan done by Defender for DevOps. To do that click **Microsoft Security DevOps** section in the left and you will see the output of the actions that were done as shown below:

![Azure ADO Connector - scanresult](../Images/M14_Fig11.PNG?raw=true)



