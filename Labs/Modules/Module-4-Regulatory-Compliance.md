# Module 4 - Regulatory Compliance

<p align="left"><img src="../Images/asc-labs-intermediate.gif?raw=true"></p>

#### 🎓 Level: 200 (Intermediate)
#### ⌛ Estimated time to complete this lab: 60 minutes

## Objectives
This exercise guides you through the current Microsoft Defender for Cloud's Regulatory Compliance feature. Defender for Cloud helps customers meet such requirements by assessing their resources' posture against a particular standard through the Regulatory Compliance dashboard. This exercise will walk you through this feature, but for official documentation visit this [page](https://learn.microsoft.com/en-us/azure/defender-for-cloud/regulatory-compliance-dashboard).  

### Exercise 1: Understanding Regulatory Compliance dashboard

1.	From **Microsoft Defender for Cloud main dashboard**, select **Regulatory Compliance** tile (this pilar is also available from the sidebar under Cloud Security).
2.	Regulatory Compliance dashboard opens. On this page, you can see the compliance standards currently assigned to your subscription.
3.	On the top strip, notice the number of **passed controls** for Microsoft cloud security benchmark.

### Exercise 2: Adding new standards in Azure and multicloud

You can add additional industry standards (represented as compliance packages) such as IST SP 800-53 R4, SWIFT CSP CSCF-v2020, UK Official and more.

1.	From the top menu bar in Regulatory Compliance, select **Manage compliance policies**.
2.	Select your subsciption.
<br> Note: <br>
If you want to assign a standard in AWS or GCP, choose an AWS or GCP connection and then go directly to **Security policies** on the left. Available compliance standards in all three clouds are documented [here](https://learn.microsoft.com/en-us/azure/defender-for-cloud/concept-regulatory-compliance-standards#available-compliance-standards). 
<br> Another note: <br>
Modules [10](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module-10-GCP.md) and [11](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module-11-AWS.md) will walk through creating those multicloud connectors. Feel free to skip to those modules and then come back. 
3.  Select **Security policies**. 
4.	Under the **Standards** tab, look for *CIS Microsoft Azure Foundations Benchmark v2.0.0*.
5.  Select the standard. 
6.  Notice the number of **audit** and **manual** policy definitions. 
**Audit effect**: When a resource does not adhere to the specific policy definition, Policy will mark said resource as **non-compliant** and create a warning in the activity log but it won't take action on the actual resource. Visit this[page](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/effect-audit) to learn more about the audit effect. 
**Manual effect**: Sometimes, when some operations or tasks cannot be automated or requires updating of resource's compliance state, manual attestation is required. To learn more about this, check out this [page](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/effect-manual). 
7.  Search for **rotation** in the search box. **Keys should have a rotation policy ensuring that their rotation is scheduled within the specified number of days after creation.** should come up. Notice **Additional parameters** is set to **Configured**. 
8.  Click on the ellipses to **view policy definition**. 
When assigning this standard to your scope (subscription or management group), you will be asked to input a value of the maximum days to rotate keys, per this policy definition. 
9.  Navigate back to the **Standards** page and click toggle **On** for *CIS Microsoft Azure Foundations Benchmark v2.0.0*. 
10.  Input the value that adheres to your organization's policy or, for this lab purpose only, input **30**. 
11.  In a few hours, this new standard will display in the **Regulatory Compliance** dashbard, next to the default MCSB. 
> ❗ Important: <br>
> It will take a while until the change takes an effect (2-3 hours).
  
### Exercise 3: Exploring a benchmark 
1. Navigate to the standard you've chosen for Exercise 2. For the lab, we chose *CIS Microsoft Azure Foundations Benchmark v2.0.0*. Notice the different compliance controls mapped to assessments.
2.	Search for **Secure transfer to storage accounts should be enabled.**
3.	Click to open **Secure transfer to storage accounts should be enabled.**
4.	In the new pane, tick the box for the unhealthy resource titled asclabXXXXXX, and select **Fix** at the bottom of the page. 
5.	Then in the pop-up tab click Fix 1 resource. Your Storage account now has secure transfer enabled.
6.	Return to the dashboard. You can export regulatory standard compliance status as a PDF report or CSV file. From the top menu bar, select **Download report**.
7.	On the Report standard dropdown menu, select *CIS Microsoft Azure Foundations Benchmark v2.0.0* and **PDF**. Click **Download**
8. A local PDF file is now stored on your machine. Open the **CIS Microsoft Azure Foundations Benchmark v2.0.0** and explore the compliance report – This report summarizes the status of those assessments on your environment, as they map to the associated controls.

### Exercise 4: Creating your own benchmark!
For the sake of simplicity, while you can create your own "benchmark", we will use the term "standard" in this exericse. A standard can be made up of one or more recommendations. 
Once you create your custom standard, Defender for Cloud allows you to add it as security policy and which provides two main benefits:
* Having security requirements represent as custom recommendations under the recommendation list.
* Having a way to track compliance status using Regulatory Compliance dashboard.
1.	Navigate to Regulatory Compliance in Defender for Cloud.
2.	From the top menu, select **Manage compliance standards** to create custom standard.
3.	Select a scope as a location for the new definition. The recommended approach is to select management groups if they have been assigned but in our scenario select your subscription as the scope.
4.	Select **Security policies**.
5.	Click on **+Custom standard** from the **+Create** dropdown on top. 
6.  Provide a name like "Module 4 custom standard".
7.  Add a description.
8.  Now you can choose the different recommendations you want to have as part of this standard. 
9.  Click **Create**.
10.	You will be redirected to the **Security policies** page. Sort by **Status** to see your newly created standard applied to your subscription.
![module4_customstandard](https://github.com/Azure/Microsoft-Defender-for-Cloud/assets/45104504/aba2680c-9d1e-4fae-bb98-63ea3627c9a4)


### Exercise 5 Azure Audit Reports

Now in Microsoft Defender for Cloud, you can easily create & download Audit reports for Regulatory Compliance Standards.
1.	From Microsoft Defender for Cloud, select Regulatory Compliance from the sidebar
2.	Then click on Audit Reports found at the top of the page
![Regulatory compliance assessment and standards](../Images/lab4rc6.jpg?raw=true)
3.	Select PCI from the tabs, and download 2021 - Azure PCI 3DS 1.0 Package, and click download
![Regulatory compliance assessment and standards](../Images/lab4rc7.jpg?raw=true)
4.	Press download on the Privacy Notice pop-up that appears.
You now have the audit report downloaded.


### Exercise 6 Continuous Export & Compliance over time workbook

Compliance dashboard over time is a Workbook in Microsoft Defender for Cloud dedicated to tracking a subscription's compliance with the regulatory or industry standards applied to it. Read more about it [here](https://learn.microsoft.com/en-us/azure/defender-for-cloud/custom-dashboards-azure-workbooks#compliance-over-time-workbook). To leverage this workbook, you'll need to configure continuous export first to export data to a Log Analytics workspace:
1.	From Microsoft Defender for Cloud's sidebar, select **Environment Settings**.
2.	Select the subscription for which you want to configure the data export.
3.	From the sidebar of the settings page for that subscription, select **Continuous Export**.
4.	Click on the **Log Analytics workspace**. Set the export enable to **On** (which is the tab beside Event hub).
5.	Leave settings as is. Check off box next to **Regulatory compliance** and choose **Select All**
6.	From the export frequency options, select both **Streaming updates** and **Snapshots**.
7.	Select target workspace and the Resource Group to be those you created earlier.
9.	Select Save. You might get a message about Sentinel alerts connector already enabled. Click **Confirm**.
10.	Wait for the first snapshot to occur. 

Compliance dashboard over time 
1.	Go to Microsoft Defender for Cloud, and from the left navigation pane, under the **General** section, choose on the **Workbooks** button. 
2.	Select **Compliance Over Time** workbook located under **Defender for Cloud**.
3.	For the workspace, select **asclab-la-XXXXXXXXXX** 
4.	For the subscription, select your subscription.
5.	For the standard name, select **All**, and now you can see the workbook.
![Regulatory compliance assessment and standards](../Images/lab4rc11.jpg?raw=true)
>Note 1: You need to complete the previous exercise of setting up Continuous Export to the Log Analytics workspace for the Compliance Over Time Workbook to work.
>Note 2: If you see the error below, you will need to wait for a week for this workbook to populate with data through Continuous Export.
![Regulatory compliance assessment and standards](../Images/lab4rc12.gif?raw=true)


### Continue with the next lab: [Module 5 - Improving your Secure Posture](../Modules/Module-5-Improving-your-Secure-Posture.md)
