# Module 3 - Security Policy

<p align="left"><img src="../Images/asc-labs-intermediate.gif?raw=true"></p>

#### 🎓 Level: 200 (Intermediate)
#### ⌛ Estimated time to complete this lab: 60 minutes

## Objectives
This exercise guides you through the current Microsoft Defender for Cloud's security policies. These security policies are made of security standards and recommendations that help you improve your cloud security posture. Security standards are made of [Microsoft Cloud Security Benchmark (MCSB)](https://learn.microsoft.com/en-us/azure/defender-for-cloud/concept-regulatory-compliance), Regulatory compliance standards and custom standards. 
By the end of this exercise, you will know how to create exemptions, policy enforcements and custom policies.  

#### Prerequisites
To get started with Microsoft Defender for Cloud, you must have a subscription to Microsoft Azure. Please go through [Module 1](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module-1-Preparing-the-Environment.md) to get started with a free subscription. 

### Exercise 1: Overview of the Microsoft Defender for Cloud policy

1. On Microsoft Defender for Cloud blade, from the left navigation pave, click on **Environment Settings**. 
2. Then select **Subscription 1** and from the left navigation select **Security policy**.
3. Under the **Standards** tab, you will see MCSB and 241 recommendations. **Type** is **Default**. This is because MCSB is assigned by default when a management group or subscription is onboarded to Defender for Cloud.  

Note: As mentioned earlier, this is the default and was automatically assigned as part of onboarding to Microsoft Defender for Cloud. The default assignment contains only audit policies. For more information please visit https://aka.ms/ascpolicies. MCSB is a holistic collection of security recommendations and best practices from not only Azure but also your multi-cloud environment. 

4.	Click on the assign assignment: **Microsoft Cloud Security Benchmark**. Notice **Effect** is **Audit**. Microsoft Defender for Cloud assesses your environment and audits data. It does not enforce without your approval.
5.	Go back to the **Security policies** page. Click on **Recommendations** tab. Notice **Source** changes from **Defender for Cloud** and **Azure Policy**. Also take note of **Standards** column.  


### Exercise 2: Explore Azure Policy
1.	On Azure Portal, navigate to **Policy blade**. You can use the search box on the upper part for "Policy" or navigate to: https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyMenuBlade
2.	From the left navigation pane, under the **Authoring** section, click on **Definitions** to explore the built-in policy definitions and initiatives.
3.	From the top menu, use the filter button to set Category as **Security Center** and deselect **All**. Under **Definitions type**, select **Initiative** and deselect **All**.
4.	You can now see built-in initiatives used by Microsoft Defender for Cloud, some in Preview.
5. Notice the number of policies included in each initiative (policies column)
6. Now exit.

### Exercise 3: Create resource exemption for a recommendation

Resource exemption will allow increased granularity for you to fine-tune recommendations by providing the ability to exempt certain resources from evaluation.
When working with a recommendation, you can create an exemption by clicking the ellipsis menu on the right side and then select create exemption.

Note: Exemptions is a premium Azure policy capability that's offered for Microsoft Defender for Cloud customers with no additional cost. For other users, charges may apply in the future.

1.	Open **Microsoft Defender for Cloud blade** and from the left navigation pane and select **Recommendations**.
2.	Type in **"management ports**.
3.	Select the **Management ports should be closed on your virtual machines** recommendation.
4.	On the list of **unhealthy resources**, see the current resources: *asclab-win* and *asclab-linux*.
5.	Select the **asclab-win** resource and then click on **Create exemption**.

![Create exemption](../Images/asc-management-ports-resource-exemption.gif?raw=true)

6.	The create **exemption pane** opens:
   *	Keep the default name.
*	Click the expiration button ON and set datetime for two days ahead on 12:00 AM.

    - Select **Waiver** as exemption category.
    - Provide a description: **Testing exemption capability – module 3**.
    - Select **Save**.
  
  ![Modifying Microsoft Defender for Cloud default policy assignment](../Images/Inkedlab3pl6.gif?raw=true)
  
