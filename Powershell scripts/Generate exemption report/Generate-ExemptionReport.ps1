#Requires -Modules @{ ModuleName="Az.Accounts"; ModuleVersion="2.2.8" }
<#  
.SYNOPSIS  
  This script will generate a detailed Azure Policy exemption report.
     
.DESCRIPTION  
  This script will look through all subscriptions for Azure Policy exemptions and will record the exmptions in a CSV report | It will also record ASCBuiltIn policies disabled from Default only at Subscription Scope
.NOTES
   AUTHOR: Nathan Swift - Security CSA 
   LASTEDIT: April 27, 2021 1.00
    - 1.00 change log: Created intial generation exemption report script

.LINK
    This script posted to and discussed at the following locations:
    https://github.com/Azure/Azure-Security-Center/tree/master/Powershell%20scripts
#>

# Prerequisites
# Install-module Az
# Install-module Az.security

#stamp for file run
$datetime = Get-Date -Format "MMyyddhhmmss"

#Path for report file
$currentlocation = Get-Location
$csvpath = $currentlocation.Path + "\ASCExemptionReport_" + $datetime + ".csv"
$outputFile = $csvpath

# write out headers of CSV
$exempstring = "SubscriptionName,SubscriptionId,ResourceName,ResourceType,ExmeptionName,Category,Notes,PolicyDefIds,CreatedBy,CreatedOn,ExpiresOn,ModifiedOn"
$exempstring | Out-File $outputFile -append -force

# gather all subscriptions
$subs = Get-AzSubscription

# For each subscription set contect and invoke REST GET policyExemptions API
Foreach ($sub in $subs){

    # Set subscription context and retrieve access token to work with exemption API
    $context = Set-AzContext -SubscriptionId $sub.Id
    $accessToken = (Get-AzAccessToken).token
    $requestHeader = @{
        "Authorization" = "Bearer " + $accessToken
        "Content-Type" = "application/json"
    }

    # ARM Call URL invoke REST GET policyExemptions API
    $armcall = "https://management.azure.com/subscriptions/" + $sub.Id + "/providers/Microsoft.Authorization/policyExemptions?api-version=2020-07-01-preview"

    # Make ARM Client call for GET policyExemptions API
    $exemptionaudits = Invoke-RestMethod -Uri $armcall -Method GET -Headers $requestHeader

    # Format exemptions table lists values
    $exemptionaudits = $exemptionaudits.value

    # for each table exemption item
    foreach ($exemptionaudit in $exemptionaudits) {
    
        # generate a variable for the Provider Type
        $providertype = $exemptionaudit.Id.split(“/”)[6]

        # generate a variable for the Resource name
        $resourcename = $exemptionaudit.Id.split(“/”)[8]

        #generate the table list entry into the report
        #"SubscriptionName,SubscriptionId,ResourceName,ResourceType,ExmeptionName,Category,Notes,PolicyDefIds,CreatedBy,CreatedOn,ExpiresOn"
        $exempstring = "$($sub.Name),$($sub.Id),$($resourcename),$($providertype),$($exemptionaudit.properties.displayName),$($exemptionaudit.properties.exemptionCategory),$($exemptionaudit.properties.description),$($exemptionaudit.properties.policyDefinitionReferenceIds),$($exemptionaudit.systemData.createdBy),$($exemptionaudit.systemData.createdAt),$($exemptionaudit.properties.expiresOn),"

        #Write into and append into output file
        $exempstring | Out-File $outputFile -append -force

    }

        # ASC policy Assignment works for the BuiltIn Policy Assignment per Subscription that was disabled by user
        $policyassign = (Get-AzPolicyAssignment -Name SecurityCenterBuiltIn).Properties
        $policyassignparams = (Get-AzPolicyAssignment -Name SecurityCenterBuiltIn).Properties.Parameters
        $policyassignparams = $policyassignparams.psobject.Properties

        # for each table diabled policy assignment item
        foreach ($policyassignparam in $policyassignparams) {

        #generate the table list entry into the report
        #"SubscriptionName,SubscriptionId,ResourceName,ResourceType,ExmeptionName,Category,Notes,PolicyDefIds,CreatedBy,CreatedOn,ExpiresOn"
        $exempstring = "$($sub.Name),$($sub.Id),,,$($policyassignparam.Name),$($policyassignparam.Value.value),,,$($policyassign.Metadata.assignedBy),$($policyassign.Metadata.createdOn),,$($policyassign.Metadata.updatedOn)"

        #Write into and append into output file
        $exempstring | Out-File $outputFile -append -force

    }

}