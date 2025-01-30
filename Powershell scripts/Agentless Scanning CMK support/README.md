# Add CMK Permissions for Agentless Scanning

This script identifies and configures Key Vaults associated with Customer Managed Keys (CMKs) to ensure agentless scanning permissions are in place.

## Features

- Grants permissions at **subscription level** (default) or **Key Vault level**.
- Supports Key Vaults in different subscriptions than their disks.
- Detects **access policies** (legacy model) and advises migration to Azure RBAC.

## EXAMPLES

```powershell
.\AddCmkPermissions.ps1 -Subscriptions "Subscription1", "Subscription2" -DryRun
.\AddCmkPermissions.ps1 -Subscriptions "Subscription1" -ApplyAtKeyVaultLevel
```

## SYNOPSIS
This script iterates over all VMs in specified subscriptions, identifying those with Customer Managed Keys (CMK). It applies RBAC permissions at the **subscription level** by default but can also apply permissions at the **Key Vault level** if specified.

## PARAMETERS

### Subscriptions
An array of Azure Subscription IDs.

### DryRun
A switch parameter to simulate the process without making changes.

### ApplyAtKeyVaultLevel
A switch parameter to apply permissions at the Key Vault level instead of the default subscription level.

## NOTES
- **Access Policies Key Vaults**: Subscription-level RBAC permissions do not apply. The script detects such cases and offers options to configure manually.
- **Migration to RBAC is recommended** for better security & manageability.
    - Migration Guide: [https://learn.microsoft.com/en-us/azure/key-vault/general/rbac-migration](https://learn.microsoft.com/en-us/azure/key-vault/general/rbac-migration)
    - RBAC vs. Access Policies: [https://learn.microsoft.com/en-us/azure/key-vault/general/rbac-access-policy](https://learn.microsoft.com/en-us/azure/key-vault/general/rbac-access-policy)
