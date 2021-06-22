# Inventory (for reporting purposes)

Most enterprise customers today have deployed Azure Security Center at least to some extent in their organizations. In this case, they can use [Azure Resource Graph](https://docs.microsoft.com/en-us/azure/governance/resource-graph/) queries to get an overview of their current security state and answer the following questions:
1.	How many subscriptions do I have?
2.	How many of these subscriptions have been onboarded to ASC?
3.	How many of these subscriptions have not yet been onboarded to ASC?
4.	Which subscriptions have not yet been onboarded to ASC?
5.	Which subscriptions are using ASC with Azure Defender fully enabled?
6.	Which subscriptions are using ASC without Azure Defender fully enabled?
7.	What is the coverage (On | On (partial) | Off) for Azure Defender across all of my subscriptions?
8.	Which Azure Defender plans (Azure Defender for VMs, Azure Defender for KeyVaults, etc.) are enabled across all of my subscriptions?  

The matching Azure Resource Graph queries can be found [here](https://github.com/Azure/Azure-Security-Center/tree/master/Kusto/Azure%20Resource%20Graph/Starter%20Kit%20-%20ASC%20Pricing).

In order to run these Azure Resource Graph queries, we recommend that customers have at least *Security Admin* and *Reader* permissions on the appropriate management group level. For further details, refer to [Step #2 in Module 2 - Roles and permissions](./Modules/2-Roles-and-Permissions.md#step-2---assign-the-necessary-rbac-permissions-to-the-central-security-team).

Running these queries is an optional step, but it helps to compare the customers current security state to the security state after rolling out and governing ASC centrally, and it may be useful for reporting progress to management.
