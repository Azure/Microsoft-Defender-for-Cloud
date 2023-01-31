﻿﻿#---------------------------------------------------------------------------------------------------
# Script to generate a .csv report of failed MDE. VM Extensions, useful for filtering and grouping
#---------------------------------------------------------------------------------------------------

# Outputfile for MDE extension error report thresholds

$path = "C:\temp\mdeextreport.txt"
$csvpath = "C:\temp\mdeextreport.csv"
$outputFile = $path

#Set and apply 1st line of csv headers
# FUTURE # ,VM Extension Detailed Errors
$string = "Subscription,VM Name,VM Extension,OS,VM Extension Status,Error Code,Error Description,VM Extension Error, VM Extension Error Details"
$string | Out-File $outputFile -append -force

# get all subscriptions
$Subs = Get-AzSubscription


# for each subscription get all the VMs and their status
foreach($sub in $subs){

    # set a particular subscription context to search for VMs
    Set-AzContext -Subscription $Sub.Id

    # get all the VMs in Subscription including status
    $vms = Get-AzVM

    #For each VM check for MDE.windows or MDE.Linux extension and if in a error state record information to csv
    foreach($vm in $vms){

        #get particular extension details of VM
        $vme = Get-AzVm -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status

        # conditional check for VM if it has MDE extension
        if($vme.Extensions.Name -match "MDE"){

            # set variable for status level of MDE extension
            $level = ($vme.Extensions | where-Object {($_.Name -match "MDE")}).Statuses.level

            # if the mde extension is not successful then generate a entry in the report for the vm and informnationa round mde extension
            if($level -ne "Info"){
            
                # future build for sub status detailed errors, is in a list, would need to foreach and join into a single string with a unique delimiter
                $SubMessages = ($vme.Extensions | where-Object {($_.Name -match "MDE")}).Substatuses.message

                $modstring = $SubMessages.Split('')
                $modstring = $modstring.Split("'`n'")
                $modstring = $modstring.Split("'`t'")
                $modstring = $modstring.Split("'`r'")
                $modstring = $modstring.Split('`,')

                $code = (($vme.Extensions | where-Object {($_.Name -match "MDE")}).Statuses.message).split(' ')[16]

                # Define Hashtables for switch lookup rather than IF
                $codedesc = switch ($code) 
                    { 
	                    1 {"ERR_INTERNAL"}
                        2 {"ERR_INVALID_ARGUMENTS"}
                        3 {"ERR_INSUFFICIENT_PRIVILAGES"}
                        4 {"ERR_NO_INTERNET_CONNECTIVITY"}
                        5 {"ERR_CONFLICTING_APPS"}
                        10 {"ERR_UNSUPPORTED_DISTRO"}
                        11 {"ERR_UNSUPPORTED_VERSION"}
                        12 {"ERR_INSUFFICIENT_REQUIREMENTS"}
                        20 {"ERR_MDE_NOT_INSTALLED"}
                        21 {"ERR_INSTALLATION_FAILED"}
                        22 {"ERR_UNINSTALLATION_FAILED"}
                        23 {"ERR_FAILED_DEPENDENCY"}
                        24 {"ERR_FAILED_REPO_SETUP"}
                        25 {"ERR_INVALID_CHANNEL"}
                        26 {"ERR_FAILED_REPO_CLEANUP"}
                        30 {"ERR_ONBOARDING_NOT_FOUND"}
                        31 {"ERR_ONBOARDING_FAILED"}
                        40 {"ERR_TAG_NOT_SUPPORTED"}
                        41 {"ERR_PARAMETER_SET_FAILED"}
                        default {"ERR_UNKNOWNCODE"}
                    }

                #generate entry for report
                $string = "$($sub.Name),$($vme.Name), $(($vme.Extensions | where-Object {($_.Name -match "MDE")}).Name), $($vm.StorageProfile.ImageReference.sku), $(($vme.Extensions | where-Object {($_.Name -match "MDE")}).Statuses.level), $($code), $($codedesc), $(($vme.Extensions | where-Object {($_.Name -match "MDE")}).Statuses.Message), $($modstring)"               
                
                #output entry into report
                $string | Out-File $outputFile -append -force
            
            }
        
        }    
    
    }

}

# Once done import the data into excel

$CSV = Import-Csv -Path $path
$CSV | Export-Csv -Path $csvpath -NoTypeInformation