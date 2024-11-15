# Module 14 – Onboarding Azure DevOps to Defender for Cloud

<p align="left"><img src="../Images/asc-labs-intermediate.gif?raw=true"></p>

#### 🎓 Level: 200 (Intermediate)
#### ⌛ Estimated time to complete this lab: 30 minutes

## Objectives
In this exercise, you will learn how to connect Azure DevOps repositories to Defender for Cloud.

### Exercise 1: Preparing the Environment

If you already finished [Module 1](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module-1-Preparing-the-Environment.md) of this lab, you can skip this exercise, otherwise please finish at least Exercise 1, 2 and 3 from Module 1.

### Exercise 2: Creating an Azure DevOps Trial Subscription

1.	Open an In-Private session in your web browser and navigate to [https://dev.azure.com](https://dev.azure.com)
2.	On the main part of this page, click Start free and use your Microsoft account credentials to login. If you don’t want to use your existing credentials, use the Azure Trial subscription account in order to login.
3.	Type your Account email address and Password and login to your DevOps environment..

### Exercise 3: Onboarding an Azure DevOps Connector

1.	Login to your Azure Portal and open Defender for Cloud dashboard
2.	In the left navigation pane, click **Environment settings** option
3.	Click the **Add environment** button and click **Azure DevOps** option. The **Create Azure DevOps connection** page appears as shown the sample below.

<img width="625" alt="image" src="https://github.com/user-attachments/assets/f85b2051-39ae-4dd3-be28-ac3643a1fbeb">


4.	Type the name for the connector, select the subscription, select the Resource Group, which can be the same you used in this lab and the region. 
11.	Click **Next: Configure access >** button to continue.
12.	In the next page, click **Next: Authorize connection >** button to continue.

<img width="468" alt="image" src="https://github.com/user-attachments/assets/79801359-2618-4d7c-acb9-c4a3335058a9">

13.	Click **Authorize** button. If this is the first time you’re authorizing your DevOps connection, you’ll receive a pop-up screen, that will ask your permission to authorize. Scroll down the popped up window screen and click the **Accept** button as shown in the sample below:

<img width="1040" alt="image" src="https://github.com/user-attachments/assets/1794e5b1-ddd9-4a7d-9be2-d3a6e3f6c537">

> **Note** When you click **Accept** in your Azure DevOps, you’ll notice the proof of Authorization to the **Microsoft Security DevOps** App. You can find this in your Azure ADO organization, under the **Personal Access tokens** / **User Settings** / **Authorizatons**.  


14.	Click **Review and generate** button to continue.


> **Note** You need to be a **Project Collection Admin** in the Azure DevOps organization that you selected to complete this process. Learn more about this role [here](https://learn.microsoft.com/en-us/azure/devops/organizations/settings/about-settings?view=azure-devops&WT.mc_id=Portal-Microsoft_Azure_Security_DevOps#project-collection-administrator-pca-role-and-managing-collections-of-projects)


15.	After some minutes you will see the Azure DevOps connector in the **Environment settings** page and in about 15 minutes, you will start to seeing the total resources number populating.

### Exercise 4: Configure the Microsoft Security DevOps Azure DevOps Extension

1.	Login to the Azure DevOps organization that you created in Exercise 3.
2.	In the right corner, click in the shopping bag icon and click **Browse marketplace** option.
3.	In the search field, type ***Microsoft Security DevOps extension*** and click the search button.
4.	Click in the extension, select Install. Choose appropriate Organization from the dropdown menu, select Install and Proceed to Organization.
5.	 you have it installed, you’ll notice the Extension under ‘Installed’ section in the organization level settings as shown the example below:

![Azure DevOps Connector - Extension](../Images/M14_Fig5.PNG?raw=true)


> **Note** Project Collection Administrator privileges to the Azure DevOps organization are required to install the extension. If you don’t have access to install the extension, you must request access from your Azure DevOps organization’s administrator during the installation process


### Exercise 5: Install Free extension SARIF SAST Scans Tab

In order to view the scan results (when you execute the pipelines), in an easier and readable format, install this free extension in your Azure DevOps organization.

1.	Login to the Azure DevOps organization that you created in Exercise 3 and open the marketplace using the same steps that were descrivbed in the previous exercise.
2.	In the search field, type ***SARIF SANST Scans*** and click the search button.
3.	Follow the same steps as shown in the previous exercise to install this extension in your Azure ADO organization.
4.	After finishing installing you should see two extensions as shown in the example below:

![Azure ADO Connector - SANS](../Images/M14_Fig6.PNG?raw=true)

### Exercise 6: Configure your pipeline using YAML 

The purpose of this exercise is to allow you to see how the extension used by Defender for Cloud will check your pipeline. Before start this exercise review the following observations:
- If you are using the free version of Azure DevOps you will receive an error message when executing the pipeline. This message will ask you to visit  https://aka.ms/azpipelines-parallelism-request/ and request increased parallelism in Azure DevOps. This can take 2 to 4 days to occur.
- An alternative way to create a pipeline is by using a Hosted Build Agent, which is the method used in this exercise. To create your hosted build agent follow the steps from [Module 14 - Appendix 1](Module14-Appendix1.pdf). After finishing these steps, you can continue

1. Login to the Azure DevOps organization that you created in Exercise 3 and open your project.
2. In the left navigation pane, click **Pipelines** as shown below:

![Azure ADO Connector - Pipeline](../Images/M14_Fig7.PNG?raw=true)

3. In the right pane, click **New pipeline** button.
4. In the **Where is your code?** page, click **Azure Repos Git** as shown below: 

![Azure DevOps Connector - where](../Images/M14_Fig8.PNG?raw=true)

5. Click the appropriate repository.
6. In the **Configure your pipeline** page, click **Starter pipeline** as shown below: 

![Azure DevOps Connector - starter](../Images/M14_Fig9.PNG?raw=true)

7. In the page that opens up, replace the YAML code for the one below:

```
# Starter pipeline
# Start with a minimal pipeline that you can customize to build and deploy your code.
# Add steps that build, run tests, deploy, and more:
# https://aka.ms/yaml
trigger: none
pool: windows-build-agents
steps:
- task: MicrosoftSecurityDevOps@1
  displayName: 'Microsoft Security DevOps'
```

> **Note** Observe that the pool is pointing to windows-build-agents, which is the VMSS that you created.

8. Click **Save and run** button and then click Save and run button again.


> **Note** At this point the job will queue up to run. This step may take some time to spin up a build agent in the VMSS. During this time, if you go back to VMSS dashboard you will see that the instance is getting created

9. In a few more minutes, the job will start to have some activity as shown the example below:

![Azure ADO Connector - result](../Images/M14_Fig10.PNG?raw=true)

10. After it finishes you can see scan done by Defender for Cloud. To do that click **Microsoft Security DevOps** section in the left and you will see the output of the actions that were done as shown below:

![Azure ADO Connector - scanresult](../Images/M14_Fig11.PNG?raw=true)



