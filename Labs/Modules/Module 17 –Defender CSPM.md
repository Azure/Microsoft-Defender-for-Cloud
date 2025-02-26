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

Pre-requisites: Deploy the Environment in **Module 1 - Preparing the Environment**

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
4. Turn **ON** the following settings under **Monitoring Coverage**:
   - **Agentless scanning for machines** to enable vulnerability assessment and software inventory.
   - **Agentless discovery for Kubernetes** to continuously detect and manage Kubernetes resources.
   - **Agentless container vulnerability assessment** to scan container images and registries for vulnerabilities.
   - **Sensitive data discovery** to identify and protect sensitive data across your cloud environments.
   - **Permissions Management (Preview)** to manage and audit permissions across your cloud resources.

   Click **Continue** to proceed.

5.	Click on **Save** to save the changes.
The agentless scanning engines will begin their assessments and are expected to generate insights within 24 hours. Please allow this time for the initial data collection and analysis to complete, then return to review the results.

 ## Use-case for the exercise

A hypothetical organization, "Adatum Corporation," had a robust cybersecurity infrastructure in place. However, one day, an attacker used a brute force or password spraying attack to gain access to an Internet-exposed server of the organization.

The attacker could quickly move laterally through the network, exploiting vulnerabilities on the Internet-exposed servers and gaining access to the organization's Storage Accounts, SQL servers, and Key Vaults. The SOC department was alerted by Defender for Cloud on the “Brute Force, Password Spray” IOC/IOA, and quickly realized something was wrong when they noticed unusual activity on the servers and Storage Accounts.

In response to the attack, the security engineers leveraged the attack path analysis to identify the entry point of the attack and the path the attackers used to move laterally through the network. Based on this analysis, they were able to close the entry point and cut off the attackers' access to the organization's data.

Additionally, they utilized **Sensitive Data Discovery** to identify and secure sensitive information that could be at risk of exposure. **Permission Management** tools were implemented to review and tighten access controls, ensuring that permissions were strictly granted based on the principle of least privilege. The discovery of plaintext secrets in the environment prompted the integration of **Secret Discovery** tools to encrypt sensitive data and manage secrets more securely.

The IT department didn't stop there. They also took a proactive approach by implementing security recommendations to fix the vulnerabilities on the Internet-exposed servers and prevent similar attacks in the future. Utilizing the Risk Prioritization feature of DCSPM, the security team gained full visibility into which recommendations should be prioritized, focusing their efforts on addressing the most critical vulnerabilities first. Additionally, they implemented a robust incident response plan and conducted regular security training for employees. 

Thanks to the combination of both reactive and proactive measures, Adatum Corporation was able to prevent a major data breach and keep their sensitive information safe. This hypothetical use case demonstrates the importance of having both a reactive and proactive approach when it comes to cybersecurity, including performing attack path and security risk analysis, implementing security recommendations, assigning/managing change actions to the proper owners, and educating employees to prevent future attacks.  

## Exercise 3: Analyzing and Mitigating Attack Paths

In this exercise, we will explore the Attack Path feature of Defender CSPM. Through a hands-on scenario, you will learn how to identify and mitigate potential security breaches that exploit critical vulnerabilities and inadequate permission settings in cloud environments.

### Scenario Overview

An Internet-exposed VM has been identified with High severity vulnerabilities, which includes read permissions to a key vault. This setup poses a significant risk as it may allow attackers to exploit Remote Code Execution (RCE) vulnerabilities on the server. The lack of "least privileged" permission configurations could enable intruders to access sensitive secrets stored in the Key Vault once the server is breached.

### Objective

Utilize the Attack Path feature to trace and understand how an attacker could navigate through your cloud environment and identify critical steps to mitigate this risk.

The next exercise will demonstrate how to leverage the Attack Path feature of Defender for CSPM, highlighting a critical use case where an Internet-exposed VM with High severity vulnerabilities and read permissions to a key vault presents a potential attack vector.

1.	Open **Azure Portal** and navigate to **Microsoft Defender for Cloud** blade.
2.	From Defender for Cloud's menu, open the **Attack path analysis** page

![image](../Images/module17Img01.png?raw=true)

3.	You will find Attack path view as below:

![image](../Images/module17Img02.png?raw=true)
 
4.	Find the Attack Path with the name **"Internet exposed Azure VM with high severity vulnerabilities allows lateral movement to Azure Key Vault”**, and open it by clicking it

![image](../Images/module17Img03.png?raw=true)

![image](../Images/module17Img04.png?raw=true)
 
