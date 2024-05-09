# Module 20 –Contextual Security capabilities for AWS using Defender CSPM  

<p align="left"><img src="../Images/asc-labs-intermediate.gif?raw=true"></p>

#### 💁 Authors: 
Vasavi Pasula [Github](https://github.com/vapasula), [Linkedin](https://www.linkedin.com/in/pasulavasavi/)

#### 🎓 Level: 200 (Intermediate)
#### ⌛ Estimated time to complete this lab: 60 minutes
<br />

## Objectives
In this exercise, you will learn how to enable Defender for CSPM for onboarded AWS accounts and leverage Defender for CSPM Capabilities 

## Scenario for this Lab: 

Contoso company operates a platform that deals with its customers' sensitive data, such as personal information, financial details, and medical records. 
The company prioritizes data privacy and security to protect its customers' sensitive information from unauthorized access and data breaches. 

The company conducts regular internal and external security audits and vulnerability assessments to identify potential weaknesses in their systems. 
These assessments help in identifying and addressing security vulnerabilities proactively. 
As part of the regular security Audit, contoso company can proactively identify and address potential security risks in their AWS environment. 
The security team enabled Defender CSPM plan for their AWS environment to proactively identify common vulnerabilities, misconfigurations, and potential weaknesses 
in their AWS environment. 

## Exercise 1: Preparing the AWS Environment for Defender CSPM plan 

If you already finished Module 11 of this lab, [Module 11 – Connecting an AWS Account, Preparing the Environment](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module-11-AWS.md), you will deploy an extended environment for Defender CSPM plan. 
1. Sign in to the **Azure portal**. 
2. Navigate to **Defender for Cloud**, then go to **Environment settings**.
3. Select an onboarded AWS Connector 
![image](https://github.com/Azure/Microsoft-Defender-for-Cloud/assets/102209701/f0d5ef05-384f-4722-8c6e-69b47ff18b02)
4.	Under Select Plans -> Turn **Defender CSPM** to **ON** and click on **settings**
   ![image](https://github.com/Azure/Microsoft-Defender-for-Cloud/assets/102209701/3d4496c8-2860-4e48-9b78-8df6c5222206)

5.	Under **Auto-provisioning** configuration, Turn On **Agentless Scanning** and **Sensitive Data Discovery** capabilities and click **Save**.
   ![image](https://github.com/Azure/Microsoft-Defender-for-Cloud/assets/102209701/6cea2a78-d5db-47ec-ac35-3909c127c28e)
6.	Click **Next: Configure Access**
   ![image](https://github.com/Azure/Microsoft-Defender-for-Cloud/assets/102209701/27750503-8598-459d-8f69-75ab8812882e)
7.	Choose a deployment method: **AWS CloudFormation** or **Terraform** and **Download** the Template
8.	Under update stack in AWS, select the checkbox **CloudFormation template has been updated on AWS environment** and click **Review and Generate**
   ![image](https://github.com/Azure/Microsoft-Defender-for-Cloud/assets/102209701/cfb22e34-6bca-43a2-b887-5ce6d094d4b1)
9.	Observe the new IAM roles are created for Defender CSPM plan. Click on **Update**

Note: Updating plan selection requires an update of the CloudFormation template to add or remove access roles. Without performing this action, Defender will only have partial access to your environment.
![image](https://github.com/Azure/Microsoft-Defender-for-Cloud/assets/102209701/18cea134-bb1d-41e7-a219-a77109bf39ef)

10.	Deploy the CloudFormation template by using Stack
    ![image](https://github.com/Azure/Microsoft-Defender-for-Cloud/assets/102209701/0d148702-aed8-4726-bb1b-3a638df51e33)
11.	Upload the downloaded CloudFormation template and click **Next**
12.	Specify a stack name and click **Next** and **Submit**.
    ![image](https://github.com/Azure/Microsoft-Defender-for-Cloud/assets/102209701/c2266de1-5568-401e-8b53-4059e327b1e7)
13.	Wait till the Stack deployment is complete
    ![image](https://github.com/Azure/Microsoft-Defender-for-Cloud/assets/102209701/6356b52d-93e6-4fcc-a2a2-223fcc6f4ce9)
14. In the AWS console search bar, type **S3** and go to S3 console
15. Click on Block Public Access Settings for this Account
    ![image](https://github.com/Azure/Microsoft-Defender-for-Cloud/assets/102209701/3dc0de4f-b0bd-4c6a-b6fc-374566bce0b2)
16. Click Edit and Uncheck **Block Public Access** and click on **Save Changes**
    ![image](https://github.com/Azure/Microsoft-Defender-for-Cloud/assets/102209701/8c820bcd-2a2c-4182-a442-1630ee12040e)

18.	In the AWS Console deploy the AWS Resources required for the Lab Scenario using the [Cloud Formation Template](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Files/AWS-Cloudformation-Template.json). Repeat Steps 10 to 13. wait till the stack is deployed.
19. Go to S3 console, select the S3 Bucket created and upload the [sample data](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Files/sample-data.docx) file to your S3 Bucket
    ![image](https://github.com/Azure/Microsoft-Defender-for-Cloud/assets/102209701/d9111229-b765-419d-9b6c-0f4ea35629b4)

    ![image](https://github.com/Azure/Microsoft-Defender-for-Cloud/assets/102209701/7390c4b4-85d2-4706-820b-e46674b3cba9)

21. Wait for **24 hours** and come back to the setup

## Exercise 2: Explore Attack Paths in your AWS Environment
1.	Open **Azure Portal** and navigate to **Microsoft Defender for Cloud** blade.
2.	From **Defender for Cloud**'s menu, open the **Attack Path Analysis** page
3.	You will find the Attack Paths in your AWS Environment. Click on **“Internet exposed AWS S3 Bucket with sensitive data is publicly accessible”**
   
   ![image](https://github.com/Azure/Microsoft-Defender-for-Cloud/assets/102209701/7355af25-6b4e-4a7e-8229-144e3e96003c)
  	
4.	You can observe the risk involved is **Sensitive Data Exposure** and Potential Impact. Click on the S3 bucket to drill down the sensitive data stored in the S3 bucket.
   
   ![image](https://github.com/Azure/Microsoft-Defender-for-Cloud/assets/102209701/b4b4dc7e-186d-46c2-9812-e0cb1a013b8e)

5.	The **Insights** tab provides the detailed insights of the Attack path. You can observe the Insights **Exposed to the Internet, Allows Public access, Contains Sensitive Data**. You can drill down further on Contains Sensitive Data, to check what files contains sensitive data and Sensitive Info Types.

![image](https://github.com/Azure/Microsoft-Defender-for-Cloud/assets/102209701/cda2bb60-dfb7-428c-a040-6e004375fadf)

6.	Remediate the recommendations to resolve the attack path
7.	Explore the rest of the Attack paths found in your Environment and remidiate


## Exercise 3: Build query with Cloud Security Explorer
1.	Open **Azure Portal** and navigate to **Microsoft Defender for Cloud** blade.
2.	From **Defender for Cloud**'s menu, open the **Cloud Security Explorer** page, build the query as shown below and click **Done** and **search**

![image](https://github.com/Azure/Microsoft-Defender-for-Cloud/assets/102209701/35f2fff2-80b0-4437-9ef8-6e9a09c498f1)

![image](https://github.com/Azure/Microsoft-Defender-for-Cloud/assets/102209701/309e904b-0868-49b5-b3c7-0c7758a0af01)

![image](https://github.com/Azure/Microsoft-Defender-for-Cloud/assets/102209701/5246ca77-4455-4e5d-8c99-ee3c1d6d2f8f)

![image](https://github.com/Azure/Microsoft-Defender-for-Cloud/assets/102209701/74a8af18-9593-4489-a59f-65e1c547a5a0)

3.	You can drill down further to observe the Insights and secrets file stored on the EC2 Instance 

![image](https://github.com/Azure/Microsoft-Defender-for-Cloud/assets/102209701/39eaa344-e447-42fd-800a-001a38addb57)

## Clean up AWS Resources
1.	In the AWS Console, Go to Cloud Formation console, select the Stack you deployed and click on Delete to delete the resources created in the AWS account
   
![image](https://github.com/Azure/Microsoft-Defender-for-Cloud/assets/102209701/4acc0b99-9b6f-43e7-a07c-04da8597f22a)











