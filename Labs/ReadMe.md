# Welcome to Azure Security Center Labs

<p align="center">
<img src="./Images/asc-labs-logo.png?raw=true">
</p>

## Introduction
Our labs project help you get ramped up with Azure Security Center and provide hands-on practical experience for product features, capabilities, and scenarios. The labs are divided into 3 main tracks, a beginner (level 100/200) and an advanced (level 300+) track. The labs contain several modules cover different pillars such as Cloud Security Posture Management (CSPM) to Cloud Workload Protection  (CWP). To start using our labs, you will need to create Azure Trial Subscription which provides you all capabilities for 30 days – so you have to finish this lab at this point to take advantage of the free trial. We continually update the content to include the latest capabilities – please feel free to [submit issue](https://github.com/Azure/Azure-Security-Center/issues/new/choose) for any changes and suggestions.

<p align="center">
<img src="./Images/asc-labs-levels.png?raw=true">
</p>

Skill | Level | Description
----- | ----- | -----------
Beginner | 100 | You're starting out and want to learn the fundamentals of Azure Security Center
Intermediate | 200 | You have some experience with the product but want to learn more in-depth
Advanced | 300+ | You have lots of experience and are looking to learn about advanced capabilities

## Last release notes

* Version 1.0 - General availability of Azure Security Center labs

## Modules

[**Module 1 – Preparing the Environment (L100)**](./Modules/Module-1-Preparing-the-Environment.md)
- [Creating an Azure Trial Subscription](./Modules/Module-1-Preparing-the-Environment.md#exercise-1-creating-an-azure-trial-subscription)
- [Provisioning resources (automation)](./Modules/Module-1-Preparing-the-Environment.md#exercise-2-provisioning-resources)
- [Enabling Azure Defender](./Modules/Module-1-Preparing-the-Environment.md#exercise-3-enabling-azure-defender)
 
[**Module 2 – Exploring Azure Security Center (L100)**](./Modules/Module-2-Exploring-Azure-Security-Center.md)
- [Understanding ASC dashboard](./Modules/Module-2-Exploring-Azure-Security-Center.md#exercise-1-understanding-azure-security-center-dashboard)
- [Exploring Secure Score and Recommendations](./Modules/Module-2-Exploring-Azure-Security-Center.md#exercise-2-exploring-secure-score-and-recommendations)
- [Exploring the Inventory capability](./Modules/Module-2-Exploring-Azure-Security-Center.md#exercise-3-exploring-the-inventory-capability)
 
[**Module 3 – ASC Security Policy (L200)**](./Modules/Module-3-ASC-Security-Policy.md)
- [Overview of the ASC policy](./Modules/Module-3-ASC-Security-Policy.md#exercise-1-overview-of-the-asc-policy)
- [Explore Azure Policy](./Modules/Module-3-ASC-Security-Policy.md#exercise-2-explore-azure-policy)
- [Create resource exemption for a recommendation](./Modules/Module-3-ASC-Security-Policy.md#exercise-3-create-resource-exemption-for-a-recommendation)
- [Create a policy enforcement and deny](./Modules/Module-3-ASC-Security-Policy.md#exercise-4-create-a-policy-enforcement-and-deny)
- [Create a custom policy](./Modules/Module-3-ASC-Security-Policy.md#exercise-5-create-a-custom-policy)

[**Module 4 – Regulatory Compliance (L200)**](./Modules/Module-4-Regulatory-Compliance.md)
- [Understanding Regulatory Compliance dashboard](./Modules/Module-4-Regulatory-Compliance.md#exercise-1-understanding-regulatory-compliance-dashboard)
- [Adding new standards](./Modules/Module-4-Regulatory-Compliance.md#exercise-2-adding-new-standards)
- [Creating your own benchmark](./Modules/Module-4-Regulatory-Compliance.md#exercise-3-creating-your-own-benchmark)
 
[**Module 5 – Improving your Secure Posture (L300)**](./Modules/Module-5-Improving-your-Secure-Posture.md)
- [Vulnerability assessment for VMs](./Modules/Module-5-Improving-your-Secure-Posture.md#exercise-1-vulnerability-assessment-for-vms)
- [Vulnerability assessment for Containers](./Modules/Module-5-Improving-your-Secure-Posture.md#exercise-2-vulnerability-assessment-for-containers)
- [Automate recommendations with workflow automation](./Modules/Module-5-Improving-your-Secure-Posture.md#exercise-3-automate-recommendations-with-workflow-automation)
- [Accessing your secure score via ARG](./Modules/Module-5-Improving-your-Secure-Posture.md#exercise-4-accessing-your-secure-score-via-arg)
 
[**Module 6 – Azure Defender (L300)**](./Modules/Module-6-Azure-Defender.md)
- [Alert validation](./Modules/Module-6-Azure-Defender.md#exercise-1-alert-validation)
- [Alert suppression](./Modules/Module-6-Azure-Defender.md#exercise-2-alert-suppression)
- [Accessing Security Alerts using Graph Security API](./Modules/Module-6-Azure-Defender.md#exercise-3-accessing-security-alerts-using-graph-security-api)

[**Module 7 – Exporting ASC information to a SIEM (L200)**](./Modules/Module-7-Exporting-ASC-information-to-a-SIEM.md)
- [Using continuous export](./Modules/Module-7-Exporting-ASC-information-to-a-SIEM.md#exercise-1-using-continuous-export)
- [Integration with Azure Sentinel](./Modules/Module-7-Exporting-ASC-information-to-a-SIEM.md#exercise-2-integration-with-azure-sentinel)

[**Module 8 – Advance Cloud Defense (L300)**](./Modules/Module-8-Advance-Cloud-Defense.md)
- [Using JIT to reduce attack surface](./Modules/Module-8-Advance-Cloud-Defense.md#exercise-1-using-jit-to-reduce-attack-surface)
- [Adaptive Application Control](./Modules/Module-8-Advance-Cloud-Defense.md#exercise-2-adaptive-application-control)
- [File Integrity Monitoring](./Modules/Module-8-Advance-Cloud-Defense.md#exercise-3-file-integrity-monitoring)

## Acronyms

Acronym | Meaning | Description
------- | --- | -----------
ASC | Azure Security Center | Built-in free service which offer limited security for your Azure resources only
CSPM | Cloud Security Posture Management | Automates the identification and remediation of risks across cloud infrastructures. CSPM is Security Center is available for free to all Azure users. The free experience includes CSPM features such as secure score, detection of security misconfigurations in your Azure machines, asset inventory, and more.
CWP | Cloud Workload Protection | Provides workload-centric security protection solutions such as servers, app service, storage, database and more. All CWP capabilities are covered under Azure Defender.
JIT | Just-in-time | Feature to reduce exposure to attacks while providing easy access when you need to connect to a VM
ARM | Azure Resource Manager | Deployment and management layer that enables you to create, update, and delete resources in your Azure account.
RBAC | Role-based access control | Authorization system built on Azure Resource Manager that provides fine-grained access management of Azure resources.
VA | Vulnerability Assessment | Provides vulnerability scanning for your virtual machines and container registries.
SIEM | Security information and event management | Tool to provide a central place to collect events and alerts, that aggregates data from multiple systems and analyze that data to catch abnormal behavior or potential cyberattacks. For example, Azure Sentinel.