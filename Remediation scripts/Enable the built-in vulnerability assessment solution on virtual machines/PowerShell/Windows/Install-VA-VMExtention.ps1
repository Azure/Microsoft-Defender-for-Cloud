#***************************************************************************************************************
# This script will import a CSV file, based on the "checkForVAExtension" script output file
# and install the Vulnerability Assessment extension on all the VMs found in that CSV
#**************************************************************************************************************

$ErrorActionPreference = 'Stop'

#Login-AzAccount

#variables
$VMinputFolder = "c:\temp\"
$VMinputFile = "ASC-inputFile.csv"  # We will install the Vulnerability Analysis VM extension onto the VMs in this file


#fill in your workspaceID, workspaceKey, resourcegroup name and location
$publicSettings = @{"workspaceId" = "<YourWorkspaceID>"}
$protectedSettings = @{"workspaceKey" = "<YourWorkspaceKey>"}

# Importing CSV file
Write-Host "*** Trying to import file:" ($VMinputFolder + $VMinputFile) " ***" -ForegroundColor Green
try {
    $targetVMs = Import-Csv -Path ($VMinputFolder + $VMinputFile)
    Write-Host "Your input file contains" $targetVMs.VMname.count "VM's" -ForegroundColor Green
}
catch {Write-Host "Could not open input file.... Please check your path and filename." -ForeGroundColor Red}

$answer = Read-Host "Continue installation? (yes/no)"
if($answer -eq "yes"){
    Write-Host "Starting VM extension installation" -ForegroundColor Green
    }
else
{
    Write-Host "Aborting installation" -ForegroundColor Red
    break
}

# loop through csv and install VA VM extension
foreach($VM in $targetVMs)
{
    Write-Output "`r`n"
    Write-Host "*** Installing the Vulnerability Assessment VM extension on" $VM.VMname "- Subscription:" $VM.SubScriptionName -ForegroundColor Green
    Write-Host "Changing to subscription:" $VM.SubScriptionName -ForegroundColor Green
    
    try
    {
        Set-AzContext -Subscription $VM.SubScriptionName
        Write-Host "Installing the VA VM Extension on Windows....please wait..." -ForeGroundColor Green
        try
        {
            # check if the VM extension has already been installed
            Get-AzVMExtension -VMName $VM.VMname -ResourceGroupName $VM.ResourceGroup -Name "WindowsAgent.AzureSecurityCenter" | Select-Object VMName, ProvisioningState, ResourceGroupName
            Write-Host "The VA Extension has already been installed, so skipping this VM...." -ForegroundColor Red

        }
        catch
        {
            Set-AzVMExtension -VMName $VM.VMname -ResourceGroupName $VM.ResourceGroup `
            -Name WindowsAgent.AzureSecurityCenter `
            -TypeHandlerVersion 1.0 `
            -Publisher Qualys  `
            -ExtensionType WindowsAgent.AzureSecurityCenter `
            -Settings $publicSettings `
            -ProtectedSettings $protectedSettings `
            -Location $VM.Location
            Write-Host "Done!" -ForeGroundColor Green
        }

        
    }
    catch {Write-Host "Could not set subscription or could not install the VM extension" -ForegroundColor Red}
}