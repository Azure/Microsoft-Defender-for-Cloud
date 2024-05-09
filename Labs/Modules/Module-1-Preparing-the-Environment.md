# Module 1 – Preparing the Environment

<p align="left"><img src="../Images/asc-labs-beginner.gif?raw=true"></p>

#### 🎓 Level: 100 (Beginner)
#### ⌛ Estimated time to complete this lab: 30 minutes

## Objectives
Create a new Microsoft Account enable with Azure Trial Subscription 
This section is intended to deploy Azure resources in an automated way to get you started quickly or in case you need to re-provision your environment.

#### Prerequisites
Before you start this lab, make sure you have the following prerequisites:
- **Supported web browser** (Microsoft Edge, Google Chrome, Safari, Firefox Mozilla)
    - For using these labs, **we recommend to open an incognito/in-private browser session** on your machine and login to Azure Portal to avoid conflicts with existing Azure Subscriptions/environments if already being used.
 - **Microsoft Account** - If you do not have an existing account Sign-up to create a free account: https://signup.live.com
  

### Exercise 1: Creating an Azure Trial Subscription

To use these labs, you should have Azure Subscription Trial, this allows you to get:
- **12 months of free products** - Get free access to popular products like virtual machines, storage, and databases in your first 30 days, and for 12 months after you upgrade your account to pay-as-you-go pricing.
- £150 credit/$200 credit - Use your credit to experiment with any Azure service in your first 30 days - beyond the free product amounts.
- **No automatic charges** – During the registration process, you should enter your credit card information to complete the identity verification process. 
> ⚠️ Warning: you won't be charged unless you choose to upgrade the subscription.
Before the end of your first 30 days, you'll be notified and have the chance to upgrade and start paying only for the resources you use beyond the free amounts.

#### Instructions:
1. Open an **In-Private** session in your web browser and navigate to https://azure.microsoft.com/en-us/free
2. On the main part of this page, click **Start free** and use your Microsoft Account credentials to you to login to Azure Portal.
Important - Make sure you are not logged in with your corporate user.
3. Type your Microsoft Account email address and then click on **Next**.
4. On the **Stay signed in** message, click **Yes**.
5. At the **Try Azure for free** page, type in your details following the 4-steps (your profile, identity verification by phone, identity verification by card, agreement). Once you complete all steps, click on **Sign Up** button to complete the subscription creation process.
6. On the **You’re ready to start with Azure** page, click on **Go to portal** button. Now you should have Azure Subscription named **Azure subscription 1** including owner permissions.

### Exercise 2: Provisioning resources

> ❗ Important: <br>
> You should also be accessing the Microsoft Defender for Cloud labs in the same private window. Otherwise, link from the lab will be open on a non-private window. 

As part of the exercises mentioned in this lab guide, you will create an environment using an automated deployment based on ARM template.
An ARM template is a JavaScript Object Notation (JSON) file that defines the infrastructure and configuration for your project. The template uses declarative syntax, which lets you state what you intend to deploy without having to write the sequence of programming commands to create it.
The following list of resources will be deployed during the provisioning process (including dependencies like disks, network interfaces, public IP addresses, etc.):

Name | Resource Type | Purpose
-----| ------------- | -------
asclab-win | Virtual machine | Windows Server
asclab-linux | Virtual machine | Linux Server
asclab-as | Availability set | Availability set for the 2-VMs
asclab-aks | Kubernetes service | Testing container services capabilities
asclab-app-[uniqestring] | App Service | App service to be used for web app, function app
asclab-sql-[uniqestring] | SQL server | To be using for the sample database
asclab-as | SQL database | Sample database based on AdventureWorks template
asclab-kv-[uniqestring] | Key vault | Demonstrating Key Vault related recommendations and security alerts
asclab-fa-[uniqestring] | Function App | Demonstrating related built-in and custom security recommendations
asclab-la-[uniqestring]	| Log Analytics workspace | Log Analytics workspace used for data collection and analysis, storing logs and continuous export data
asclab-nsg | Network security group | Required for Just-in-Time access and security recommendations
asclab-splan | App Service plan | Demonstrating related security recommendations
asclab-vnet | Virtual network | Default virtual network for both Azure VM and for network related recommendations
asclabcr[uniqestring] | Container registry | Demonstrating related security recommendations
asclabsa[uniqestring] | Storage account | Demonstrating related security recommendations
SecurityCenterFree | Solution | Default workspace solution used for Microsoft Defender for Cloud free tier

