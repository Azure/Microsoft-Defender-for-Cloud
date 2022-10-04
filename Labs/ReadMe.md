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
- [Download vulnerable image from Docker Hub into the Container Registry]([Download vulnerable image from Docker Hub into the Container Registry](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module-9-Defender-For-Containers.md#exercise-2-download-vulnerable-image-from-docker-hub-into-the-container-registry))
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
