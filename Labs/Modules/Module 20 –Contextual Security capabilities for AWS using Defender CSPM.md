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

If you already finished Module 11 of this lab, (Module 11 – Connecting an AWS Account, Preparing the Environment), you will deploy an extended environment for Defender CSPM plan. 
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



