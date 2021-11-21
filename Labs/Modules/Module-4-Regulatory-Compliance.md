# Module 4 - Regulatory Compliance

<p align="left"><img src="../Images/asc-labs-intermediate.gif?raw=true"></p>

#### 🎓 Level: 200 (Intermediate)
#### ⌛ Estimated time to complete this lab: 60 minutes

## Objectives
This exercise guides you through the current Microsoft Defender for Cloud policies, based on Azure Policy, and shows you where to enable or disable Microsoft Defender for Cloud polices.

### Exercise 1: Understanding Regulatory Compliance dashboard

1.	From **Microsoft Defender for Cloud main dashboard**, select **Regulatory Compliance** tile (this pilar is also available from the sidebar under Cloud Security).
2.	Regulatory Compliance dashboard opens. On this page, you can see the compliance standards currently assigned to your subscription.
3.	On the top strip, notice the number of **passed controls** for Azure Security Benchmark.

### Exercise 2: Adding new standards

You can add additional industry standards (represented as compliance packages) such as IST SP 800-53 R4, SWIFT CSP CSCF-v2020, UK Official and more.

1.	From the top menu bar in Regulatory Compliance, select **Manage compliance policies**.
2.	Select a scope to assign the new package: **Azure subscription 1**.
3.	On the **Industry & regulatory standards** section, notice the out of the box standards. Click on **Add more standards**.
4.	On the **Add regulatory compliance standards**, locate the **Azure CIS 1.1.0 (New)** standard and select **Add**.
![Regulatory compliance assessment and standards](../Images/lab4rc4.gif?raw=true)
5.	Click **Assign the Policy**. For scope, select azure subscription 1, and leave all other options as default.

6.	Click **Review + create** and then **Create**.
![Add CIS 1.1.0 (New) Standard](../Images/asc-azure-cis-new-standard.gif?raw=true)

> ❗ Important: <br>
> It will take a while until the change takes an effect (2-3 hours).

7.	**Azure CIS 1.1.0 (New)** should now be listed on the standards list.
   
### Exercise 3: Exploring a benchmark 
1.	From the top menu bar in Regulatory Compliance, select **Manage compliance policies** which can be found under the Lowest compliance regulatory standards tile.
2. Then select **Azure Subscription 1** and choose **Security Policy** from the sidebar.
3.	On the **Industry & regulatory standards** section, notice the out of the box standards under **Industry & regulatory standards**.
4.	Locate the **PCI DSS 3.2.1** standard and select **Enable**.
![Regulatory compliance assessment and standards](../Images/mdfc-pci.png?raw=true)
5. Select **yes** to the pop-up asking you to enable PCI DSS.
6.	**PCI DSS 3.2.1** should now be listed as enabled.

Once you have enabled PCI DSS 3.2.1, now we will explore a particular control included in it.

1. From the **regulatory compliance** page, select **PCI DSS 3.2.1.** Notice the different compliance controls mapped to assessments.

![Regulatory compliance assessment and standards](../Images/lab4rc1.gif?raw=true)

2.	Click to open up **Encrypt transmission of cardholder data across open, public networks.**
3.	Click to open **control 4.1**
![Regulatory compliance assessment and standards](../Images/lab4rc2.gif?raw=true)
4.	Click to open **Secure transfer to storage accounts should be enabled.**
5.	In the new pane, tick the box for the unhealthy resource titled asclabXXXXXX, and select **Fix** at the bottom of the page. 
![Regulatory compliance assessment and standards](../Images/lab4rc3.jpg?raw=true)
6.	Then in the pop-up tab click Fix 1 resource. Your Storage account now has secure transfer enabled.
7.	Return to the dashboard. You can export regulatory standard compliance status as a PDF report or CSV file. From the top menu bar, select Download report.
8.	On the Report standard dropdown menu, select **PSI DSS 3.2.1** and **PDF**. Click **Download**
9.	A local PDF file is now stored on your machine. Open the **PCI DSS 3.2.1 Compliance Report** and explore the compliance report – This report summarizes the status of those assessments on your environment, as they map to the associated controls.

### Exercise 4: Creating your own benchmark

Once you create your custom initiative, Microsoft Defender for Cloud allows you to add it as security policy and which provides two main benefits:
* Having security requirements represent as custom recommendations under the recommendation list.
* Having a way to track compliance status using regulatory compliance dashboard.

Navigate to Azure Policy blade. You can also select this [link](https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyMenuBlade/Overview).

