# Module 11 - Connecting an AWS  project

<p align="left"><img src="../Images/asc-labs-advanced.gif?raw=true"></p>

#### 🎓 Level: 300 (Advanced)
#### ⌛ Estimated time to complete this lab: 60 minutes

## Objectives
This exercise guides you on how to connect and protect GCP projects using Defender for Cloud.

### Exercise 1: Create an AWS account

First you need to create an AWS account project. 

1.	Navigate to [Create free AWS](https://portal.aws.amazon.com/billing/signup?refid=em_127222&redirect_url=https%3A%2F%2Faws.amazon.com%2Fregistration-confirmation#/start/email)  
2.  Click **Create a free account**.
3.  Follow the guidance in AWS to create a free account.

 ![Create free AWS account](../Images/create-free-aws.png?raw=true)

### Exercise 2: Create an AWS connector for the new AWS account in Microsoft Defender for Cloud

1. Sign in to the Azure portal.
2. Navigate to **Defender for Cloud**, then go to **Environment settings**.
3. Select **Add environment**, then choose **Amazon Web Services**.
4. Connecting an AWS account to an Azure subscription.
5. Enter the details of the AWS account, including the location where you'll store the connector resource.
 ![Add AWS account](../Images/add-aws-account.png?raw=true)
6. Select **Next: Select plans**.

The CSPM plan is enabled by default.

7. Ensure that the Servers, Containers and Database plans are set to **On**. 
 ![Enable Defender plans in AWS](../Images/aws-select-plans.png?raw=true)
8. Select **Configure** on each of the plans, to enable all the necessary configurations.
9. Select **Next: Configure access**.
10. Click **Download the CloudFormation template**.
11. After the CloudFormation template has been downloaded, then you'll see a Service Principal secret which has been generated. Copy it and keep it somewhere safe as you'll be needing it later.
 ![Service Principal Secret](../Images/aws-service-principal-secret.png?raw=true)
11. Login to your AWS account at [AWS portal](https://portal.aws.amazon.com/billing/signup?refid=em_127222&redirect_url=https%3A%2F%2Faws.amazon.com%2Fregistration-confirmation#/start/email) .
12. Search for **create stack** and select **cloud formation**.
 ![AWS stack of type cloud formation](../Images/aws-stack-cloud-formation.png?raw=true)
12. Select **template is ready** 
 ![AWS stack of type cloud formation](../Images/stack-template-aws.png?raw=true)
13. Click **upload a template** and **choose file**. Here, input the downloaded CloudFormation template.
14. Then give the stack a name, and also paste the Service Principal secret, which you copied earlier, in the ArcAutoProvisioningServicePrincipalSecret field.
15. Leave everything else as default, and click **next**.
16. Select **create stack**.
17. Wait a few minutes for the stack to be successfully created in AWS.
18. After the stack has been created, then go back to the other tab with the **Azure Portal**'s Microsoft Defender for Cloud experience.
19. In Defender for Cloud, click **Next: Review and Generate**.
14. Select **Create**.

Defender for Cloud will immediately start scanning your AWS resources and you'll see security recommendations in the Recommendations blade in Microsoft Defender for Cloud within a few hours. 