> ⭐ Good to know: <br>
> **Mitigated** - This issue isn't relevant to the resource because it's been handled by a different tool or process than the one being suggested
> **Waiver** - Accepting the risk for this resource

7.	It might take up to **30 min for exemption to take effect**. Once this happens:
    - The resource doesn't impact your secure score.
    - The resource is listed in the Not applicable tab of the recommendation details page
    - The information strip at the top of the recommendation details page lists the number of exempted resources: **1**

8.	Open the **Not applicable** tab to review your exempted resource – you can see our resource along with the reason / description value.
9.	Exemption rules is based on Azure Policy capability. Therefore, you can track all your exemptions from Azure Policy blade as well.
10.	Navigate to **Azure Policy blade** and select **Exemptions** from the left navigation pane. Notice your newly created exemption listed there.

### Exercise 4: Create a policy enforcement and deny

1.	From **Microsoft Defender for Cloud sidebar**, select **Recommendations**.
2.  Search for **Secure transfer to storage accounts should be enabled**.
3.	From the top menu bar, click on **Deny** button. *Enforce and Deny options provide you another way to improve your score by preventing security misconfigurations*.

> ❗ Important: <br>
> Security misconfigurations are a major cause of security incidents

4.	On the **Deny - Prevent resource creation**, select **Azure subscription 1** (which is currently set to audit mode). This allow you to ensure that from now on, storage account without the security transfer feature turned on will be denied.

![Prevent resource creation](../Images/asc-storage-deny-policy.gif?raw=true)

5.	Go back to the **Recommendations view**, and remove the Deny-only filter. From the search area, type **Auditing**. Click on the recommendation **Auditing on SQL server should be enabled**.

![Auditing on SQL server should be enabled](../Images/asc-auditing-sql.gif?raw=true)

6.	On the recommendations page, from the top menu bar, click on **Enforce** button. Using this option allow you to take advantage of Azure policy’s DeployIfNotExist effect and automatically remediate non-compliant resources upon creation.
7.	Once the configuration pane opens with all of the policy configuration options, select the following configuration settings:

* On Scope, select your subscription. **Click Select**.
* Click **Next**
* Keep retention days as is and select then resource group **asclab**
Select **Review + create** to assign the policy on your subscription.
* Click **Create**

9. On the recommendation page, **select** the SQL Server resource found on the **unhealthy resources** tab (asclab-sql-xxx) and click **Remediate**. Click **Remediate 1 resource**. By doing both operations, you can now be ensure your existing resources and new ones will be enabled for auditing. Auditing on your SQL Server helps you track database activities across all databases on the server and save them in an audit log.
10.	[Click here](https://learn.microsoft.com/en-us/azure/defender-for-cloud/secure-score-security-controls#secure-score-controls) to review a list of security controls and their recommendations.

### Exercise 5: Create a custom recommendation

***Create a custom initiative using KQL Query***
For this exercise, we will use an existing recommendation ([Preview]: Storage account public access should be disallowed) to create a custom one. 
1.	Navigate to **Security Policy** for your subscription.
2.	Select **Create recommendation** from the **+Create** drop down on the top.
3.	On the **Create a new recommendation** page, provide the following:
    - Name: customrecommendation_module3
    - Description: [Preview]: Storage account public access should be disallowed
    - Remediation description: Anonymous public read access to containers and blobs in Azure Storage is a convenient way to share data but might present security risks. To prevent data breaches caused by undesired anonymous access, Microsoft recommends preventing public access to a storage account unless your scenario requires it.
    - Severity:  High
    - Security issue: Anonymous Access
  
4.	Use the query editor to build or test your KQL Query. Once that's done add your query to the **Recommendation query**. 
7. Select **Next**. Click **Save**.
8. In a few minutes, navigate back to **Security policies** under your subscription.
9. Click on the **Recommendations** tab and you should see the custom policy we just created.

Learn more about custom recommendations and standards by visiting this [page](https://learn.microsoft.com/en-us/azure/defender-for-cloud/create-custom-recommendations)

### Continue with the next lab: [Module 4 - Regulatory Compliance](../Modules/Module-4-Regulatory-Compliance.md)