5. Here, you can observe the attack path and the resources involved in the attack vector. By clicking on each node/element of the attack path, you can review detailed information from the right panel. This panel provides related insights and valuable information, helping you understand how the attack can occur and what factors contribute to the lateral movements through the resources involved.

![image](../Images/module17Img05.png?raw=true)

6. Remediate the recommendations to resolve the attack path. In the main Attack Path view, locate and click on the **Remediation** tab. This action opens the remediation section, which displays the specific security recommendations needed to mitigate the attack vector.

![image](../Images/module17Img06.png?raw=true)

7.	Explore the rest of the Attack paths found in your Environment and remidiate

## Exercise 4: Build Query with Cloud Security Explorer

In this exercise, you will utilize the Cloud Security Explorer in Microsoft Defender for Cloud to perform a type of ad-hoc risk analysis by querying and identifying risky resources within your cloud environment. You will learn how to use predefined query templates and the query builder to explore, for example, vulnerabilities, identities, and sensitive data exposures in your virtual machines and storage accounts. This hands-on experience will enhance your understanding of how to effectively search for Virtual Machines (Servers) vulnerable to Remote Code Execution, pinpoint specific vulnerabilities, and identify storage accounts with sensitive data,, or you can also expand the query to add additional condition as you like, or build a total new one.

### Steps

