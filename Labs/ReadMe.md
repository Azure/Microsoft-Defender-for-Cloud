# Welcome to Microsoft Defender for Cloud Labs!

<p align="center">
<img src="./Images/asc-labs-logo.png?raw=true">
</p>

## Introduction
Our labs project help you get ramped up with Microsoft Defender for Cloud and provide hands-on practical experience for product features, capabilities, and scenarios. The labs are divided into 3 main tracks, a beginner (level 100/200) and an advanced (level 300+) track. The labs contain several modules cover different pillars such as Cloud Security Posture Management (CSPM) to Cloud Workload Protection  (CWP). To start using our labs, you will need to create Azure Trial Subscription which provides you all capabilities for 30 days – so you have to finish this lab at this point to take advantage of the free trial. We continually update the content to include the latest capabilities – please feel free to [submit issue](https://github.com/Azure/Azure-Security-Center/issues/new/choose) for any changes and suggestions.

<p align="center">
<img src="./Images/asc-labs-levels.png?raw=true">
</p>

Skill | Level | Description
----- | ----- | -----------
Beginner | 100 | You're starting out and want to learn the fundamentals of Microsoft Defender for Cloud
Intermediate | 200 | You have some experience with the product but want to learn more in-depth
Advanced | 300+ | You have lots of experience and are looking to learn about advanced capabilities

## Last release notes

* Version 1.0 - General availability of Microsoft Defender for Cloud labs
* Version 2.0 - General availability of Microsoft Defender for Cloud labs version 2 (November 2021)

## Modules

[**Module 1 – Preparing the Environment (L100)**](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module-1-Preparing-the-Environment.md)
- [Creating an Azure Trial Subscription](./Modules/Module-1-Preparing-the-Environment.md#exercise-1-creating-an-azure-trial-subscription)
- [Provisioning resources (automation)](./Modules/Module-1-Preparing-the-Environment.md#exercise-2-provisioning-resources)
- [Enabling Microsoft Defender for Cloud](./Modules/Module-1-Preparing-the-Environment.md#exercise-3-enabling-azure-defender)
 
[**Module 2 – Exploring Microsoft Defender for Cloud (L100)**](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module-2-Exploring-Azure-Security-Center.md)
- [Understanding Microsoft Defender for Cloud dashboard](./Modules/Module-2-Exploring-Azure-Security-Center.md#exercise-1-understanding-azure-security-center-dashboard)
- [Exploring Secure Score and Recommendations](./Modules/Module-2-Exploring-Azure-Security-Center.md#exercise-2-exploring-secure-score-and-recommendations)
- [Exploring the Inventory capability](./Modules/Module-2-Exploring-Azure-Security-Center.md#exercise-3-exploring-the-inventory-capability)
 
[**Module 3 – Security Policy (L200)**](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module-3-ASC-Security-Policy.md)
- [Overview of the security policy](./Modules/Module-3-ASC-Security-Policy.md#exercise-1-overview-of-the-asc-policy)
- [Explore Azure Policy](./Modules/Module-3-ASC-Security-Policy.md#exercise-2-explore-azure-policy)
- [Create resource exemption for a recommendation](./Modules/Module-3-ASC-Security-Policy.md#exercise-3-create-resource-exemption-for-a-recommendation)
- [Create a policy enforcement and deny](./Modules/Module-3-ASC-Security-Policy.md#exercise-4-create-a-policy-enforcement-and-deny)
- [Create a custom policy](./Modules/Module-3-ASC-Security-Policy.md#exercise-5-create-a-custom-policy)

[**Module 4 – Regulatory Compliance (L200)**](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module-4-Regulatory-Compliance.md)
- [Understanding Regulatory Compliance dashboard](./Modules/Module-4-Regulatory-Compliance.md#exercise-1-understanding-regulatory-compliance-dashboard)
- [Adding new standards](./Modules/Module-4-Regulatory-Compliance.md#exercise-2-adding-new-standards)
- [Creating your own benchmark](./Modules/Module-4-Regulatory-Compliance.md#exercise-3-creating-your-own-benchmark)
 
[**Module 5 – Improving your Secure Posture (L300)**](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module-5-Improving-your-Secure-Posture.md)
- [Vulnerability assessment for VMs](./Modules/Module-5-Improving-your-Secure-Posture.md#exercise-1-vulnerability-assessment-for-vms)
- [Vulnerability assessment for Containers](./Modules/Module-5-Improving-your-Secure-Posture.md#exercise-2-vulnerability-assessment-for-containers)
- [Automate recommendations with workflow automation](./Modules/Module-5-Improving-your-Secure-Posture.md#exercise-3-automate-recommendations-with-workflow-automation)
- [Accessing your secure score via ARG](./Modules/Module-5-Improving-your-Secure-Posture.md#exercise-4-accessing-your-secure-score-via-arg)
- [Creating Governance Rules and Assigning Owners](./Modules/Module-5-Improving-your-Secure-Posture.md#exercise-4-accessing-your-secure-score-via-arg)
 
[**Module 6 – Microsoft Defender Plans (L300)**](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module-6-Azure-Defender.md)
- [Alert validation](./Modules/Module-6-Azure-Defender.md#exercise-1-alert-validation)
- [Alert suppression](./Modules/Module-6-Azure-Defender.md#exercise-2-alert-suppression)
- [Accessing Security Alerts using Graph Security API](./Modules/Module-6-Azure-Defender.md#exercise-3-accessing-security-alerts-using-graph-security-api)

[**Module 7 – Exporting Microsoft Defender for Cloud information to a SIEM (L200)**](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module-7-Exporting-ASC-information-to-a-SIEM.md)
- [Using continuous export](./Modules/Module-7-Exporting-ASC-information-to-a-SIEM.md#exercise-1-using-continuous-export)
- [Integration with Microsoft Sentinel](./Modules/Module-7-Exporting-ASC-information-to-a-SIEM.md#exercise-2-integration-with-azure-sentinel)

[**Module 8 – Enhanced Security (L300)**](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module-8-Advance-Cloud-Defense.md)
- [Using JIT to reduce attack surface](./Modules/Module-8-Advance-Cloud-Defense.md#exercise-1-using-jit-to-reduce-attack-surface)
- [Adaptive Application Control](./Modules/Module-8-Advance-Cloud-Defense.md#exercise-2-adaptive-application-control)
- [File Integrity Monitoring](./Modules/Module-8-Advance-Cloud-Defense.md#exercise-3-file-integrity-monitoring)

[**Module 9 – Defender for Containers (L300)**](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module-9-Defender-For-Containers.md)
- [Install Docker Desktop](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module-1-Preparing-the-Environment.md)
- [Download vulnerable image from Docker Hub into the Container Registry](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module-9-Defender-For-Containers.md#exercise-2-download-vulnerable-image-from-docker-hub-into-the-container-registry)
- [Investigate the recommendation for vulnerabilities in ACR](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module-9-Defender-For-Containers.md#exercise-3-investigate-the-recommendation-for-vulnerabilities-in-acr)

[**Module 10 – GCP (L300)**](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module-10-GCP.md)
- [Create a GCP project](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module-10-GCP.md#exercise-1-create-a-gcp-project)
- [Create the GCP connector in Microsoft Defender for Cloud](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module-10-GCP.md#exercise-2-create-the-gcp-connector-in-microsoft-defender-for-cloud)
- [Investigate the GCP recommendations](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module-10-GCP.md#exercise-3-investigate-the-gcp-recommendations)

[**Module 11 – AWS (L300)**](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module-11-AWS.md)
- [Create an AWS account](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module-11-AWS.md#exercise-1-create-an-aws-account)
- [Create an AWS connector for the new AWS account in Microsoft Defender for Cloud](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module-11-AWS.md#exercise-2-create-an-aws-connector-for-the-new-aws-account-in-microsoft-defender-for-cloud)

[**Module 12 – Defender for Azure Cosmos DB (L300)**](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module-12-Defender-for-Azure-Comos-DB.md)
- [Enable database protection on your subscription](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module-12-Defender-for-Azure-Comos-DB.md#exercise-1-enable-database-protection-on-your-subscription)
- [Create an Azure Cosmos DB account and protect it using Microsoft Defender for Azure Cosmos DB](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module-12-Defender-for-Azure-Comos-DB.md#exercise-2-create-an-azure-cosmos-db-account-and-protect-it-using-microsoft-defender-for-azure-cosmos-db)

[**Module 13 – Governance (L300)**](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module-13-Governance.md)
- [Add a new Governance Rule in Microsoft Defender for Cloud](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module-13-Governance.md#exercise-1-add-a-new-governance-rule-in-microsoft-defender-for-cloud)
- [See recommendations that you're the owner of](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module-13-Governance.md#exercise-2-see-recommendations-that-youre-the-owner-of)

[**Module 14 – Configuring Azure ADO Connector in Defender for DevOps (L200)**](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module%2014-Config%20Azure%20ADO%20in%20DfD.md)
- [Preparing the environment](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module%2014-Config%20Azure%20ADO%20in%20DfD.md#exercise-1-preparing-the-environment)
- [Creating an Azure ADO Trial Subscription](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module%2014-Config%20Azure%20ADO%20in%20DfD.md#exercise-2-creating-an-azure-ado-trial-subscription)
- [Configuring Azure ADO Connector](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module%2014-Config%20Azure%20ADO%20in%20DfD.md#exercise-3-configuring-azure-ado-connector)
- [Configure the Microsoft Security DevOps Azure DevOps Extension](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module%2014-Config%20Azure%20ADO%20in%20DfD.md#exercise-4-configure-the-microsoft-security-devops-azure-devops-extension)
- [Install Free extension SARIF SAST Scans Tab](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module%2014-Config%20Azure%20ADO%20in%20DfD.md#exercise-5-install-free-extension-sarif-sast-scans-tab)
- [Configure your pipeline using YAML](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module%2014-Config%20Azure%20ADO%20in%20DfD.md#exercise-6-configure-your-pipeline-using-yaml)

[**Module 15 – Integrating Defender for DevOps with GitHub Advanced Security (L200)**](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module%2015%20-%20Integrating%20Defender%20for%20DevOps%20with%20GitHub%20Advanced%20Security.md)
- [Preparing the environment](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module%2015%20-%20Integrating%20Defender%20for%20DevOps%20with%20GitHub%20Advanced%20Security.md#exercise-1-preparing-the-environment)
- [Creating an GitHub Trial account](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module%2015%20-%20Integrating%20Defender%20for%20DevOps%20with%20GitHub%20Advanced%20Security.md#exercise-2-creating-an-github-trial-account)
- [Obtain trial of GitHub Enterprise Cloud account](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module%2015%20-%20Integrating%20Defender%20for%20DevOps%20with%20GitHub%20Advanced%20Security.md#exercise-3-obtain-trial-of-github-enterprise-cloud-account)
- [Connecting your GitHub organization](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module%2015%20-%20Integrating%20Defender%20for%20DevOps%20with%20GitHub%20Advanced%20Security.md#exercise-4-connecting-your-github-organization)
- [Configure the Microsoft Security DevOps GitHub action](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module%2015%20-%20Integrating%20Defender%20for%20DevOps%20with%20GitHub%20Advanced%20Security.md#exercise-5-configure-the-microsoft-security-devops-github-action)

[**Module 16 Module 16 - Protecting On-Prem Servers in Defender for Cloud (L300)**](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module%2016%20-%20Protecting%20On-Prem%20Servers%20in%20Defender%20for%20Cloud.md)
- [Install Hyper-V which will be used to create the server on your own machine](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module%2016%20-%20Protecting%20On-Prem%20Servers%20in%20Defender%20for%20Cloud.md#exercise-1-install-hyper-v-which-will-be-used-to-create-the-server-on-your-own-machine)
- [Using Hyper-V, confirm that there's a virtual switch already installed on your desktop](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module%2016%20-%20Protecting%20On-Prem%20Servers%20in%20Defender%20for%20Cloud.md#exercise-2-using-hyper-v-confirm-that-theres-a-virtual-switch-already-installed-on-your-desktop)
- [Using Hyper-V, create a VM (virtual machine) which will act as the virtual on-premises server that you will be protecting via Defender for DevOps](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module%2016%20-%20Protecting%20On-Prem%20Servers%20in%20Defender%20for%20Cloud.md#exercise-3-using-hyper-v-create-a-vm-virtual-machine-which-will-act-as-the-virtual-on-premises-server-that-you-will-be-protecting-via-defender-for-devops)
- [Install the operating system in your VM](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module%2016%20-%20Protecting%20On-Prem%20Servers%20in%20Defender%20for%20Cloud.md#exercise-4-install-the-operating-system-in-your-vm)
- [Setup the Azure Arc Rresource provider](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module%2016%20-%20Protecting%20On-Prem%20Servers%20in%20Defender%20for%20Cloud.md#exercise-5-setup-the-azure-arc-rp)
- [Connect to your VM](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module%2016%20-%20Protecting%20On-Prem%20Servers%20in%20Defender%20for%20Cloud.md#exercise-6-connect-to-your-vm)
- [Install Azure Arc on the VM so the VM will be protected by Micrsosoft Defender for Cloud](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module%2016%20-%20Protecting%20On-Prem%20Servers%20in%20Defender%20for%20Cloud.md#exercise-7-install-azure-arc-on-the-vm-so-the-vm-will-be-protected-by-micrsosoft-defender-for-cloud)
- [Confirm that the "on-prem" server we created is being detected by the Azure portal](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module%2016%20-%20Protecting%20On-Prem%20Servers%20in%20Defender%20for%20Cloud.md#exercise-8-confirm-that-the-on-prem-server-we-created-is-being-detected-by-the-azure-portal)


[**Begin the labs here >**](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module-1-Preparing-the-Environment.md)

## Acronyms

Acronym | Meaning | Description
------- | --- | -----------
MDFC | Microsoft Defender for Cloud | Built-in free service which offer limited security for your Azure resources only
CSPM | Cloud Security Posture Management | Automates the identification and remediation of risks across cloud infrastructures. CSPM in Microsoft Defender for Cloud is available for free to all Azure users. The free experience includes CSPM features such as secure score, detection of security misconfigurations in your Azure machines, asset inventory, and more.
CWP | Cloud Workload Protection | Provides workload-centric security protection solutions such as servers, app service, storage, database and more. All CWP capabilities are covered under Microsoft Defender for Cloud.
JIT | Just-in-time | Feature to reduce exposure to attacks while providing easy access when you need to connect to a VM
ARM | Azure Resource Manager | Deployment and management layer that enables you to create, update, and delete resources in your Azure account.
RBAC | Role-based access control | Authorization system built on Azure Resource Manager that provides fine-grained access management of Azure resources.
VA | Vulnerability Assessment | Provides vulnerability scanning for your virtual machines and container registries.
SIEM | Security information and event management | Tool to provide a central place to collect events and alerts, that aggregates data from multiple systems and analyze that data to catch abnormal behavior or potential cyberattacks. For example, Microsoft Sentinel.


[**Begin the labs here >**](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module-1-Preparing-the-Environment.md)
