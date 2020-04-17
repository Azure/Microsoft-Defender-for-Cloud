#***************************************************************************************************************
# This script will enumerate through all your subscriptions and your Virtual Machines to report
# if the Vulnerability Assessment extension has been installed.
# It creates a CSV output file which you can review and edit, which serves as an input file to 
# install the VA extension in bulk.
#**************************************************************************************************************

$ErrorActionPreference = 'Stop'

#variables
$outputFolder = "C:\Temp\"              # Export folder
$outputFileName = "ASC-outputFile.csv"  # Output file name (will be overwritten)
$VMs = @()                              # To store all the VMs that I have access to with meta data, like MMA extension installed
$VMproperties = $null                   # VM properties like subscriptionID
$VMproperties = @{}                     # Initializing the table
$mySubs = $null                         # My Azure subscriptions that I have access to
$VMs = @()                              # VM Output table

#Get Azure subscriptions I have access to
Write-Host "Running script, this can take a couple of minutes, please be patient..." -ForegroundColor Green
Write-Host "Getting VMs..." -ForegroundColor Green  
$mySubs = Get-AzContext -ListAvailable
foreach ($sub in $mySubs.Subscription)
{
    Write-Output "`r`n"
    Write-Host "*** Going through subscription:" $sub.Name " ***" -ForegroundColor Green
    if ($VM.OsType -eq "Windows") {
        try
        {
            Set-AzContext -Subscription $sub.Name | Out-Null
            $myVMs = Get-AzVM
            #$myVMs.Name #remove comment character (#) to see VMs flow by

            foreach($VM in $myVMs)
            {
                try # check if the VM has the MMA extension, if not, we execute the catch part
                {
                    Get-AzVMExtension -ResourceGroupName $VM.ResourceGroupName -VMName $VM.Name -Name WindowsAgent.AzureSecurityCenter | Out-Null
                    $VMextensionInstalled = $true
                }

                catch # We did not find the MMA extension
                {
                    $VMextensionInstalled = $false
                }
                $VMproperties = New-Object psobject -Property @{
                    VMname = $VM.Name;
                    Location = $VM.Location;
                    ResourceGroup = $VM.ResourceGroupName;
                    SubscriptionName = $sub.Name;
                    SubscriptionID = $sub.ID;
                    VAExtensionInstalled = $VMextensionInstalled
                    OsType = $VM.StorageProfile.OsDisk.OsType
                }
                $VMs += $VMproperties
            }
        }
        catch{
            Write-Host "Could not get info for subscription: " $sub -ForeGroundColor Red
        }
    }
}

# Uncomment to view the VM table
# $VMs | Format-Table VMname, MMAExtensionInstalled, Location, ResourceGroup, SubscriptionName, SubscriptionID, OsType

# Export to output file
Write-Host "*** Creating Output file: " ($outputFolder + $outputFileName)  "***" -ForegroundColor Green
try {$VMs | Select-Object "VMname", "Location", "VAExtensionInstalled", "ResourceGroup", "SubscriptionName", "SubscriptionID", "OsType" | Export-Csv -Path ($outputFolder + $outputFileName) -Force -NoTypeInformation}
catch {Write-Host "Could not create output file.... Please your path, filename and write permissions." -ForeGroundColor Red}