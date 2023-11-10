# Module 22 – Integration with Microsoft Defender for Endpoint

<p align="left"><img src="../Images/asc-labs-advanced.gif?raw=true"></p>

#### 🎓 Level: 300 (Advanced)
#### ⌛ Estimated time to complete this lab: 20 minutes

## Objectives
Microsoft Defender for Endpoint integration is one of the main capabilities in both plans of Microsoft Defender for Servers. In this module, you will learn how to enable the integration.

### Exercise 1: Enable auto-deployment of and integration with Microsoft Defender for Endpoint

[Defender for Servers Plan 1 and Plan 2](https://learn.microsoft.com/en-gb/azure/defender-for-cloud/plan-defender-for-servers-select-plan) include integration and license coverage for [Microsoft Defender for Endpoint](https://www.microsoft.com/microsoft-365/security/endpoint-defender). Together, they provide comprehensive endpoint detection and response (EDR) capabilities, software inventory, and vulnerability assessments leveraging [Microsoft Defender Vulnerability Management](https://learn.microsoft.com/en-gb/azure/defender-for-cloud/deploy-vulnerability-assessment-defender-vulnerability-management).
As soon as Defender for Endpoint detects a threat, it triggers a security alert that is shown in both, Microsoft Defender for Cloud and Microsoft 365 Defender. From Microsoft Defender for Cloud, you can also pivot to the Defender for Endpoint console, and perform a detailed investigation to uncover the scope of the attack.

Integration with Microsoft Defender for Endpoint and Microsoft Defender Vulnerability Management is enabled by default once you enable one of the two Defender for Servers plans. To control the current configuration, you can

1.  Navigate to **Microsoft Defender for Cloud**, then **Environment settings**.
2.  Select the relevant subscription.
3.  Locate **Servers**.
4.	Click on **Settings** and ensure **Endpoint protection** and **Vulnerability assessment for machines** are toggled **On**.
5.  Click **Continue** and **Save**. 

As soon as you have enabled the integration with Microsoft Defender for Endpoint, Microsoft Defender for Cloud will automatically deploy the MDE.Windows and MDE.Linux extensions to your Windows and Linux Azure VMs and non-Azure machines running Azure Arc-enabled Servers. As soon as the extension is deployed, an onboarding package will analyze the machine and
- ignore any Linux machines that are running other fanotify-based security solutions (see details of the fanotify kernel extension required in [Linux system requirements](https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/microsoft-defender-endpoint-linux#system-requirements))
- detect any previous installations of Defender for Endpoint and reconfigure them to integrate with Microsoft Defender for Cloud.

Onboarding of the MDE agent will start within an hour. However, it can take up to 12 hours before vulnerability assessment results are shown in the **Machines should have vulnerability findings resolved** recommendation. The onboarding is completed as soon as the extension has been installed and is in **Provisioning succeeded** state.

![](../Images/m22-mdeextension.png?raw=true)

### Exercise 2: Connect your on-premises servers via direct onboarding
While the onboarding scenario in exercise 1 will require Azure Arc to be installed first so Defender for Cloud's backend process can deploy Microsoft Defender for Endpoint to your non-Azure machines, there is another capability called direct onboarding that allows Defender for Cloud to detect any server in Defender for Endpoint's backend and connect it to Defender for Cloud using a backend integration between both services, offering integration and license coverage.

To enable direct onboarding, follow these steps:
1. Navigate to **Microsoft Defender for Cloud**, then **Environment settings**.
2. Click the **Direct onboarding** tile
   ![](../Images/m22-directonboarding.png?raw=true)
3. Toggle **Direct onboarding** on and select a **Designated subscription**.
   ![](../Images/m22-directonboarding2.png?raw=true)
4. Click **Save**.

In case Defender for Servers has not already been enabled on the designated subscription before enabling direct onboarding, Defender for Cloud will automatically enable Defender for Servers Plan 1 on this subscription. As a next step, Defender for Cloud will now detect all servers in your [Defender for Endpoint backend](https://security.microsoft.com) and connect them to Defender for Cloud. In order to manually deploy Defender for Endpoint to your server, please follow these steps:
1. Login to [Microsoft 365 Defender portal](https://security.microsoft.com).
2. Navigate to **Settings**, then **Endpoints**.
3. Under **Device management**, find **Onboarding**.
4. Select your server's operating system and follow the installation instructions.

As soon as your machine is successfully onboarded to Microsoft Defender for Endpoint, it will be connected to Defender for Cloud. Security alerts, Software inventory and vulnerability assessment findings will now be available in Defender for Cloud and Microsoft 365 Defender.

### Exercise 3: Analyze vulnerability assessment findings in custom workbooks
As soon as Microsoft Defender Vulnerability Management (MDVM) will report vulnerability assessment results for your machine, Defender for Cloud will show them in the **Machines should have vulnerability findings resolved** security recommendation. At the same time, these results will also be available via Azure Resource Graph (ARG), where you can query them using Kusto Query Language (KQL). We have released a custom [CVE Dashboard](https://aka.ms/CVEDashboard) that you can deploy from this Github repository by following the link and clicking on **Deploy to Azure**.

The workbook will show vulnerability assessment results based on CVE IDs, including information about affected machines and software. You can also filter by using the plain text search bar on top of every table.

![](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Workbooks/CVE%20Dashboard/tab1.png)