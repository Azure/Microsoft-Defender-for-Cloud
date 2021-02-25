# Module 1 - Prerequisites

## Step #0 – Ensure the basic environment setup and knowledge are in place

To follow the implementation steps in this document, it is necessary that customers have a solid understanding of Azure Security Center (ASC) and its basic functionality and features. They should also be familiar with the governance and automation options in Azure to successfully deploy ASC in their organization. We therefore assume that customers are familiar with the following concepts:

* The customer understands the shared responsibility model and the threat landscape in the cloud.
    * [Shared responsibility in the cloud](https://docs.microsoft.com/en-us/azure/security/fundamentals/shared-responsibility)
    *	[Respond to today’s threats](https://docs.microsoft.com/en-us/azure/security-center/security-center-alerts-overview#respond-to-todays-threats--)
    *	[The threat landscape](https://www.microsoftpressstore.com/articles/article.aspx?p=2992603&seqNum=4)
*	The customer has defined and implemented a Management Group (MG) hierarchy in their Azure environment according to the organization’s needs.
    *	[What are Azure management groups?](https://docs.microsoft.com/en-us/azure/governance/management-groups/overview)
    *	[Subscription decision guide](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/decision-guides/subscriptions/)
    *	[Management group and subscription organization](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/enterprise-scale/management-group-and-subscription-organization)
    *	[Governance guide for complex enterprises](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/govern/guides/complex/)
    *	[Organize and manage multiple Azure subscriptions](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/organize-subscriptions)
*	The customer has a basic understanding of Azure Security Center and its functionalities.
    *	[What is Azure Security Center?](https://docs.microsoft.com/en-us/azure/security-center/security-center-introduction)
    *	[Azure Security Center’s overview page](https://docs.microsoft.com/en-us/azure/security-center/overview-page)
    *	[Security recommendations](https://docs.microsoft.com/en-us/azure/security-center/recommendations-reference)
    *	[Introduction to Azure Defender](https://docs.microsoft.com/en-us/azure/security-center/azure-defender)
    *	[Working with security policies](https://docs.microsoft.com/en-us/azure/security-center/tutorial-security-policy)
*	The organization understands the different roles that are available within Azure Security Center and RBAC (Role-based access control) in general.
    *	[Permissions in Azure Security Center](https://docs.microsoft.com/en-us/azure/security-center/security-center-permissions)
    *	[What is Azure RBAC?](https://docs.microsoft.com/en-us/azure/role-based-access-control/overview)
    *	[Azure built-in roles](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles)
*	The customer knows how to use a Log Analytics workspace and has decided on a Log Analytics workspace design (centralized or distributed).
    *	[Best practices for designing an Azure Sentinel or Azure Security Center Log Analytics workspace](https://techcommunity.microsoft.com/t5/azure-sentinel/best-practices-for-designing-an-azure-sentinel-or-azure-security/ba-p/832574)
    *	[Design a workspace deployment](https://docs.microsoft.com/en-us/azure/azure-monitor/platform/design-logs-deployment#important-considerations-for-an-access-control-strategy)
*	The customer understands ASC pricing, Azure Monitor pricing, and Azure bandwidth costs.
    *	[ASC Pricing](https://azure.microsoft.com/en-us/pricing/details/security-center/)
    *	[Azure Monitor Pricing](https://azure.microsoft.com/en-us/pricing/details/monitor/)
    *	[Azure Bandwidth Pricing](https://azure.microsoft.com/en-us/pricing/details/bandwidth/)
*	The customer has a solid understanding of Azure Policy and other Azure Governance constructs like Azure Blueprints and Azure Resource Graph.
    *	[What is Azure Policy?](https://docs.microsoft.com/en-us/azure/governance/policy/overview)
    *	[Understand Azure Policy effects](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/effects)
    *	[What is Azure Blueprints?](https://docs.microsoft.com/en-us/azure/governance/blueprints/overview)
    *	[What is Azure Resource Graph?](https://docs.microsoft.com/en-us/azure/governance/resource-graph/overview)
*	The customer is familiar with one or more of the following Azure Resource Manager automation options:
    *	[Azure REST API](https://docs.microsoft.com/en-us/rest/api/azure/)
    *	[ARM templates](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/overview)
    *	[Azure PowerShell](https://docs.microsoft.com/en-us/powershell/azure/?view=azps-5.0.0)
    *	[Azure CLI](https://docs.microsoft.com/en-us/cli/azure/what-is-azure-cli)

<br />

### &#8680; Continue with the next steps: [Module 2 - Roles & Permissions](./2-Roles-and-Permissions.md)
