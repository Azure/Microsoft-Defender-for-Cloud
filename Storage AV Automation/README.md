# Antivirus Automation for Azure Storage
Antivirus Automation for Azure Storage is an independent system that protects one Azure Blob Container from malware by performing a scan on each uploaded blob. The project consists of an Azure Function Blob Trigger that starts upon blob upload, and a Windows VM that utilizes Windows Defender as a malware scanner.

For each blob uploaded to the protected container, the function will send the blob to the VM for scanning and changes the blob location according to the scan results:
* If the blob is clean, it will be moved to the "clean-files-container" 
* If it contains malware it will move to "quarantine-container"

The Azure Function and the VM are connected through a virtual network and communicate using HTTP requests.

The systems specifications:
* Supports parallel blob scanning
* Designed for simple use for Dev and Non-Dev users 
* Can be modified if needed.

List of created resource:
1. Function App
1. App Service Plan
1. Virtual Network
1. Network Security Group
1. Storage Account - Host for the function app
1. Virtual Machine
1. Disk - Storage for the VM
1. Network Interface - NIC for the VM
1. Key Vault
    1. Stores connection string to the storage account to scan as a secret
1. Optional: Public IP - Used to acces the VM from public endpoint

## Getting Started - Simple Deployment

### Prerequisites:
* Azure Subscription
* Azure Storage Account with at least one blob container

The simplest way to create the system is to use an ARM Template that is provided under the ARM_Template folder.

There are two ways to deploy the template:

### Deploy the ARM template from the Azure portal:
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FStorage%20AV%20Automation%2FARM_template%2FAntivirusAutomationForStorageTemplate.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>   


### Deploy the ARM template with an Azure CLI script

This part requires some knowledge in PowerShell scripting and Git.

1. Make sure you have [Azure CLI Tools][instalCliUrl] installed.

1. Clone the repo
    ```
    git clone https://github.com/Azure/Azure-Security-Center.git
    ```
1. Create Storage AV Automation/ARM_template/AntivirusAutomationForStorageTemplate.parameters.json file and fill the parameters.
    * Deployment Script Parameters:
        * location
        * resourceGroupName - Can be the name of a new group or an existing one.
        * subscriptionID
        * armTemplateFile
        * armTemplateParametersFile
1. Run the script. During the execution, you will be prompted to enter your Azure credentials.


## Getting Started - Advanced
This part is for users that want to modify the code and make some changes.

### Prerequisites:
* Azure Subscription
* Azure Storage Account with at least one blob container
* Azure Storage Account to host the code package (can be the same as the target Storage Account)
* .Net Core 3.1 SDK installed
* Azure CLI Tools installed - [Install Azure CLI][instalCliUrl]
* Knowledge of PowerShell scripting and Git

### Project Structure:
* ScanUploadedBlobFunction - contain the Azure Function Blob Trigger source code.

* ScanHttpServer - contains the HttpServer project that runs on the VM and waits for requests, the VM has in Init Script to start the ScanHttpServer. The script can be found in the same folder and can be modified too. The ScanHttpServer will be run with a simple script that restart the app if it crashes (/ScanHttpServer/runLoop.ps1)

* Build and Deploy Script (BuildAndDeploy.ps1) - will prepare the project for deployment, upload the source code to a host storage account and deploy the arm template using the parameters in the script (the script overrides the ARM template parameters file).

    *  Function Code - build, zipped and uploaded
        * build command:
    
        ```powershell
        dotnet publish <csproj-file-location> -c Release -o <out-path>
        ```

    *  ScanHttpServer Code - build, zipped and uploaded using this command:

        ```powershell
        dotnet publish -c Release -o <csproj-file-location>
        ```

    * The zip file must contain the ScanHttpServer binary files and runLoop.ps1 script to run the server on the VM.

    * Build and Deploy Script Parameters:
        * sourceCodeStorageAccountName - Storage account name to store the source code, must be public access enabled.
        * sourceCodeContainerName - Container name to store the source code, can be new or existing, if already exists must be with public access.
        * subscriptionID - Storage account to scan subscription ID.
        * targetResourceGroup - Storage account to scan resource group name.
        * targetStorageAccountName - Name of the storage account to scan.
        * targetContainerName - Name of the container to scan.
        * deploymentResourceGroupName - Resource group to deploy the AV system to.
        * deploymentResourceGroupLocation - Resource group Geo location.
        * vmUserName - VM username
        * vmPassword - VM password

### Deployment Steps
1. Clone the repo
    ```
    git clone https://github.com/Azure/Azure-Security-Center.git
    ```
1. Modify the project
1. Open Storage AV Automation/Scripts/BuildAndDeploy.ps1 and enter the necessary parameters
1. Run the script. During the execution, you will be prompted to enter your Azure credentials.


## Scanning storage account inside a virtual network
This section refers to the case in which your storage account can't be accessed through public endpoints but only through virtual network.  
This template deploys the scanning system to an existing virtual network to gain access to your storage account.

Unlike the simple scenario this case require some manual steps in order to complete the deployment using Azure portal:
* Open your the storage account (the storage account to scan)
* Go to Networking section under Security + networking
* Under Virtual Networks click "Add existing virtual network"
* Inside the "Add network" form choose the virtual network used for the deployment and add the new subnets:
    * functionSubnet
    * VMSubnet
* Click "Add"
* Save the new configuration using the "Save" button
 

### Deploy the ARM template from the Azure portal:
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FStorage%20AV%20Automation%2FARM_template%2FAVAutomationForStorageExistingVnetTemplate.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>  


## Important Notes

* Blobs uploaded to the protected container are sent from the Function to VM through HTTP request inside the Virtual Network.

* Files potentially containing malware are saved locally by the VM for scanning. They're deleted afterwards. So be aware that the VM might be compromised.

* The port number for the communication is hardcoded and can't be passed as parameter.

* The ARM template deployment can take up to 10 minutes so be patience.

* Monitoring the system:
    * Function - you can configure Azure Application Insights resource to monitor the Function logs by going to your Function->Monitor->Configure Application Insight.
    * Scan HTTP Server - logs kept inside the machine in <RunPath>/log/ScanHttpServer.log as a single file.


[instalCliUrl]: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
