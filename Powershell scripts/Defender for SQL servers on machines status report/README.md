# Get-SqlVMProtectionStatusReport.ps1

## Validating SQL Instance Protection Under The *Microsoft Defender for SQL Servers on Machines* Plan

## Overview
Defender for SQL on machines provides comprehensive security for SQL servers hosted on Azure Virtual Machines, on-premises infrastructure, and Azure Arc-enabled servers.<!-- -->
It helps you discover and mitigate potential [database vulnerabilities](https://learn.microsoft.com/en-us/azure/defender-for-cloud/sql-azure-vulnerability-assessment-overview)<!-- -->
and alerts you to [anomalous activies](https://learn.microsoft.com/en-us/azure/defender-for-cloud/defender-for-sql-introduction?source=recommendations#advanced-threat-protection) that might indicate a threat to your databases.
For further details about the plan and how to enable protection, [please visit this page](https://learn.microsoft.com/en-us/azure/defender-for-cloud/defender-for-sql-usage).

The `Get-SqlVMProtectionStatusReport.ps1` script is designed to retrieve and report the **Microsoft Defender for SQL** protection status from all **SQL Virtual Machines** within a specified Azure subscription.

## Prerequisites
Before using this script, ensure you meet the following requirements:

### 1. PowerShell Modules
Install the necessary Azure PowerShell modules:
```powershell
Install-Module -Name Az -AllowClobber -Scope CurrentUser
Install-Module -Name ImportExcel -Scope CurrentUser
```
If the modules are already installed, ensure they are updated:
```powershell
Update-Module -Name Az
Update-Module -Name ImportExcel
```

### 2. Azure Authentication
Log in to your Azure account:
```powershell
Connect-AzAccount
```
Ensure you have **permissions** to run `Invoke-AzVMRunCommand` on the target VMs.

### 3. Ensure that the Microsoft Defender for SQL servers on machines plan is enabled
Ensure **Microsoft Defender for SQL** is enabled on your **subscription**.
More details on Defender for SQL can be found here:  
👉 [Microsoft Defender for SQL on machines](https://learn.microsoft.com/en-us/azure/defender-for-cloud/defender-for-sql-usage)

---

## Usage Instructions
### Step 1: Run the Script
To execute the script, run the following command, replacing `<SubscriptionIdOrName>` with either the **Subscription ID** or **Subscription Name**:

```powershell
.\Get-SqlVMProtectionStatusReport.ps1 -SubscriptionIdOrName "<SubscriptionIdOrName>"
```

### Step 2: Review the Report
- The script will generate an **Excel file** containing the results.
- The file is saved in the same directory where the script is run.
- The output filename follows this format:
```plaintext
  SqlVmProtectionResults_<SubscriptionId>.xlsx
```

- **Status Explanation:**
  - **Protected:** Defender for SQL is actively protecting the instance. It is important to check the "Last Update" field to ensure the information is recent and not outdated.
  - **Not Protected:** Defender for SQL encountered issues while protecting the instance. This indicates that some intervention is required to enable successful protection.
  - **Inactive:** Defender for SQL is running on the machine, but the SQL instance is either paused or stopped.
  - **Empty:** The protection status could not be retrieved or the status does not exist on the machine. In this case, assume that the instance is not protected by Defender for SQL.

### Step 3: Analyze and Troubleshoot
- Open the Excel file and review the protection status of your SQL instances.
- If any SQL  server instance is **unprotected**, please refer to the **following troubleshooting guide**:
  👉 [Troubleshooting SQL server on machines](https://learn.microsoft.com/en-us/azure/defender-for-cloud/troubleshoot-sql-machines-guide)

---

## How The Script Works
The script:
1. **Retrieves SQL Virtual Machines** (`Get-AzSqlVM`) in the provided **Azure Subscription**.
2. **Identifies the Underlying VM** for each SQL VM.
3. **Runs a Remote PowerShell Command** (`Invoke-AzVMRunCommand -AsJob`) on each VM to:
   - Enumerate SQL instances under `HKLM:\SOFTWARE\Microsoft\AzureDefender\SQL\`
   - Retrieve registry values of the protection status and the timestamp of its last update
   - Convert timestamps to **ISO 8601** format.
4. **Aggregates and Formats Data** for all SQL instances found on each VM.
5. **Exports to an Excel Report**, which includes:
    - SQL VM Name
    - SQL Instance Name
    - Protection Status
    - Last Update Time
    - SQL VM Resource ID
    - Failure Reason (if applicable)

---

## Troubleshooting & FAQ

### **Q1: I get an error: "Subscription not found."**
**Solution:** Ensure you provide the correct **Subscription ID** or **Subscription Name**.

### **Q2: The report shows empty results.**
**Solution:** Ensure:
- The subscription contains **SQL VMs**.
- You have the correct **Azure role permissions** to access these VMs.
- **Microsoft Defender for SQL server on machines** plan is enabled for the specified subscription.

### **Q3: I get an "Invoke-AzVMRunCommand failed" error.**
**Solution:** Ensure:
- The target **VMs are running**.
- The **VM agent is installed** on each VM (required for `Invoke-AzVMRunCommand`).

For additional guidance, check 👉 [Invoke-AzVMRunCommand](https://learn.microsoft.com/en-us/powershell/module/az.compute/invoke-azvmruncommand?view=azps-13.2.0).

---
