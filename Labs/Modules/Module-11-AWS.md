# Module 11 - Connecting an AWS  project

<p align="left"><img src="../Images/asc-labs-advanced.gif?raw=true"></p>

#### 🎓 Level: 300 (Advanced)
#### ⌛ Estimated time to complete this lab: 60 minutes

## Objectives
This exercise guides you on how to connect and protect AWS projects using Defender for Cloud.

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
5. Enter the details of the AWS account, including the location where you'll store the connector resource. Select the *Single account* option. 
 ![Add AWS account](../Images/add-aws-account.png?raw=true)
6. Select **Next: Select plans**.

The Foundational CSPM plan is enabled by default.

7. Ensure that the Defender CSPM, Servers, Containers and Database plans are set to **On**. 
 ![Enable Defender plans in AWS](../Images/aws-select-plans.png?raw=true)
8. Select **Configure** on each of the plans, to enable all the necessary configurations.
9. Select **Next: Configure access**.
10. Click **Download the CloudFormation template**.
11. After the CloudFormation template has been downloaded, you can proceed with creating a stack in AWS.
 ![Service Principal Secret](../Images/aws-service-principal-secret.png?raw=true)
12. Login to your AWS account at [AWS portal](https://portal.aws.amazon.com/billing/signup?refid=em_127222&redirect_url=https%3A%2F%2Faws.amazon.com%2Fregistration-confirmation#/start/email) .
13. Search for **create stack** and select **cloud formation**.
 ![AWS stack of type cloud formation](../Images/aws-stack-cloud-formation.png?raw=true)
14. Select **template is ready** 
 ![AWS stack of type cloud formation](../Images/stack-template-aws.png?raw=true)
15. Click **upload a template** and **choose file**. Here, input the downloaded CloudFormation template.
16. Then give the stack a name.
17. Leave everything else as default, and click **Next**.
18. On **Review** check **I acknowledge that AWS CloudFormation might create IAM resources with custom names**, and click **Submit**.
19. Select **Create stack**.
20. Wait a few minutes for the stack to be successfully created in AWS.
21. After the stack has been created, then go back to the other tab with the **Azure Portal**'s Microsoft Defender for Cloud experience.
22. In Defender for Cloud, click **Next: Review and Generate**.
23. Select **Create**.

Now, you have successfully onboarded AWS to Microsoft Defender for Cloud, you'll be able to get AWS recommendations and alerts.

### Exercise 3: Investigate the AWS recommendations 

> [!NOTE]
> You will need to create some AWS resources in order to see recommendations for AWS in Microsoft Defender for Cloud.
 
 1. Go to **Microsoft Defender for Cloud** in the **Azure Portal**.
 2. Go to the **Recommendations** tab in Defender for Cloud.
 3. In the upper taskbar, under **Scope**, select **AWS** only. 
 
![AWS Recommendations](../Images/8awsrecommendations.png?raw=true)

If you have existing AWS resources, then you'll be able to see recommendations associated with them.

