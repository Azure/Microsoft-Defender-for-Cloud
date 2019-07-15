# This sample script enumerates through all your subscriptions you have access to #####
# and creates a CSV file with all recommendations across your subscriptions           #
# Prequisites:                                                                        #
# - Latest Az PowerShell module                                                       #
# - logged into to Azure (login-AzAccount)                                            #
# - output folder and filename                                                        #
#######################################################################################

$ErrorActionPreference = 'Stop'
$outputFolder = "<Your Output Folder>" # use format "c:\temp"
$outputFileName = "ASC-Recommendations.csv"
$Subscriptions = Get-AzSubscription
$RecommendationTable = @()

foreach($Subscription in $Subscriptions)
{
    Select-AzSubscription $Subscription.Id

    try
    {
        $SecurityTasks = Get-AzSecurityTask # get all recommendations from ASC

        foreach($SecurityTask in $SecurityTasks)
        {
            If([string]::IsNullOrEmpty($SecurityTask.ResourceId.Split("/")[8])) {  
            # resource field is empty, do nothing, since this is not actionable
            }
            
            else {
                $Recommendations = New-Object psobject -Property @{
                Recommendation = $SecurityTask.RecommendationType
                Resource = ($SecurityTask.ResourceId.Split("/")[8])
                SubscriptionName = $Subscription.Name
                SubscriptionId = ($SecurityTask.ResourceId.Split("/")[2])
                ResourceGroup = ($SecurityTask.ResourceId.Split("/")[4])
                }
                $RecommendationTable += $Recommendations
            }
        }
    }
    catch
    {
        Write-Host "Could not get recommendations for subscription: " $Subscription.Name -ForegroundColor Red
        Write-Output ("Error Message: " + $_.Exception.Message)
        Write-Host "Skipping subscription `r`n" -ForegroundColor Red
    }
}

Write-Host "*** Creating Output file: " ($outputFolder + "\" + $outputFileName)  "***" -ForegroundColor Green
try
{
    $RecommendationTable | Select-Object "SubscriptionName", "SubscriptionId", "Resource", "Recommendation", "ResourceGroup" | Export-Csv -Path ($outputFolder + "\" + $outputFileName) -Force -NoTypeInformation
    Write-Host "Done!" -ForegroundColor Yellow
}
catch {Write-Host "Could not create output file.... Please check your path, filename and write permissions." -ForeGroundColor Red}
