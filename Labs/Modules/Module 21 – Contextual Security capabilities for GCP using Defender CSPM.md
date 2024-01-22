# Module 21 –Contextual Security capabilities for GCP using Defender CSPM  

<p align="left"><img src="../Images/asc-labs-intermediate.gif?raw=true"></p>

#### 💁 Authors: 
Bojan Magusic [Github](https://github.com/bomagusi), [Linkedin](https://www.linkedin.com/in/bojanmagusic/)

#### 🎓 Level: 200 (Intermediate)
#### ⌛ Estimated time to complete this lab: 60 minutes
<br />

## Objectives
This module teaches you how to leverage Defender CSPM's capabilities for your GCP environment, by guiding you how to enable Defender CSPM for GCP projects and organizations.

## Scenario for this Lab:

Contoso company operates a platform that deals with its customers' sensitive data, such as personal information, financial details, and medical records. 
The company prioritizes data privacy and security to protect its customers' sensitive information from unauthorized access and data breaches. 

The company conducts regular internal and external security audits and vulnerability assessments to identify potential weaknesses in their systems. 
These assessments help in identifying and addressing security vulnerabilities proactively. 
As part of the regular security Audit, contoso company can proactively identify and address potential security risks in their GCP environment. 
The security team enabled Defender CSPM plan for their GCP environment to proactively identify common vulnerabilities, misconfigurations, and potential weaknesses in their GCP environment. 

## Exercise 1: Preparing the GCP Environment for Defender CSPM plan 

To enable Defender CSPM during onboarding of new GCP projects or organizations, perform the steps outlined at [Module 10 – Connecting a GCP Project](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module-10-GCP.md). 

To enable Defender CSPM on already onboarded GCP projects or organizations, perform the following steps in sequence: 
1. Sign in to the **Azure portal**. 
2. Navigate to **Defender for Cloud**, then go to **Environment settings**.
3. Select the relevant GCP Connector on which you want to enable Defender CSPM.  
4.	Under Select Plans -> Turn **Defender CSPM** to **ON** and click on **Settings**.
   ![image](../Images/module21enableDCSPM.png?raw=true)
5.	Under **Auto-provisioning** configuration, Turn On **Agentless Scanning**, **Sensitive Data Discovery** and **Permissions Management** capabilities and click **Save**.
   ![image](../Images/module21enableDCSPMSettings.png?raw=true)
6.	Click **Next: Configure Access**.
   ![image](../Images/module21ConfigureAccess.png?raw=true)
7.	Choose a deployment method: **GCP Cloud shell** or **Terraform** and **Copy** or **Download** the Script/Template. 
8. If you selected GCP Cloud shell as a deployment method, log in to GCP Cloud Shell, paste the script into the Cloud Shell terminal and run it.
    ![GCP console with Cloud Shell](../Images/7gcpconsole.png?raw=true)
9. Let the script run and after it finishes successfully return to Defender for Cloud. 
10. Select **I ran the deployment template for the changes to take effect** and click **Next: Review and generate**.
11. Click **Update**

## Exercise 2: Explore Attack Paths in your AWS Environment

1.	Open **Azure Portal** and navigate to **Microsoft Defender for Cloud** blade.
2.	From **Defender for Cloud**'s menu, elect open the **Attack Path Analysis** page.
3.	To filter for attack paths related to GCP only, click **Add filter**, select **Environment**, then choose **GCP** and click **Apply**.
4.	You will find the Attack Paths in your GCP Environment. Select a particulat attack path to investigate it further, like **”Publicly accessible GCP storage bucket with sensitive data (Preview)”**
   
   ![image](../Images/module21AttackPathsGCP.png?raw=true)
  	
4.	You can observe the risk involved is **Internet Exposure** and **Sensitive Data**. Click the GCP storage bucket to drill down to the sensitive data stored in the storage bucket.

5.	The **Insights** tab provides the detailed insights of the Attack path. You can drill down further on **Insights - Contains Sensitive Data**, to check what files contains sensitive data and Sensitive Info Types.
6.	Remediate the recommendations to resolve the attack path.
7.	Explore the rest of the Attack paths found in your Environment and remidiate the relevant recommendations.

## Exercise 3: Build query with Cloud Security Explorer

The Cloud Security Explorer allows you to proactively identify risk in your GCP environment for a wide range of scenario. Imagine, you wanted to identify which GCP Compute Instances are exposed to the Internet and contain SAS tokens. To accomplish this scenario you can perform the following steps: 

1.	Open **Azure Portal** and navigate to **Microsoft Defender for Cloud** blade.
2.	From **Defender for Cloud**'s menu, open the **Cloud Security Explorer** page, build the query as shown below and click **Done** and **Search**.

   ![image](../Images/module21CloudSecurityExplorerQuery.png?raw=true)
   ![image](../Images/module21CloudSecurityExplorerCondition.png?raw=true)
   ![image](../Images/module21CloudSecurityExplorerContains.png?raw=true)

3.	In the list of results, you can select a particular GCP Compute Instance and drill down further to observe the Insights. 

## Clean up GCP Resources

To clean up the resources created by Defender CSPM in the GCP environment, log in to GCP Cloud Shell and delete the relevant resources, like the policies/role bindings created by Defender for Cloud during the enablement of Defender CSPM. To validate the names of the GCP resources you need to delete, you start by analyzing the deployment method you used to enable Defender CSPM, like in this module the GCP Cloud Shell which contains the names of the GCP resources that Defender for Cloud creates for Defender CSPM.