1.	From the left pane, select **Definitions**.
2.	From the top menu, select **+ initiative definition** to create a new policy set definition.
3.	On the Basics tab, select a **scope as a location for the new definition**. The recommended approach is to select management groups if they have been assigned but in our scenario select your subscription "Azure subscription 1" as the scope.
4.	Select a name, for example: **Custom Benchmark**.
5.	Provide an informative description so others can be clear on what is the purpose of this new security policy.
6.	Select **Category**. You can decide to use existing one (for example: Microsoft Defender for Cloud) or to create your own one. *The recommended approach is to use a custom one so you can quickly filter policy definitions and initiatives when needed (for example: Contoso)*.
7.	Select **Version** number. Each policy definition and initiative contain a version in its metadata section. You can decide to have major versions (1.0), minor version (1.1) and so.  Click **Next**.
8.	Click **Groups**, to define your groups and subgroups to be used in your initiative. To add a new group, click **Create Group**.
9.	Create a new group, for this example we will call **Group 1**, select a subgroup, **Sub-group1** and provide a description. Please aware to the additional metadata which can be used as well. The location of the policyMetadata object that has additional details about the control and compliance domain. Click **Save** to create the new group.
10.	Repeat the previous step to create additional group, for example: Group 2
11.	Now you should have two groups to help you organize your policies within the initiative.
12.	Click on the **Policies** tab. Here you can add policy definitions, both built-in and custom. Click Add policy definition(s). Select your desired polices, if you create a benchmark, you can also leverage existing policy definitions from **Microsoft managed** tab. For example, you can choose the following policies and select Add:
    -	Audit virtual machines without disaster recovery configured
    -	Audit VMs that do not use managed disks
13.	Each policy on the list, has its definition name, reference ID and the associated group. However, you do need to define a group for each policy. To do so, click on the **…** to open the context menu and select **Edit groups**.
14.	Make sure all policies are associated to a group. Please notice that policies can be associated to multiple groups.
15.	You can assign policy and initiative parameters to be used during the assignment process. Skip this section and click on Review + Create to validate your settings. Then, click on Create.
16.	You should now see your new initiative listed – **Custom Benchmark** along with the additional metadata (scope, category, etc.)
![Regulatory compliance assessment and standards](../Images/lab4rc5.gif?raw=true)
17.	To assign your new security policy, open **Microsoft Defender for Cloud blade**.
18.	From the left navigation pane, under Management section, click on **Security policy**.
19.	Select a **desired scope** to assign your new security policy (it could be either Management Group or Subscription).
20.	On **Security policy** page, hover to Your custom initiatives and select **Add a custom initiative**. 
21.	On **Add custom initiative**, your new standard should be listed there, so you can click on **Add** to assign to it. Once assigned, it will be listed as a recommendation in the Recommendations blade and be added in the Regulatory Compliance dashboard.
22.	Follow the **on-screen instructions to assign it on the desired scope**. If you decided to include parameters in your initiative, now you should be able to fulfill them. Click **Review + create** to start the validation process and then **Create**.
23.	Now your new security benchmark is displayed in regulatory compliance along with the built-in regulatory standards.

### Exercise 4 Azure Audit Reports

Now in Microsoft Defender for Cloud, you can easily create & download Audit reports for Regulatory Compliance Standards.
1.	From Microsoft Defender for Cloud, select Regulatory Compliance from the sidebar
2.	Then click on Audit Reports found at the top of the page
![Regulatory compliance assessment and standards](../Images/lab4rc6.jpg?raw=true)
3.	Select PCI from the tabs, and download 2021 - Azure PCI 3DS 1.0 Package, and click download
![Regulatory compliance assessment and standards](../Images/lab4rc7.jpg?raw=true)
4.	Press download on the Privacy Notice pop-up that appears.
You now have the audit report downloaded.


### Exercise 5 Continuous Export & Compliance over time workbook

Compliance dashboard over time is a Workbook in Microsoft Defender for Cloud dedicated to tracking a subscription's compliance with the regulatory or industry standards applied to it.

You'll need to configure continuous export first to export data to a Log Analytics workspace:
1.	From Microsoft Defender for Cloud's sidebar, select **Environment Settings**.
2.	Select **Azure Subscription 1** for which you want to configure the data export.
3.	From the sidebar of the settings page for that subscription, select **Continuous Export**.
4.	Set the export target to **Log Analytics workspace** (which is the tab beside Event hub).
5.	Select the following data types: **Regulatory compliance**.
6.	From the export frequency options, select both **Streaming updates** and **Snapshots (Preview)**.
7.	Select target workspace and the Resource Group to be those you created earlier.
9.	Select Save.
10.	Wait for the first snapshot to occur. 

![Regulatory compliance assessment and standards](../Images/lab4rc8.jpg?raw=true)

![Regulatory compliance assessment and standards](../Images/lab4rc9.jpg?raw=true)

![Regulatory compliance assessment and standards](../Images/lab4rc10.jpg?raw=true)

Compliance dashboard over time 
1.	Go to Microsoft Defender for Cloud, and from the left navigation pane, under the General section, press on the Workbooks button. 
2.	Select the Compliance Over Time Workbook
3.	For the workspace, select **asclab-la-XXXXXXXXXX** 
4.	For the subscription, select **Subscription 1**
5.	For the standard name, select **All**, and now you can see the workbook.
![Regulatory compliance assessment and standards](../Images/lab4rc11.jpg?raw=true)
>Note 1: You need to complete the previous exercise of setting up Continuous Export to the Log Analytics workspace for the Compliance Over Time Workbook to work.
>Note 2: If you see the error below, you will need to wait for a week for this workbook to populate with data through Continuous Export.
![Regulatory compliance assessment and standards](../Images/lab4rc12.gif?raw=true)







### Continue with the next lab: [Module 5 - Improving your Secure Posture](../Modules/Module-5-Improving-your-Secure-Posture.md)
