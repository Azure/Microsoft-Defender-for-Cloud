# AI Red Teaming Workshop

This workshop deploys an environment for running the [Azure AI Red Teaming Agent](https://learn.microsoft.com/azure/ai-foundry/how-to/develop/run-scans-ai-red-teaming-agent) in a secure, managed setup.

## Introduction

<a href="https://airtwork.blob.core.windows.net/$web/videos/airtwelcomevideo.mp4" target="_blank">Watch Introduction Video Here</a>

## Prerequisites

1. Upload the repo (or just `register_providers.sh`) into an Azure Cloud Shell or your local AZ CLI environment and run `./register_providers.sh` to register the required resource providers.
2. Turn on [Defender for AI Services](https://learn.microsoft.com/azure/defender-for-cloud/ai-onboarding#enable-threat-protection-for-ai-services-1) in the subscription that will host the workshop resources.

## Deploy the Templates

### Deploy the Main Template
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fswiftsolves-msft%2FAI-Red-Teaming-Workshop%2Fmain%2Fazuredeploy.json)

### Deploy this Forked Template
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FThor-DraperJr%2FAI-Red-Teaming-Workshop%2Fmain%2Fazuredeploy.json)

## Deployment Guidance


> Must be deployed in **East US 2** or another supported region for AI Red Teaming Agent.
> Only a single parameter (`userObjectId`) is required.
> Avg deployment time: ~15 minutes

## What the template deploys

The current `azuredeploy.json` provisions the following (no manual role assignment or compute creation required):

| Category | Resource | Notes |
|----------|----------|-------|
| Storage | 1 x `Microsoft.Storage/storageAccounts` | Name pattern: `<rgprefix>sa<unique>`; identity-based access configured for system datastores. |
| Secrets | 1 x `Microsoft.KeyVault/vaults` | RBAC-enabled (`enableRbacAuthorization: true`); no access policies created. |
| Monitoring | 1 x `Microsoft.Insights/components` | Application Insights (classic) for logging. |
| Identity | 1 x `Microsoft.ManagedIdentity/userAssignedIdentities` | Attached to the compute instance and granted storage + OpenAI access. |
| AI Services | 1 x `Microsoft.CognitiveServices/accounts` (kind `AIServices`) | System‑assigned identity; model deployment `gpt-4o-mini` created automatically. |
| Model Deployment | `accounts/deployments/gpt-4o-mini` | Deployment name fixed; version `2024-07-18`. |
| Hub Workspace | `Microsoft.MachineLearningServices/workspaces` (kind `Hub`) | Configured with storage/key vault/app insights + identity datastore mode. |
| Project Workspace | `Microsoft.MachineLearningServices/workspaces` (kind `Project`) | Linked to hub (inherits security settings). |
| Compute Instance | `workspaces/computes` (ComputeInstance) | Size `Standard_E4ds_v4`, personal assignment to `userObjectId`, idle shutdown 1h. |
| Role Assignments | Multiple `Microsoft.Authorization/roleAssignments` | See “RBAC applied automatically” below. |

### RBAC applied automatically
The template assigns all required roles; you should NOT manually add storage or cognitive services roles unless customizing.

| Principal | Scope | Role (friendly name) |
|----------|-------|----------------------|
| User (`userObjectId`) | Storage Account | Storage Blob Data Contributor |
| User (`userObjectId`) | Storage Account | Storage File Data Privileged Contributor |
| User (`userObjectId`) | Hub Workspace | Azure AI Developer |
| User (`userObjectId`) | Project Workspace | Azure AI Developer |
| User Assigned Identity | Storage Account | Storage Blob Data Contributor |
| User Assigned Identity | Storage Account | Storage File Data Privileged Contributor |
| User Assigned Identity | Cognitive Services Account | Cognitive Services OpenAI User |
| Project Workspace Managed Identity | Cognitive Services Account | Cognitive Services OpenAI User |

> Verification: In the Azure Portal, open the resource group > Access control (IAM) > Role assignments, filter by the roles above. All will appear shortly after deployment (role assignment propagation can take a few minutes).

> Note: After deployment Azure may also create (or your organization may enforce) additional storage-scoped role assignments for the hub and project workspace managed identities (e.g., Storage Account Contributor, Storage Table Data Contributor, Reader) to enable system datastore isolation and management. These are expected even though they are not explicitly declared in `azuredeploy.json`. If you see broader roles like Azure AI Administrator at a scope, they likely originate from existing subscription / policy baselines rather than this template.

## Parameter

| Name | Description |
|------|-------------|
| `userObjectId` | Microsoft Entra Object ID of the user who will own the personal compute instance and receive developer/storage roles. Obtain with the command below. |

```bash
az ad signed-in-user show --query id -o tsv
```

## Deployment Region

Use a supported region for AI Red Teaming Agent (for example, East US 2). See the [region support list](https://learn.microsoft.com/en-us/azure/ai-foundry/how-to/develop/run-scans-ai-red-teaming-agent#region-support).

![Deploy](./images/deploytemplatedirections.png)

## Post‑Deployment Checklist

1. In Azure ML Studio, open the Hub workspace (from the resource group or via [https://ml.azure.com/hubs](https://ml.azure.com/hubs)). Open your compute with the VS Code Web experience
2. Clone workshop repo inside the compute instance terminal or upload notebooks from `workshop/files`.
3. Run the generate-env.sh script to set up the Python environment variables.
4. Run notebooks (e.g., `AIRT-AiHML.ipynb`) using the remote kernel on the provisioned compute instance.

> Portal note: This workshop uses a **hub-based project** in **Microsoft Foundry (classic)**, backed by an Azure Machine Learning hub workspace. Microsoft Foundry (new) only shows Foundry projects; use the classic experience when navigating to evaluations and resources for this lab. To migrate from hub-based to Foundry projects later, see [Migrate from hub-based to Foundry projects](https://learn.microsoft.com/azure/ai-foundry/how-to/migrate-project).

## Participants Guide

Proceed to the [AI Red Team workshop - Participants Guide](./workshop/Module%20-%20Participant%20Guide.md)

## References

- AI Red Teaming Agent docs: https://learn.microsoft.com/azure/ai-foundry/how-to/develop/run-scans-ai-red-teaming-agent
- Hub & project concepts: https://learn.microsoft.com/azure/ai-foundry/concepts/ai-resources
- Observability & evaluations: https://learn.microsoft.com/azure/ai-foundry/concepts/observability
