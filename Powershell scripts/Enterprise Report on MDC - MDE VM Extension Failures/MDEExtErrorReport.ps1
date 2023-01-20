#---------------------------------------------------------------------------------------------------
# Script to generate a .csv report of failed MDE. VM Extensions, useful for filtering and grouping
#---------------------------------------------------------------------------------------------------

# Outputfile for MDE extension error report

$path = "C:\temp\mdeextreport.txt"
$csvpath = "C:\temp\mdeextreport.csv"
$outputFile = $path

#Set and apply 1st line of csv headers
$string = "VM Name,VM Extension,VM Extension Status,VM Extension Error,VM Extension Detailed Errors"
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
        $vm = Get-AzVm -ResourceGroupName $vm.ResourceGroupName  -Name $vm.Name -Status

        # conditional check for VM if it has MDE extension
        if($vm.Extensions.Name -match "MDE"){

            # set variable for status level of MDE extension
            $level = ($vm.Extensions | where-Object {($_.Name -match "MDE")}).Statuses.level

            # if the mde extension is not successful then generate a entry in the report for the vm and informnationa round mde extension
            if($level -ne "Info"){
            
                # future build for sub status detailed errors, is in a list, would need to foreach and join into a single string with a unique delimiter
                $SubMessages = ($vm.Extensions | where-Object {($_.Name -match "MDE")}).Substatuses.message

                #generate entry for report
                $string = "$($vm.Name), $(($vm.Extensions | where-Object {($_.Name -match "MDE")}).Name), $(($vm.Extensions | where-Object {($_.Name -match "MDE")}).Statuses.level), $(($vm.Extensions | where-Object {($_.Name -match "MDE")}).Statuses.Message)"               
                
                #output entry into report
                $string | Out-File $outputFile -append -force
            
            }
        
        }    
    
    }

}

# Once done import the data into excel

$CSV = Import-Csv -Path $path
$CSV | Export-Csv -Path $csvpath -NoTypeInformation