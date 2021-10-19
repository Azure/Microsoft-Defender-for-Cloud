# Module 7 – Exporting ASC information to a SIEM

<p align="left"><img src="../Images/asc-labs-intermediate.gif?raw=true"></p>

#### 🎓 Level: 200 (Intermediate)
#### ⌛ Estimated time to complete this lab: 30 minutes

## Objectives
In this exercise, you will understand how to configure the continuous export for Log Analytics workspace, exporting security alerts, recommendations, secure score, and security findings. Moreover, you will learn how to enable the integration between Azure Security Center and Azure Sentinel.

### Exercise 1: Using continuous export

1.	On Security Center’s sidebar, click on **Pricing & settings**.
2.	Select **Azure subscription 1**.

![Pricing & settings page](../Images/asc-pricing-settings-sub.gif?raw=true)

3.	From the Azure Defender plans’ sidebar, click on **Continuous export**.
4.	Here you can configure streaming export setting of Security Center data to multiple export targets either Event Hub or Log Analytics workspace.
5.	Select the **Log Analytics workspace** option.
6.	On the Exported data types, select **Security recommendations, Secure score and Security alerts** – as you can see, all recommendations, severities, controls, and alerts are selected.
7.	On the Export configuration, select a resource group: *asclabs*
8.	On the Export target, select the target Log Analytics workspace: *asclab-la-xxx*
9.	Click on the **Save** button on the top menu.

![Continuous export settings page](../Images/asc-continuous-export-settings.gif?raw=true)

> Note: Exporting Security Center's data also enables you to use experiences such as integration with 3rd-party SIEM and Azure Data Explorer.

10.	On the Azure portal, navigate to **Log Analytics workspaces** service or [click here](https://portal.azure.com/#blade/HubsExtension/BrowseResource/resourceType/Microsoft.OperationalInsights%2Fworkspaces).
11.	Click on the **asclab-la-xxx** workspace.
12.	From the workspace’s sidebar, click on the **Logs** button.
13.	On the welcome page, click on the **Get Started** button and then **close the Queries window**.
14.	From the left pane, notice the following tables: `SecureScores`, `SecureScoreControls`, `SecurityAlert`, `SecurityRecommendation` and `SecurityNestedRecommendation`.
15.	Query the tables later on to validate data streaming - double click on the desired table to open a new query. Then click **Run**.

![Respective tables in the Log Analytics workspace](../Images/asc-continuous-export-tables.gif?raw=true)

### Exercise 2: Integration with Azure Sentinel

1.	On the Azure portal, navigate to **Azure Sentinel** service or [click here](https://portal.azure.com/#blade/Microsoft_Azure_Security_Insights/WorkspaceSelectorBlade).
2.	On the Azure Sentinel workspaces, click on **+ Create** workspace button – for this exercise we’ll use the same Log Analytics workspace used by Security Center.

![](../Images/lab7sent.gif?raw=true)

3.	On the **Add Azure Sentinel** to a workspace, select **asclab-la-xxx** workspace. Click **New** on the top bar, or click **Create Azure Sentinel**. 
4.	Adding Azure Sentinel to workspace asclab-la-xxx is now in progress. The process will few minutes. 
5.	Once Sentinel News and guides opens, use the Azure Security Center connector to enable the integration.
6.	From Sentinel’s sidebar, click on the **Data connectors**.
7.	On the Data connectors page, use the search field and type: *Azure Defender*.
8.	Select the **Azure Defender** connector and then click on **Open connector page**.

![ASC pricing & settings page](../Images/asc-sentinel-data-connectors.gif?raw=true)

9.	On the Configuration section, locate the **Azure subscription 1** and change the toggle button to **Connect**. Wait for the connection status to be: `Connected`.

![Connect Azure Security Center to Azure Sentinel](../Images/asc-sentinel-data-connector-page.gif?raw=true)

> **Note on ASC & Sentinel bi-directional alerts:**
When you connect Azure Defender to Azure Sentinel, the status of Azure Defender alerts that get ingested into Azure Sentinel is synchronized between the two services. So, for example, when an alert is closed in Azure Defender, that alert will display as closed in Azure Sentinel as well. Changing the status of an alert in Azure Defender "won't"* affect the status of any Azure Sentinel incidents that contain the synchronized Azure Sentinel alert, only that of the synchronized alert itself.<br/>
Enabling this preview feature, bi-directional alert synchronization, will automatically sync the status of the original Azure Defender alerts with Azure Sentinel incidents that contain the copies of those Azure Defender alerts. So, for example, when an Azure Sentinel incident containing an Azure Defender alert is closed, Azure Defender will automatically close the corresponding original alert.

### Exercise 3: Security Center can now auto provision the Azure Policy's Guest Configuration extension (in preview)
Azure Policy can audit settings inside a machine, both for machines running in Azure and Arc connected machines. The validation is performed by the Guest Configuration extension and client. Learn more in [Understand Azure Policy's Guest Configuration](https://docs.microsoft.com/en-gb/azure/governance/policy/concepts/guest-configuration).
With this update you can now set Security Center to automatically provision this extension to all supported machines.
1.	In Azure Security Center, click on **Pricing & Settings**.
2.	Then select **Auto provisioning** from the sidebar.
3.	Here, for **Guest Configuration agent**, toggle the status to be **On**.
4.	Then click **Save**.

![](../Images/lab7autop.gif?raw=true)




### Continue with the next lab: [Module 8 – Advance Cloud Defense](Module-8-Advance-Cloud-Defense.md)
