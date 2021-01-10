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
6.	On the Exported data types, select **Security recommendations, Secure score (Preview) and Security alerts** – as you can see, all recommendations, severities, controls, and alerts are selected.
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
2.	On the Azure Sentinel workspaces, click on **Connect** workspace button – for this exercise we’ll use the same Log Analytics workspace used by Security Center.
3.	On the **Add Azure Sentinel** to a workspace, select **asclab-la-xxx** workspace. Click **Add**.
4.	Adding Azure Sentinel to workspace asclab-la-xxx is now in progress. The process will few minutes. 
5.	Once Sentinel News and guides opens, use the Azure Security Center connector to enable the integration.
6.	From Sentinel’s sidebar, click on the **Data connectors**.
7.	On the Data connectors page, use the search field and type: *Security Center*.
8.	Select the **Azure Security Center** connector and then click on **Open connector page**.

![ASC pricing & settings page](../Images/asc-sentinel-data-connectors.gif?raw=true)

9.	On the Configuration section, locate the **Azure subscription 1** and change the toggle button to **Connect**. Wait for the connection status to be: `Connected`.

![Connect Azure Security Center to Azure Sentinel](../Images/asc-sentinel-data-connector-page.gif?raw=true)

10.	On the Create incidents (recommended) click on the **Enable** button to create incidents automatically from all alerts generated in this connected service.

![Enable incidents](../Images/asc-sentinel-enable-incidents.gif?raw=true)

### Continue with the next lab: [Module 8 – Advance Cloud Defense](Module-8-Advance-Cloud-Defense.md)