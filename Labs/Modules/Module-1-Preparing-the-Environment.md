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
 - 

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
> You should also be accessing the ASC labs in the same private window. Otherwise, link from the lab will be open on a non-private window. 

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
SecurityCenterFree | Solution | Default workspace solution used for Security Center free tier

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
> Notice that password must be between 12 and 72 characters and have 3 of the following: 1 lower case, 1 upper case, 1 number and 1 special character.
7.	Click **Review + create** to start the validation process. Once validation passed, click on **Create** to start the ARM deployment on your subscription.
8.	The deployment takes about **10 minutes** to complete.<br>

> The *deployment is in progress* page continues to update and show the resources being uploaded to the environment assuming the deployment is successful.  
> During the deployment, additional resource group will be created automatically for Kubernetes resources named as “asclab-aks”.<br>

<p align="left"><img src="../Images/deploy-to-azure.gif?raw=true"></p>

You can also check the progress of your deployment if you click on your created resource group details, then click on **Deployments** (*1 deploying*). <br>

![Template deployment is in progress](../Images/asc-deployment-in-progress.gif?raw=true)

When the deployment is complete, you should see the following:

![Template deployment completed](../Images/asc-deployment-completed.gif?raw=true)

### Exercise 3: Enabling Azure Defender

#### Subscription upgrade and agents installation
1. Open **Azure Portal** and navigate to **Security Center** blade.
2. Click on **Getting started** page from the left pane, On the **Upgrade** Tab, select subscription (Azure subscription 1) and press **Upgrade**.
3. Click on **Install agents**, if the button has been grayed out, then it's already set to **On**.
4. Return to Azure security Center blade and Click on **Pricing & settings**.
5. Your subscription (Azure subscription 1) should be listed and Azure Defender plan should be **On (partial)** (if it does not, close your browser session and open a new one).

> Notice that you enabled Azure Defender at a subscription level, but Log Analytics workspace pricing is still set on Free (means Azure Defender is OFF).

#### Configure the data collection settings in ASC
1. On **Pricing and Settings** page, press on the Log Analytics workspace named **asc-lab-xxx**

![Template deployment completed](../Images/asc-workspace-pricing-settings.gif?raw=true)

2. On the Azure Defender Plans page, select **Azure Defender on** and press **Save**. Now both subscription and Log Analytics workspace should be set to **On** for Azure Defender plan.

![Enable Azure Defender on the workspace level](../Images/asc-enable-defender-workspace.gif?raw=true)

3. Go back to the **Pricing & Setting** and drill down into your **Azure subscription** (Azure subscription 1).
4. Navigate to **Data Collection**
5. On the **Auto provisioning - Extensions** page, set **Log Analytics agent for Azure VMs** to **On** (if it's not already set to On)
6. Click **Edit configuration**.
7. On the workspace configuration section, use the **Connect Azure VMs to a different workspace** option to select your workspace **asc-lab-xxx** (which has been created by the ARM template).
8. Under **Store additional raw data - Windows security events** section, select **All Events** option.

![Enable Azure Defender on the workspace level](../Images/asc-extension-deployment-configuration.gif?raw=true)

9. Click on **Apply**.
10. Click on **Save**.

<br>

> Please notice:
> * To get the full functionality of Azure Security Center and Azure Defender, both subscription and Log Analytics workspace should be enabled for Defender. Once you enable it, under the hood the required Log Analytics solutions will be added to the workspace.
> * Before clicking on the Upgrade button, you can review the total number of resources you are going to enable Azure Defender on.
> * You can enable Azure Defender trial for 30-days on a subscriptions only if not previously used.
> * To enable Azure Defender on a subscription, you must be assigned the role of Subscription Owner, Subscription Contributor, or Security Admin.

### Continue with the next lab: [Module 2 - Exploring Azure Security Center](../Modules/Module-2-Exploring-Azure-Security-Center.md)