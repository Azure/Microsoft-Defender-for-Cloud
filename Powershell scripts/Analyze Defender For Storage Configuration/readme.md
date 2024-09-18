# Analyze-DefenderForStorageConfig.ps1

## Description

This PowerShell script analyzes the configuration of Microsoft Defender for Storage in your Azure environment.

## Prerequisites

- Azure PowerShell module
- Permissions to read storage account configurations in your Azure subscription

## Usage

1. Clone the repository or download the script directly.
2. Open a PowerShell session.
3. Execute the script with the required parameters. You need to provide your subscription IDs and the output path where you want to save the results. Optionally, you can specify the storage account names to analyze.

```powershell
.\Analyze-DefenderForStorageConfig.ps1 -SubscriptionIds "1234-abcd-567-efg", "2345-abcd-123-mnb" -OutputPath "C:\path\to\output.csv"
```

#### Example with Optional Parameter
```powershell
.\Analyze-DefenderForStorageConfig.ps1 -SubscriptionIds "1234-abcd-567-efg", "2345-abcd-123-mnb" -OutputPath "C:\path\to\output.csv" -StorageAccountNames "storage1", "sa1234"
```

### Parameters
- SubscriptionIds: An array of subscription IDs you want to analyze.
- OutputPath: The path where the output CSV file will be saved.
- StorageAccountNames (optional): An array of specific storage account names to analyze. If not provided, all storage accounts in the subscriptions will be analyzed.



## Output
The script outputs a detailed CSV file of the Defender for Storage configuration for each storage account in the specified resource group. The report includes information on:

- Storage account name
- Defender for Storage effective plan 
- Sensitive Data Threat Detection feature (enabled/not enabled)
- On Upload Malware Scanning feature (enabled/not enabled)
- On Upload Malware Scanning cap

### Output Sample
| SubscriptionName | SubscriptionId     | ResourceGroupName  | StorageAccountName   | SubscriptionPlan      | EffectivePlanOnResource                               | SensitiveDataThreatDetection | OnUploadMalwareScanning | OnUploadMalwareScanningCap |
|------------------|--------------------|--------------------|----------------------|-----------------------|------------------------------------------------------|------------------------------|-------------------------|----------------------------|
| Contoso          | 1234-abcd-567-efg  | HR-resourcegroup   | storage1             | PerStorageAccount     | Classic Per-Storage Account Plan (v1.5)              |                              |                         |                            |
| CloudContoso     | 2345-abcd-123-mnb  | rg1                | sa1234               | DefenderForStorageV2  | New Defender for Storage Per-Storage Account Plan (v2) | TRUE                         | TRUE                    | 5000                       |
| DevContoso       | 0987-ytre-765-vcx  | devresourcegroup   | storageaccountdev    | PerStorageAccount     | Classic Per-Transaction Plan (v1)                    |                              |                         |                            |

## Notes
- Ensure you have the Azure PowerShell module installed and are authenticated to your Azure account.
- The script will iterate through the provided subscription IDs and analyze the Defender for Storage configuration for each storage account.
- The results will be exported to the specified CSV file.

## Support
This script is provided as-is, without any official support. If you encounter any issues, please open an issue in the repository, and the community will try to assist you.
