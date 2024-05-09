write-host '#####################################################################################################' -ForegroundColor green
write-host '#                                                                                                   #' -ForegroundColor green
write-host '#   This script will disable CSPM Cloud Posture for Subscriptions with Microsoft Defender for Cloud #' -ForegroundColor green
write-host '#   The script will then disable the CSPM plan on the subscriptions that are connected to your      #' -ForegroundColor green
write-host '#   az account.                                                                                     #' -ForegroundColor green
write-host '#                                                                                                   #' -ForegroundColor green
write-host '#####################################################################################################' -ForegroundColor green
write-host ''
#Requires -Version 7.0
# Declarations
#$now = Get-Date
Connect-AzAccount
if ($null -eq $(Get-AzContext)){Connect-AzAccount}
$Subscriptions = Get-AzSubscription 
try{
    foreach($sub in $Subscriptions){
        Set-AzContext -subscription $sub.id -ErrorAction Stop
        $Cloudposture=Get-AzSecurityPricing -Name Cloudposture
        if ($Cloudposture.PricingTier -eq "Standard")
        {
            $reply = Read-Host -Prompt "Continue?[y/n]"
            if ( $reply -eq 'y' ) { 
               Set-AzSecurityPricing -Name "CloudPosture" -PricingTier "Free"
            }
        }      
        $Cloudposture=Get-AzSecurityPricing -Name Cloudposture 
        if ($Cloudposture.PricingTier -eq "Free")
        {Write-Host "The subscription $sub.id Cloudposture state is Turned off"}
            }
}
catch{
    Write-Error "The script encountered an error"
}
