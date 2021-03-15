# Welcome to the Azure Security Center Enterprise Onboarding Guide

<p align="center">
<img src="./Images/asc-logo.jpeg?raw=true">
</p>

## Introduction
This document describes the actions that an organization must take in order to successfully onboard to Azure Security Center (ASC) at scale. Our recommendation is to automate as many of the steps as possible, as this reduces both manual deployment errors and maintenance effort. Before starting, customers should check the [Prerequisites](./Modules/1-Prerequisites.md) section to make sure they can follow all of the steps outlined in the following section. If customers need to report to their management on the progress of the ASC rollout, they can run the Azure Resource Graph queries listed in the [Inventory](/.Inventory) section before and after following the implementation steps.

## Last release notes

* Version 0.5 - Preview documentation of Azure Security Center Enterprise Onboarding Guide. Use at your own risk.

## Implementation steps - Overview
The following table provides an overview of the steps required to onboard Azure Security Center at scale. For each of the steps, customers can see a summary of the required action as well as the available automation options. Further details on each step are provided in the following sections of this document.
<table>
    <thead>
        <tr>
            <th rowspan=2>Step</th>
            <th rowspan=2>Action</th>
            <th colspan="5">Automation options</th>
        </tr>
        <tr>
            <th>Azure Policy (rec.)</th>
            <th>Azure CLI</th>
            <th>Azure PowerShell</th>
            <th>REST API</th>
            <th>ARM Template</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td colspan=7>
            
[**Module 1 - Prerequisites**](./Modules/1-Prerequisites.md)
            </td>
        </tr>
        <tr>
            <td>
                
