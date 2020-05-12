
# Azure Security Center Simulation Playbook

There are many ways to simulate an alert in Azure Security Center and if you just want a simple validation to get an alert, use the procedures described in [this article](https://docs.microsoft.com/en-us/azure/security-center/security-center-alert-validation). For a more scenario-based approach, you have the resources below that you can use to validate different threat detections capabilities available in Azure Security Center.

## Alert Simulation for Windows (Azure and Non-Azure VMs)

- Download this [PDF](https://gallery.technet.microsoft.com/Azure-Security-Center-f621a046) from TechNet Gallery and follow the steps to configure a lab environment to test Windows VM-based threat detection.

- [Threat Detection for Windows documentation](https://docs.microsoft.com/en-us/azure/security-center/security-center-alerts-iaas#windows-)

- [Potential alerts for Windows documentation](https://docs.microsoft.com/en-us/azure/security-center/alerts-reference#alerts-windows)

If you are testing the integration with Microsoft Defender ATP for Servers, use [this article](https://docs.microsoft.com/en-us/azure/security-center/security-center-wdatp#test-the-feature) to validate the alert integration. Make sure that the server that you are testing this procedure is already onboarded and using MDATP.

## Alert Simulation for Linux (Azure and Non-Azure VMs)

- Download this [PDF](https://gallery.technet.microsoft.com/Azure-Security-Center-0ac8a5ef) from TechNet Gallery and follow the steps to configure a lab environment to test Linux VM-based threat detection.

- [Threat Detection for Linux documentation](https://docs.microsoft.com/en-us/azure/security-center/security-center-alerts-iaas#linux-)

- [Potential alerts for Linux documentation](https://docs.microsoft.com/en-us/azure/security-center/alerts-reference#alerts-linux)


## Alert Simulation for Containers

- [This article](https://techcommunity.microsoft.com/t5/azure-security-center/how-to-demonstrate-the-new-containers-features-in-azure-security/ba-p/1011270) go over the steps to simulate alerts in Azure Kubernetes Services and Azure Container Registry.

- [Threat detection for containers documentation](https://docs.microsoft.com/en-us/azure/security-center/security-center-alerts-compute#azure-containers-)


## Alert Simulation for Advanced Threat Protection for Azure Storage

- [This article](https://techcommunity.microsoft.com/t5/azure-security-center/validating-atp-for-azure-storage-detections-in-azure-security/ba-p/1068131) go over the steps to simulate an upload of a test malware (EICAR) to an Azure Storage account that has ATP for Azure Storage enabled.

- [Threat detection for Azure Storage](https://docs.microsoft.com/en-us/azure/security-center/security-center-alerts-data-services#azure-storage-)

## Alert Simulation for Key Vault Threat Protection
- [This article](https://techcommunity.microsoft.com/t5/azure-security-center/validating-azure-key-vault-threat-detection-in-azure-security/ba-p/1220336) go over the steps to simulate an anonymizer access to the Key Vault using a TOR browser.

- [Threat detection for Key Vault](https://docs.microsoft.com/en-us/azure/security-center/threat-protection#threat-protection-for-azure-key-vault-preview)

## Threat Hunting in Azure Security Center and Log Analytics Workspace

- This simulation playbook go over a threat hunting scenario using Azure Security Center and searching for evidences of attack in Log Analtyics workspace.

- Download [this PDF](https://gallery.technet.microsoft.com/Azure-Security-Center-549aa7a4) from TechNet Gallery and follow the steps to configure a lab environment, simulate alerts in Windows and query data using KQL in Log Analytics workspace.