After the deployment of the template, you can check the progress of your deployment if you click on your created resource group details, then click on Deployments (1 deploying).
Continue with the exercise below until the deployment has completed.
<br><br>

<img src="../Images/asc-lab-architecture.svg?raw=true">
<br>

1. Prepare your lab environment by clicking on the blue **Deploy to Azure** button below:

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FLabs%2FFiles%2Flabdeploy.json" target="_blank"><img src="https://aka.ms/deploytoazurebutton"/></a>

2.	You will be redirected to Azure Portal > custom deployment page where you should specify mandatory fields for deployment.
3.	On the subscription field, select **Azure subscription 1**.
4.	On the resource group field, click on **Create new** and name it as **asclab** (you can pick any name you want or keep the default).
5.	On the parameters section, select the closest data center **region** to your current location (all downstream resources will be created in the same region as the resource group).
6. Select a password that will be used across services (such as credentials for virtual machines and SQL database)
> ❗ Important: <br>
> Notice that password must be between 12 and 72 characters and have 3 of the following: 1 lower case, 1 upper case, 1 number and 1 special character. Failure to do so will result in deployment failures.  
7.	Click **Review + create** to start the validation process. Once validation passed, click on **Create** to start the ARM deployment on your subscription.
8.	The deployment takes about **10 minutes** to complete.<br>

> The *deployment is in progress* page continues to update and show the resources being uploaded to the environment assuming the deployment is successful.  
> During the deployment, additional resource group will be created automatically for Kubernetes resources named as “asclab-aks”.<br>

<p align="left"><img src="../Images/deploy-to-azure.gif?raw=true"></p>

You can also check the progress of your deployment if you click on your created resource group details, then click on **Deployments** (*1 deploying*). <br>

![Template deployment is in progress](../Images/asc-deployment-in-progress.gif?raw=true)

When the deployment is complete, you should see the following:

![Template deployment completed](../Images/asc-deployment-completed.gif?raw=true)

### Exercise 3: Enabling Microsoft Defender for Cloud

#### Subscription upgrade and agents installation
1. Open **Azure Portal** and navigate to **Microsoft Defender for Cloud** blade.
2. Click on **Getting started** page from the left pane, On the **Upgrade** Tab, select subscription (Azure subscription 1) and press **Enable**.
   >Note: You may need to wait for a few minutes for the upgrade to complete.
3. Select both **Azure subscription 1**, and also the **workspace name** underneath it. Click on **Upgrade** to upgrade.
   ![Template deployment completed](../Images/mdfc-gettingstarted.png?raw=true)

#### Get the status of the Defender coverage on the subscription and the workspace
1. Return to Microsoft Defender for Cloud blade and Click on **Environment settings**. Click the down arrow on **Azure** to show the subscription, and then click the down arrow on **Azure Susbcription 1** to show the workspace. Notice the Defender coverage is 12/12 plans for the subscription.
> Previously for Defender for Server and Defender for SQL on Machines, it was required to enable the Defender plan on a Log Analytics workspace.  By default, both plans no longer require the use of a Log Analytics workspace (Defender for SQL on Machines will however create one due to DCR requirements).    

2. Click on **Azure subscription 1**, and notice how all Microsoft Defender for Cloud plans are enabled. 

> If you need to enable individual plans, first ensure that the Microsoft Defender for Cloud plans blue box on the right hand side is selected, and then you can select the specific Defender plans underneath.

<br>

> Please notice:
> * Before clicking on the Upgrade button, you can review the total number of resources you are going to enable Microsoft Defender for Cloud on.
> * You can enable Microsoft Defender for Cloud trial for 30-days on a subscriptions only if not previously used.
> * To enable Microsoft Defender for Cloud on a subscription, you must be assigned the role of Subscription Owner, Subscription Contributor, or Security Admin.

### Continue with the next lab: [Module 2 - Exploring Microsoft Defender for Cloud](../Modules/Module-2-Exploring-Azure-Security-Center.md)
