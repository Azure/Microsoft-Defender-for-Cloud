
# PowerShell & CLI sample scripts to onboard to Defender for APIs at scale
In this section you can find 3 PowerShall samples and 3 CLI samples for onboarding APIs to Defender for APIs at scale.

## Types of Onboarding scripts available
1. Onboarding all of the APIs in an APIM (Azure API Management service) of your choice at scale. (Both CLI & Powershell)
2. Onboarding all of the APIs in an Azure subscription (in all of the APIMs in that subscription) at scale. (Both CLI & Powershell)
3. Onboarding all of the APIs in an Azure tenant (in all of the APIMs in that tenant) at scale. (Both CLI & Powershell)

## Prerequisites for the Powershell samples:
To authorize the Powershell scripts, create an app registration in Microsoft Entra ID [here](https://learn.microsoft.com/en-us/azure/healthcare-apis/register-application) and set the roles (RBAC) required on it from [Defender for APIs](https://learn.microsoft.com/en-us/azure/defender-for-cloud/defender-for-apis-prepare#onboarding-requirements) at the scope of your choice eg on that subscription if you are onboarding to the entire subscription. Follow the RBAC steps [here](https://learn.microsoft.com/en-us/azure/role-based-access-control/role-assignments-portal?tabs=delegate-condition#step-2-open-the-add-role-assignment-page).
Then fill in the clientId and clientSecret in the Powershell script from the newly created app MS Entra ID app registration. Also fill in the tenantID, subscriptionID, APIM name as required per the script.

## Prerequisites for the CLI samples:
Run the CLI samples from the Azure CLI.