1. Open **Azure Portal** and navigate to the **Microsoft Defender for Cloud** blade.
2. From Defender for Cloud's menu, open the **Cloud Security Explorer** page.

   ![image](https://user-images.githubusercontent.com/102209701/215828929-98a0e9fe-1f0e-4ac8-97f5-4bed96d0d174.png)

3. Select a predefined query Template **“Internet exposed VMs with high severity vulnerabilities”** and click on **Search**.
4. You will find the list of VMs with high severity Vulnerabilities.
5. Select a predefined query Template **“Internet exposed SQL servers with managed identity”** and click on **Search**.
6. You will find the list of SQL servers with managed identity.
7. You can also explore and build your own queries using query builder as shown below: In the dropdown select Compute -> Virtual Machines -> Azure Virtual Machines.

   ![image](https://user-images.githubusercontent.com/102209701/230957007-478bf8c3-eb3e-4c04-908b-514710d30967.png)

   Click on + and under select condition, select Security -> vulnerable to remote code execution.

   ![image](https://user-images.githubusercontent.com/102209701/230956384-cee04cd8-8a49-4345-a9a4-4b0e8e619ca9.png)

8. Explore your Environment for Virtual Machines with a specific vulnerability.

   ![image](https://user-images.githubusercontent.com/102209701/230958117-60a425b1-ded4-443c-a11c-001fc3f51b17.png)

   Search for Virtual Machines that have a specific Vulnerability.

   ![image](https://user-images.githubusercontent.com/102209701/230958614-cdc86d27-a4a9-4622-a137-f695af2cb37a.png)

9. Explore your Environment for Storage Accounts exposed to the Internet.

   ![image](https://user-images.githubusercontent.com/102209701/230959026-54412825-60ce-4b53-957f-21d5d17afd53.png)

   ![image](https://user-images.githubusercontent.com/102209701/230959308-d2256f43-1413-4c6d-8d4a-381f706f903d.png)

10. Explore your Environment for Storage Accounts with Sensitive Data (require that you have a Storagfe Account containing sensitive data such as, for example, a list of US Social Security Number - a make up fake list that you can create in a text file).

   ![image](https://user-images.githubusercontent.com/102209701/230960239-65feb795-4ab7-47e1-8f0e-fff3e8ef2085.png)

 
## Exercise 5: Assign Governance Rule

In this exercise, you will learn to establish and manage recommendation remediation auto assignement and configuration through MDC Governance rules within Microsoft Defender for Cloud. 

Assume the role of a security administrator at a large organization managing multiple Azure subscriptions. Your challenge is to automate the remediation process for high-severity vulnerabilities, ensuring they are addressed promptly to maintain a robust security posture.

Through this exercise, you will configure a governance rule that ensures all high-severity vulnerabilities are remediated within 90 days, enhancing the security and compliance of your cloud environment. This process not only helps maintain your organization's security posture but also introduces a structured approach to managing cloud resources responsibly.

### Steps

1. Open **Azure Portal** and navigate to the **Microsoft Defender for Cloud** blade.
2. From the Defender for Cloud's menu, open the **Environment Settings** page and select the relevant subscription.
3. Under **Settings**, select **Governance Rules**.
4. Click on **+Create governance rule**.
5. Provide a **rule name**, select **scope** at subscription level, set **priority** to 100.
6. Under **conditions**:
   - Set **By severity** to **High**.
   - Set **Owner** to **By email address** and specify the email address of the workload owner who will receive notification emails.
   - Set **Remediation timeframe** to **90 days**.
7. Enable the option to **Notify Owners weekly about open and overdue tasks** and click **Save**.

   ![Governance Rule Creation](https://user-images.githubusercontent.com/102209701/215829686-cd5fc20c-32be-4822-be5f-04e5f85563c5.png)

8. After saving, click on **Governance report** to view the status of tasks, categorized as **Complete, Overdue, On-time, Unassigned**.

   ![Governance Report View](https://user-images.githubusercontent.com/102209701/215830577-947675fb-2f05-44a0-9482-fbd58a86d360.png)


## Exercise 6: Analyze Security Recommendations by Risk Level - Risk Prioritization

In this exercise, you will learn how to utilize the Risk Prioritization feature in Microsoft Defender for Cloud to analyze and prioritize security recommendations based on their risk levels. This capability allows security teams to focus on the most critical issues that could impact the security posture of their cloud environments.

You are part of a security team managing cloud assets for a multinational corporation. Due to the vast number of assets and continuous deployment cycles, it is crucial to prioritize security tasks effectively. By focusing on high-risk recommendations, you can optimize your remediation efforts and allocate resources more efficiently, enhancing overall security.

This exercise aims to enhance your ability to effectively prioritize and manage the remediation of security vulnerabilities within your cloud environment. By focusing on high-risk recommendations, you can ensure that critical vulnerabilities are addressed promptly, reducing the potential impact on your organization’s operations and data security.

### Steps

1. Open **Azure Portal** and navigate to the **Microsoft Defender for Cloud** blade.
2. Go to the **Recommendations** section.

![image](../Images/module17Img07.png?raw=true)

3. Sort or filter the recommendations by risk level by clicking on the **Risk level** column to sort from Low to Critical, or vice versa. This will organize the recommendations starting from the highest to the lowest risk levels. Here, you can view multiple valuable insights as they are exposed through each column of the records. You can see the risk factors that have contributed to the risk level evaluation, the number of attack paths found for the resource, whether an owner has been assigned to its remediation, and the status of the change.

![image](../Images/module17Img08.png?raw=true)


4. Select a high-risk recommendation to view detailed information about the risk factors, affected resources, and suggested remediation steps.

![image](../Images/module17Img09.png?raw=true)

5. Analyze the recommendation details to understand the potential business impact and the exploitability of the vulnerability. Perhaps you can view the findings by clicking the Findings tab, or you can view all the Attack paths found associated to the resource in question.
6. Plan and assign remediation tasks based on the priority of the risks. Use the integrated task management tools within Defender for Cloud to assign tasks to appropriate team members by clicking **Assign owner & set due date**.
7. Monitor the progress of remediation efforts through the **Governance and Compliance** dashboard to ensure that high-risk vulnerabilities are addressed in a timely manner.

## Exercise 7: Leverage Cloud Identity Entitlement Management - Permissions Management

This exercise will guide you through the process of enabling and using Permissions Management in Microsoft Defender for Cloud. This feature helps manage and secure identity and access configurations across your cloud environments, ensuring that permissions adhere to the principle of least privilege.

As a security administrator, you are tasked with reducing the risk of excessive permissions in your organization's cloud environments. Permissions Management allows you to track and manage entitlements efficiently, enhancing security and compliance.

This exercise aims to provide you with practical experience in managing cloud permissions, focusing on minimizing the risk associated with over-privileged identities and ensuring compliance with your organization’s security policies.

### Steps

1. **Sign in to the Azure Portal** and navigate to **Microsoft Defender for Cloud**.
2. In the left menu, select **Management/Environment settings**.
3. Choose the Azure subscription you want to manage and ensure the **Defender CSPM** plan is active.
4. Under the plan settings, enable the **Permissions Management** extension.
5. Click **Continue** and then **Save** to apply the changes. After a few minutes, you'll notice that:

    - Your subscription has a new Reader assignment for the Cloud Infrastructure Entitlement Management application.

    - The new Azure CSPM (Preview) standard is assigned to your subscription.

![image](../Images/module17Img10.png?raw=true)

6. After enabling, you can access the Permissions Management features through the Defender for Cloud portal.
7. Navigate to the **Recommendations** page to view new permissions-related recommendations.

![image](../Images/module17Img11.png?raw=true)

8. Use the Permissions Management capabilities to analyze and adjust permissions across your Azure, AWS, or GCP resources.

For further details on enabling and using Permissions Management, refer to the official [Microsoft documentation](https://learn.microsoft.com/en-us/azure/defender-for-cloud/enable-permissions-management).




 




