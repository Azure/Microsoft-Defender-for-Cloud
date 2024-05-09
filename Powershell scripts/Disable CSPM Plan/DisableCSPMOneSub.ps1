write-host '#####################################################################################################' -ForegroundColor green
write-host '#                                                                                                   #' -ForegroundColor green
write-host '#   This script will disable CSPM Cloud Posture for Subscription with Microsoft Defender for Cloud. #' -ForegroundColor green
write-host '#   Please enter your Subscription ID. The script will then disable the CSPM plan on that           #' -ForegroundColor green
write-host '#   subscription.                                                                                   #' -ForegroundColor green
write-host '#                                                                                                   #' -ForegroundColor green
write-host '#####################################################################################################' -ForegroundColor green
write-host ''
#Requires -Version 7.0
# Declarations
#$now = Get-Date
#$subscriptionArray =@()
Connect-AzAccount
if ($null -eq $(Get-AzContext)){Connect-AzAccount}
$subId = Read-Host "Enter your Sub ID" 
try{
        Set-AzContext -subscription $subId -ErrorAction Stop
        $Cloudposture=Get-AzSecurityPricing -Name Cloudposture
            if ($Cloudposture.PricingTier -eq "Standard")
                {
                    Set-AzSecurityPricing -Name "CloudPosture" -PricingTier "Free"
                }      
        $Cloudposture=Get-AzSecurityPricing -Name Cloudposture 
            if ($Cloudposture.PricingTier -eq "Free")
               {
                    Write-Host "The subscription $subId Cloudposture state is Turned off"
               }
    }
catch{
    Write-Error "The script encountered an error"
}
