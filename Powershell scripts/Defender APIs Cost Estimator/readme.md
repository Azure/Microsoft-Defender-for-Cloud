# Microsoft Defender for Cloud - Defender for APIs Plan Cost Estimator

**Author  : Giulio Astori, Preetham Anand Naik**  

This PowerShell script, `d4apis_cost_estimator_v1.ps1`, is designed to estimate the cost of Microsoft Defender for Cloud - Defender for APIs Plan. It leverages Azure PowerShell modules to authenticate users, retrieve subscription details, and, ultimately, fetch the Total API requests for each APIM resources. This document outlines how the script operates, how to run it, and the necessary permissions for execution.

## How It Works

The script operates in several key steps:
1. **Strict Mode Activation**: Ensures that all variables are declared and catches common errors early.
2. **Azure Login Verification**: Checks if the user is logged into Azure. It's crucial for executing any Azure-related commands.
3. **Subscription Enumeration**: Retrieves the list of Azure subscriptions available to the user. This is vital for identifying the context in which the resources reside.
4. **Cost Estimation**: For each Subscriptions the script enumarates the APIM resources and for each retreive the total request metric value. With such It aims to estimate the cost of Microsoft Defender for Cloud - Defender for APIs Plan.

## Execution Steps

To run this script, follow these steps:

1. **Prerequisites**:
   - Ensure you have the Azure PowerShell module (`Az` module) installed. If not, you can install it by running `Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force`.
   - Log in to your Azure account using `Connect-AzAccount`.

2. **Download the Script**: Clone this repository or download the `d4apis_cost_estimator_v1.ps1` script directly.

3. **Execute the Script**: Open PowerShell and navigate to the directory containing the script. Run the script using:
   ```powershell
   .\d4apis_cost_estimator_v1.ps1
4. **Review the Result**: Navigate to the directory containing the script and open the file generated named "**AllSubscriptionsPlanRecommendation.csv**".

To successfully execute this script and perform its intended operations, the following permissions are required:

    Azure Subscription Read: Necessary to enumerate the Azure Subscriptions. This can typically be granted through roles like Reader or Contributor at the subscription level.

    Azure API Management (APIM) Service Metrics Read: While the current version of the script does not directly fetch APIM service metrics, if you intend to extend its functionality to estimate costs based on APIM services, you would need permissions to read these metrics. This requires the APIM Service Reader role or a custom role with equivalent permissions.

Ensure you have these permissions assigned to your Azure account, or consult with your Azure administrator to acquire them.