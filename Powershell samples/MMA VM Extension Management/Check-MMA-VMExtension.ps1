#***************************************************************************************************************
# This script will enumerate through all your subscriptions and your Virtual Machines to report
# if the MMA extension has been installed.
# It creates a CSV output file which you can review and edit, which serves as an input file to 
# install the MMA extension in bulk.
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

$mySubs = Get-AzContext -ListAvailable
foreach ($sub in $mySubs.Subscription)
{
    Write-Host "Running script, this can take a couple of minutes, please be patient..." -ForegroundColor Green
    Write-Host "Trying to get VMs..." -ForegroundColor Green  
    Write-Output "`r`n"
    Write-Host "*** Going through subscription: " $sub.Name " ***" -ForegroundColor Green
    try{
        Set-AzContext -Subscription $sub.Name | Out-Null
        $myVMs = Get-AzVM
        #$myVMs.Name #remove comment character (#) to see VMs flow by

        foreach($VM in $myVMs)
        {
            try # check if the VM has the MMA extension, if not, we execute the catch part
            {
                $securedVMs = $securedVMs + (Get-AzVMExtension -ResourceGroupName $VM.ResourceGroupName -VMName $VM.Name -Name MicrosoftMonitoringAgent)

                $VMproperties = New-Object psobject -Property @{
                    VMname = $VM.Name;
                    Location = $VM.Location
                    ResourceGroup = $VM.ResourceGroupName;
                    SubscriptionName = $sub.Name;
                    SubscriptionID = $sub.ID;
                    MMAExtensioninstalled = "Yes"
                }
                $VMs += $VMproperties
            }
            catch # We did not find the MMA extension
            {
                $VMproperties = New-Object psobject -Property @{
                    VMname = $VM.Name;
                    Location = $VM.Location;
                    ResourceGroup = $VM.ResourceGroupName;
                    SubscriptionName = $sub.Name;
                    SubscriptionID = $sub.ID;
                    MMAExtensionInstalled = "No"
                }
                $VMs += $VMproperties
            }
        }
    }
    catch{
        Write-Host "Could not get info for subscription: " $sub -ForeGroundColor Red
    }
}

# Uncomment to view the VM table
# $VMs | Format-Table VMname, MMAExtensionInstalled, Location, ResourceGroup, SubscriptionName, SubscriptionID

# Export to output file
Write-Host "*** Creating Output file: " ($outputFolder + $outputFileName)  "***" -ForegroundColor Green
try {$VMs | Select-Object "VMname", "Location", "MMAExtensionInstalled", "ResourceGroup", "SubscriptionName", "SubscriptionID" | Export-Csv -Path ($outputFolder + $outputFileName) -Force -NoTypeInformation}
catch {Write-Host "Could not create output file.... Please your path, filename and write permissions." -ForeGroundColor Red}