# Get-SqlVMProtectionStatusReport.ps1

## Retrieve and Report SQL VM Protection Status from Microsoft Defender for SQL

### Overview
The `Get-SqlVMProtectionStatusReport.ps1` script is designed to retrieve and report the **Microsoft Defender for SQL** protection status from all **SQL Virtual Machines** within a specified Azure subscription. The script:
- Queries **Microsoft Defender for SQL** registry settings from the underlying virtual machines of SQL VMs.
- Retrieves Defender for SQL protection status from the registry of the machine.
- Converts the timestamp from .NET ticks to an ISO 8601 formatted date.
- Aggregates results for all SQL instances found on each VM.
- Exports the collected data to an **Excel report**, which includes:
  - SQL VM Name
  - SQL Instance Name
  - Protection Status
  - Last Update Time
  - SQL VM Resource ID

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

### 3. Enable Microsoft Defender for SQL on SQL VMs
Ensure **Microsoft Defender for SQL** is enabled on your **SQL Server VMs**.
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

### Step 3: Analyze and Troubleshoot
- Open the Excel file and review the protection status of SQL VMs.
- If any SQL VM is **unprotected**, refer to **Microsoft Defender for SQL** documentation to enable protection:
  👉 [Microsoft Defender for SQL on machines](https://learn.microsoft.com/en-us/azure/defender-for-cloud/defender-for-sql-usage)

---

## How It Works
1. **Retrieves SQL Virtual Machines** (`Get-AzSqlVM`) in the provided **Azure Subscription**.
2. **Identifies the Underlying VM** for each SQL VM.
3. **Runs a Remote PowerShell Command** (`Invoke-AzVMRunCommand -AsJob`) on each VM to:
   - Enumerate SQL instances under `HKLM:\SOFTWARE\Microsoft\AzureDefender\SQL\`
   - Retrieve registry values **SqlQueryProtection_Status** and **SqlQueryProtection_Timestamp**
   - Convert timestamps from .NET ticks to **ISO 8601** format.
4. **Aggregates and Formats Data**, ensuring clean processing.
5. **Exports to an Excel Report**, using Excel PowerShell module.

---

## Troubleshooting & FAQ

### **Q1: I get an error: "Subscription not found."**
**Solution:** Ensure you provide the correct **Subscription ID** or **Subscription Name**.

### **Q2: The report shows empty results.**
**Solution:** Ensure:
- The subscription contains **SQL VMs**.
- You have the correct **Azure role permissions** to access these VMs.
- **Microsoft Defender for SQL** is enabled for the VMs.

### **Q3: I get an "Invoke-AzVMRunCommand failed" error.**
**Solution:** Ensure:
- The target **VMs are running**.
- The **VM agent is installed** on each VM (required for `Invoke-AzVMRunCommand`).

For additional guidance, check 👉 [Invoke-AzVMRunCommand](https://learn.microsoft.com/en-us/powershell/module/az.compute/invoke-azvmruncommand?view=azps-13.2.0).

---

## Changelog
- **v1.0:** Initial release with full subscription-wide SQL VM scanning and Excel reporting.
- **v1.1:** Improved JSON parsing and added **subscription-based filename versioning**.

---