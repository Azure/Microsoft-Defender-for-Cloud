
# Automatically onboard Windows Server 2019 and Linux from Azure Security Center to Microsoft Defender for Endpoint

Azure Defender for Servers offers an integration with Microsoft Defender for Endpoints, that allows you to onboard servers automatically from Azure Security Center without manual interaction. However, currently, there is no automated onboarding for Windows Server 2019 and Linux servers.
This solution helps you to find these servers to get visibility and to run an automation that will onboard these servers to Microsoft Defender for Endpoints.

### Release notes

* Version 2 - Supports both Azure VM and Azure Arc machines based on Linux either Ubuntu or Debian distributions.
* Version 1 – Supports both Azure VM and Azure Arc machines based on Windows Server 2019 operating systems.

## What is it?
Using a custom policy initiative, Azure Security Center will determine if a machine is connected to an Azure Defender for Servers-enabled subscription and if it has the Microsoft Defender for Endpoints package installed. If it has not been installed, this server will be marked as unhealthy. From the recommendation, you can then select these machines and trigger the automation that will onboard these machines to Microsoft Defender for Endpoints.

## Prerequisites
1. Microsoft Defender for Endpoints enrollment. This can automatically be created once you enable the Azure Security Center integration, as explained in the [ASC documentation](https://docs.microsoft.com/en-us/azure//security-center/security-center-wdatp#enabling-the-microsoft-defender-for-endpoint-integration).

## How it works

1. Built-in policy initiative ensure that Guest Config policy is deployed on VMs - [Preview]: Deploy prerequisites to enable Guest Configuration policies on virtual machines.
2.	Custom recommendation on ASC identifies Windows Server 2019 and Linux machines that do not have MDE configured yet.
3.	Logic App automation to be trigger manually or automatically (using workflow automation) on the unhealthy resources.
4.	A custom script extension (both Azure VM and Azure Arc machine) to pull the script from the storage account and onboard unhealthy resources.

> Please note! the solution won’t work if there is already custom script extension deployed on a VM.

## Installation instructions

### Identify potential machines using Azure Policy

1. On the Azure portal, navigate to **Azure Policy** blade or [click here](https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyMenuBlade).
2. Assign the *[Preview]: Deploy prerequisites to enable Guest Configuration policies on virtual machines* initiative – this step is necessary to deploy the guest configuration extension on virtual machines (both Linux and Windows).

<a href="https://portal.azure.com/?#blade/Microsoft_Azure_Policy/CreatePolicyDefinitionBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FConfigure-MDE%2FSource%2FAuditIfNotExists.json" target="_blank"><img src="https://aka.ms/deploytoazurebutton"/></a>

   * On the **Definition location** select either subscription or a management group. Click **Save**.

1.  From Security Center's sidebar, select **Security policy**.
2.  Select a **desired scope** for policy initiative (either subscription or management group).
3.  At the your custom initiatives section at the bottom, click **Add a custom initiative**.
On the **Add custom initiatives​** click on **Create new**. Provide the following details:

    * Name: MDE Onboarding
    * Category: Security Center
    * On the available definitions, click the **+ Audit Windows Server 2019 machines that don't have Microsoft Defender for Endpoint configured** and **+ Audit Linux machines that don't have Microsoft Defender for Endpoint configured**.
    * If you want to include Azure Arc machine, set the value as **True**
    * Click **Save**
    * `MDE Onboarding` now appears on the page. Click **Add**.
    * * Click **Review + Create**.
    * * Click **Create**.
    * `MDE Onboarding` is now assigned into Securtiy Center. Wait few hours until the new custom recommendation appears on the ASC recommendations list.

### Automate remediation using Logic App

1. Deploy the Logic app automation and a storage account with private blob container:
   
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkflow%2520automation%2FConfigure-MDE%2FSource%2Fazuredeploy.json" target="_blank"><img src="https://aka.ms/deploytoazurebutton"/></a>

   * Provide a name for the storage account.

![](./Images/mde-resources-deployment.gif?raw=true)

1. Authorize the **ARM-Configure-MDE** Logic App connection:

   * From the Logic App’s sidebar, select **API connections**.
   * Select *ARM-Configure-MDE* connection.
   * From the sidebar, select Edit API connection.
   * Select **Authorize** and authenticate using your credentials.
   * Select **Save** to apply your changes.

3.	On Azure Defender for Servers-enabled subscription, navigate to **Microsoft Defender Security Center** [onboarding page](https://securitycenter.microsoft.com/preferences2/onboarding)
4.	From the dropdown menu (operating system to start onboarding process), select **Windows Server 1803 and 2019**.
5.	On the **Deployment method** dropdown menu, select **Group Policy** and then click on the **Download package**.
6.	Extract the `WindowsDefenderATPOnboardingPackage.zip` package to get the `WindowsDefenderATPOnboardingScript.cmd` file - this file is unique per organization.
7. From the dropdown menu (operating system to start onboarding process), select **Linux Server**.
8. Verify that *local script* is selected as the deployment method and then click on **download onboarding package**.
9. Extract the `WindowsDefenderATPOnboardingPackage.zip` package to get the `MicrosoftDefenderATPOnboardingLinuxServer.py` file - this file is unique per organization.
10. Download `ConfigureDefender.zip` and extract it.
11. Upload 4 files (`WindowsDefenderATPOnboardingScript.cmd`, `MicrosoftDefenderATPOnboardingLinuxServer.py`, `ConfigureDefender.ps1` and `ConfigureDefender.sh`) to the `scripts` private blob container (storage account)

![](./Images/mde-storage-scripts.gif?raw=true)

### Remediate unhealthy resources

Once the Azure Policy evaluation completed, you should see two new custom recommendation for both Windows Server 2019 and Linux as follow: 

![](./Images/mde-custom-recommendations.gif?raw=true)

Within each recommendation, you should get all healthy and unhealthy resources. To remediate unhealthy resources, select items from the list and click **Trigger logic app**. Select the **Configure-MDE**.

> Please note! you can also use the workflow automation capability to automatically trigger the logic app once a new unhealthy machine appears on the *Audit Windows Server 2019 machines that don't have Microsoft Defender for Endpoint configured* recommendation.

![](./Images/mde-manual-remediation-linux.gif?raw=true)