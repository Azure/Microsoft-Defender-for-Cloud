# Module 17 – Defender CSPM  

<p align="left"><img src="../Images/asc-labs-intermediate.gif?raw=true"></p>

#### 💁 Authors: 
Vasavi Pasula [Github](https://github.com/vapasula), [Linkedin](https://www.linkedin.com/in/pasulavasavi/)

Giulio Astori [Github](https://github.com/gastori), [Linkedin](https://www.linkedin.com/in/giulioastori/)

#### 🎓 Level: 200 (Intermediate)
#### ⌛ Estimated time to complete this lab: 60 minutes
<br />

## Objectives
In this exercise, you will learn how to enable Defender for CSPM, and leverage Defender for CSPM Capabilities

## Exercise 1: Preparing the Environment for DCSPM plan

Pre-requisites: Deploy the Environment in **Module 1 - Preparing the Environment **

If you already finished Module 1 of this lab, (Module 1 – Preparing the Environment), you will deploy an extended environment for Defender CSPM plan.
As part of this exercise, you will create an environment using an automated deployment based on ARM template. 

The following list of resources will be deployed during the provisioning process (including dependencies like disks, network interfaces, public IP addresses, etc.):
Name | Resource Type | Purpose
-----| ------------- | -------
dcspmlab-winsrv | Virtual machine | Windows Server
dcspmlab-nix | Virtual machine | Linux Server


1.	Prepare your lab environment by clicking on the blue **Deploy to Azure** button below:

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FMicrosoft-Defender-for-Cloud%2Fmaster%2FLabs%2FFiles%2Fdcspmlabdeploy.json" target="_blank"><img src="https://aka.ms/deploytoazurebutton"/></a>
  
2.	You will be redirected to **Azure Portal** > **custom deployment** page where you should specify mandatory fields for deployment.
![image](https://user-images.githubusercontent.com/102209701/215821808-99521c72-065c-4078-af9c-893ac8719e24.png)

 
3.	On the **subscription** field, select Azure subscription used in **Module 1**.
4.	On the **Resource group** field, click on **select existing** and select asclab (you can pick any name you want or keep the default).
5.	On the Instance Details section, select the data center **region** you deployed the ARM Template in **Module 1** (all downstream resources will be created in the same region as the resource group).
6.	Select **Admin Username** and **Admin password** that will be used for Windows Virtual Machine and Linux Virtual Machine you are deploying.
Notice that password must be between 12 and 72 characters and have 3 of the following: 1 lower case, 1 upper case, 1 number and 1 special character.
7.	Select **Storage Account Name** (asclabsa[uniqestring]), **Key Vault Name** (asclab-kv-[uniqestring]), and **Sql Server Name** (asclab-sql-[uniqestring]) you already deployed in Module 1. 
8.	Click **Review + create** to start the validation process. Once validation passed, click on **Create** to start the ARM deployment on your subscription.
9.	The deployment takes about **10 minutes** to complete.
The deployment is in progress page continues to update and show the resources being uploaded to the environment assuming the deployment is successful.

You can also check the progress of your deployment if you click on your created resource group details, then click on **Deployments** (1 deploying).
When the deployment is complete, you should see the following:
Name | Resource Type | Purpose
-----| ------------- | -------
dcspmlab-winsrv | Virtual machine | Windows Server
dcspmlab-nix | Virtual machine | Linux Server

## Exercise 2: Enabling Defender CSPM plan
To gain access to the capabilities provided by Defender CSPM, you'll need to <a href="https://learn.microsoft.com/en-us/azure/defender-for-cloud/enable-enhanced-security">enable the Defender Cloud Security Posture Management (CSPM) plan </a> on your subscription
1.	Open **Azure Portal** and navigate to **Microsoft Defender for Cloud** blade.
2.	From Defender for Cloud's menu, open the **Environment Settings** page and select the relevant subscription.
3.	In the Defender plans page, select **Defender CSPM** turn the status to **ON** and select **Settings** under Monitoring Coverage.
4.	Turn **ON** the **Agentless scanning for machines (preview)** and click **continue**
5.	Click on **Save** to save the changes 
Agentless scanning for VMs provides vulnerability assessment and software inventory in 24 hours. Leave the setup and comeback after 24 hours.
 
 ## Use-case for the exercise 

A hypothetical organization, "Acme Inc." had a robust cybersecurity infrastructure in place. However, one day, an attacker used a brute force or password spraying attack to gain access to an Internet-exposed server of the organization. 

The attacker could quickly move laterally through the network, exploiting vulnerabilities on the Internet-exposed servers and gaining access to the organization's Storage Accounts, SQL servers, and Key Vaults. The SOC department was alerted by Defender for Cloud on the “Brute Force, Password Spray” IOC/IOA, and quickly realized something was wrong when they noticed unusual activity on the servers and Storage Accounts. 

In response to the attack, the security engineers leveraged the attack path analysis to identify the entry point of the attack and the path the attackers used to move laterally through the network. Based on this analysis, they were able to close the entry point and cut off the attackers' access to the organization's data. 

However, the IT department didn't stop there. They also took a proactive approach by implementing security recommendations to fix the vulnerabilities on the Internet-exposed servers and prevent similar attacks in the future. They also implemented a robust incident response plan and conducted regular security training for employees to educate them on how to identify and avoid brute force and password spraying attacks. 

Thanks to the combination of both reactive and proactive measures, Acme Inc was able to prevent a major data breach and keep their sensitive information safe. This hypothetical use case demonstrates the importance of having both a reactive and proactive approach when it comes to cybersecurity, including performing attack path and security risk analysis, implementing security recommendations, assigning/managing change actions to the proper owners, and educating employees to prevent future attacks.  

Next exercise will show how to leverage the Attack Path feature of Defender for CSPM. 

## Exercise 3: Explore Attack Paths in your Environment
1.	Open **Azure Portal** and navigate to **Microsoft Defender for Cloud** blade.
2.	From Defender for Cloud's menu, open the **Recommendations** page
3.	You will find Attack path tab as below:

 ![image](https://user-images.githubusercontent.com/102209701/215828282-358965da-9a0f-4467-846a-2572cf6d8cb8.png)

4.	Click on **Attack path**. You will find the Attack Paths in your Environment. 
5.	Click on **“Internet exposed VM has High severity vulnerabilities and read permission to key vault”**

![image](https://user-images.githubusercontent.com/102209701/215828721-bad6c2ba-a3dc-4984-91b9-f8b15dab6ad4.png)
 
6.	You can observe the Attack path and the resources involved in the attack path.
7.	Remediate the recommendations to resolve the attack path 
8.	Explore the rest of the Attack paths found in your Environment and remidiate

## Exercise 4: Build query with Cloud Security Explorer
1.	Open **Azure Portal** and navigate to **Microsoft Defender for Cloud** blade.
2.	From Defender for Cloud's menu, open the **Cloud Security Explorer(preview)** page

 ![image](https://user-images.githubusercontent.com/102209701/215828929-98a0e9fe-1f0e-4ac8-97f5-4bed96d0d174.png)

3.	Select a predefined query Template **“Internet exposed VMs with high severity vulnerabilities”** and click on **Search**
4.	You will find the list of VMs with high severity Vulnerabilities.
5.	Select a predefined query Template **“Internet exposed SQL servers with managed identity”** and click on **Search**
6.	You will find the list of SQL servers with managed identity.
7.	You can also explore and build your own queries using query builder as shown below: In the dropdown select ->Virtual machines ->Insight ->Title -> vulnerable to remote code execution.

 ![image](https://user-images.githubusercontent.com/102209701/215829274-f268ffbd-2da6-4692-98d7-db11f05e6013.png)

8.	Explore your Environment for Virtual Machines with a specific vulnerability 

 ![image](https://user-images.githubusercontent.com/102209701/215829372-74895012-7beb-4a09-b34d-cd4ad18d2fa8.png)

9.	Explore your Environment for Storage Accounts exposed to the Internet

 ![image](https://user-images.githubusercontent.com/102209701/215829437-b12e741d-48e1-43e8-834f-71996fcf6645.png)

10.	Explore your Environment for Virtual machines with a managed identity 

![image](https://user-images.githubusercontent.com/102209701/215829494-1cb52fc0-1844-437a-aee0-d194d03049ea.png)

 
## Exercise 5: Assign Governance Rule

1.	Open **Azure Portal** and navigate to **Microsoft Defender for Cloud** blade.
2.	From Defender for Cloud's menu, open the **Environment Settings** page and select the relevant subscription.
3.	Under **settings** Select **Governance Rules(Preview)**
4.	Click on **+Create governance rule**
5.	Give a **rule name**, select **scope** at subscription level, **priority** 100
6.	Under **conditions**, select **By severity -> High**, **Owner -> By email address**, specify the email address of the workload owner to receive notification email, **Remediation timeframe -> 90 days**
7.	**Notify Owners weekly about open and overdue tasks** and click **Save**.

 ![image](https://user-images.githubusercontent.com/102209701/215829686-cd5fc20c-32be-4822-be5f-04e5f85563c5.png)

8.	Click on **Governance report** to view the status of tasks **Complete, Overdue, Ontime, Unassign**

 ![image](https://user-images.githubusercontent.com/102209701/215830577-947675fb-2f05-44a0-9482-fbd58a86d360.png)

 