[**#0**](./Modules/1-Prerequisites.md#step-0--ensure-the-basic-environment-setup-and-knowledge-are-in-place)</td>
            <td>Ensure the basic environment setup and knowledge are in place</td>
            <td colspan="5">NA</td>
        </tr>
        <tr>
            <td colspan=7>

**[Module 2 - Roles & Permissions](./Modules/2-Roles-and-Permissions.md)**
            </td>
        </tr>
        <tr>
            <td>[**#1**](./Modules/2-Roles-and-Permissions.md#step-1---create-a-central-team-that-will-be-responsible-for-tracking-andor-enforcing-security-on-your-azure-environment)</td>
            <td>Create a central team that will be responsible for tracking and/or enforcing security on your Azure environment</td>
            <td colspan="5">NA</td>
        </tr>
        <tr>
            <td>
                [**#2**](./Modules/2-Roles-and-Permissions.md#step-2---assign-the-necessary-rbac-permissions-to-the-central-security-team)
            </td>
            <td>Assign the necessary RBAC permissions to the central security team</td>
            <td>&#10005;</td>
            <td>&#10003;</td>
            <td>&#10003;</td>
            <td>&#10003;</td>
            <td>&#10003;</td>
        </tr>
        <tr>
            <td colspan=7>

**[Module 3 - Policy Management](./Modules/3-Policy-Management.md)**
            </td>
        </tr>
        <tr>
            <td>[**#3**](./Modules/3-Policy-Management.md#step-3---assign-and-customize-the-asc-default-policy) </td>
            <td>Assign and customize the ASC default policy to the appropriate scope</td>
            <td>&#10003;</td>
            <td>&#10005;</td>
            <td>&#10005;</td>
            <td>&#10005;</td>
            <td>&#10005;</td>
        </tr>
        <tr>
            <td>[**#4**](./Modules/3-Policy-Management.md#step-4---choose-standards-for-your-compliance-dashboard-recommended)</td>
            <td>Choose standards for your compliance dashboard (recommended)</td>
            <td>&#10003;</td>
            <td>&#10003;</td>
            <td>&#10003;</td>
            <td>&#10003;</td>
            <td>&#10003;</td>
        </tr>
        <tr>
            <td>[**#5**](./Modules/3-Policy-Management.md#step-5---ensure-resources-are-secure-by-default-through-azure-policy-and-azure-blueprints-recommended)</td>
            <td>Ensure resources are secure by default through Azure Policy and Azure Blueprints</td>
            <td>&#10003;</td>
            <td>&#10005;</td>
            <td>&#10005;</td>
            <td>&#10005;</td>
            <td>&#10005;</td>
        </tr>
        <tr>
            <td>[**#6**](./Modules/3-Policy-Management.md#step-6---assign-custom-policies-optional)</td>
            <td>Assign custom policies (optional)</td>
            <td>&#10003;</td>
            <td>&#10003;</td>
            <td>&#10003;</td>
            <td>&#10003;</td>
            <td>&#10003;</td>
        </tr>
        <tr>
            <td colspan=7>

**[Module 4 - Onboarding ASC Features](./Modules/4-Onboarding-ASC-Features.md)**
            </td>
        </tr>
        <tr>
            <td>[**#7**](./Modules/4-Onboarding-ASC-Features.md#step-7---enable-all-azure-defender-plans-recommended)</td>
            <td>Enable all Azure Defender plans (recommended)</td>
            <td>&#10003;</td>
            <td>&#10005;</td>
            <td>&#10005;</td>
            <td>&#10005;</td>
            <td>&#10005;</td>
        </tr>
        <tr>
            <td>[**#8**](./Modules/4-Onboarding-ASC-Features.md#step-8---set-security-contact--email-settings-recommended)</td>
            <td>Set security contact & email settings (recommended)</td>
            <td>&#10003;</td>
            <td>&#10003;</td>
            <td>&#10003;</td>
            <td>&#10003;</td>
            <td>&#10003;</td>
        </tr>
        <tr>
            <td>[**#9**](./Modules/4-Onboarding-ASC-Features.md#step-9---deploy-required-agents-recommended)</td>
            <td>Deploy required agents (recommended)</td>
            <td>&#10003;</td>
            <td>&#10003;</td>
            <td>&#10003;</td>
            <td>&#10003;</td>
            <td>&#10003;</td>
        </tr>
        <tr>
            <td colspan=7>

**[Module 5 - Management](./Modules/5-Management.md)**
            </td>
        </tr>
        <tr>
            <td>[**#10**](./Modules/5-Management.md#step-10---export-security-center-data-to-azure-sentinel-recommended)</td>
            <td>Export Security Center data to Azure Sentinel (recommended)</td>
            <td>&#10005;</td>
            <td>&#10005;</td>
            <td>&#10005;</td>
            <td>&#10003;</td>
            <td>&#10005;</td>
        </tr>
        <tr>
            <td>[**#11**](./Modules/5-Management.md#step-11---prepare-and-deploy-logic-apps-recommended)</td>
            <td>Prepare and deploy Logic Apps (recommended)</td>
            <td>&#10005;</td>
            <td>&#10005;</td>
            <td>&#10005;</td>
            <td>&#10003;</td>
            <td>&#10005;</td>
        </tr>
        <tr>
            <td>[**#12**](./Modules/5-Management.md#step-12---workflow-automation-recommended)</td>
            <td>Workflow Automation (recommended)</td>
            <td>&#10003;</td>
            <td>&#10005;</td>
            <td>&#10005;</td>
            <td>&#10003;</td>
            <td>&#10005;</td>
        </tr>
        <tr>
            <td>[**#13**](./Modules/5-Management.md#step-13---export-data-for-additional-reporting-optional)</td>
            <td>Export data for additional reporting (optional)</td>
            <td>&#10003;</td>
            <td>&#10005;</td>
            <td>&#10005;</td>
            <td>&#10003;</td>
            <td>&#10005;</td>
        </tr>
        <tr>
            <td>[**#14**](./Modules/5-Management.md#step-14---export-security-center-data-to-other-siem-or-itsm-solutions-optional)</td>
            <td>Export Security Center data to other SIEM or ITSM solutions (optional)</td>
            <td>&#10003;</td>
            <td>&#10005;</td>
            <td>&#10005;</td>
            <td>&#10003;</td>
            <td>&#10005;</td>
        </tr>
        <tr>
            <td>[**#15**](./Modules/5-Management.md#step-15---set-alert-suppression-rules-optional)</td>
            <td>Set alert suppression rules (optional)</td>
            <td>&#10003;</td>
            <td>&#10005;</td>
            <td>&#10005;</td>
            <td>&#10003;</td>
            <td>&#10005;</td>
        </tr>
    </tbody>
</table>

## Acronyms

Acronym | Meaning | Description
------- | --- | -----------
ASC | Azure Security Center | Built-in free service which offers limited security for your Azure resources only
SIEM | Security information and event management | Tool to provide a central place to collect events and alerts, that aggregates data from multiple systems and analyze that data to catch abnormal behavior or potential cyberattacks. For example, Azure Sentinel.CSPM | Cloud Security Posture Management | Automates the identification and remediation of risks across cloud infrastructures. CSPM is Security Center is available for free to all Azure users. The free experience includes CSPM features such as secure score, detection of security misconfigurations in your Azure machines, asset inventory, and more.
SOC | Security Operations Center | The main objective of a cloud SOC is to detect, respond to, and recover from active attacks on enterprise assets.
CSPM | Cloud Security Posture Management | Means having visibility to your cloud resources posture, have discovery capabilities to learn about the actual usage of each platform, be able to monitor suspicious activities, assess, and review configurations and compliance statuses, and be enabled to deploy real-time protection mechanisms.
CWPP | Cloud Workload Protection Platform | Provides workload-centric security protection solutions such as servers, app service, storage, database and more. All CWP capabilities are covered under Azure Defender.
ARM | Azure Resource Manager | Deployment and management layer that enables you to create, update, and delete resources in your Azure account.
RBAC | Role-based access control | Authorization system built on Azure Resource Manager that provides fine-grained access management of Azure resources.
MG | Management Group | Management groups allow you to organize your subscriptions and apply governance controls, such as Azure Policy and Role-Based Access Controls (RBAC), to the management groups.
