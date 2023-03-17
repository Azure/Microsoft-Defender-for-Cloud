#######################################################################################
# This sample script allows you to export affected components from your kubernetes    #
# clusters and creates a CSV file with your affected components across your           #
# environment. Prerequisites:                                                                      #
# - Latest Az PowerShell module                                                       #
# - logged into to Azure (login-AzAccount)                                            #
# - output folder and filename                                                        #
#######################################################################################
# Params
#$subId = 'XXXXXXXX-YYYY-ZZZZ-AAAA-QQQQQQQQQQQQ' # use your sub id 
$subId = Read-Host "Enter your Sub ID" 
$policyDefinitionId = '/providers/Microsoft.Authorization/policyDefinitions/febd0533-8e55-448f-b837-bd0e06f16469'
#Definition ID febd0533-8e55-448f-b837-bd0e06f16469 = Kubernetes cluster containers should only use allowed images 
#Defintion ID can be replaced with any other definition id from the policy defintion. 
$ErrorActionPreference = 'Stop'
$outputFolder = "c:\Tmp" # use format "c:\temp"
$outputFileName = "AffectedComponents.csv"
$RecommendationTable = @()
$RecommendationName
$values = @()

# Variables:
$azureSecurityBenchmarkAssignment = "/subscriptions/$subId/providers/Microsoft.Authorization/policyAssignments/SecurityCenterBuiltIn"
$RecommendationName= Get-AzPolicyDefinition -SubscriptionId $subid -Builtin | Where-Object{$_.PolicyDefinitionId -eq $policyDefinitionId} | Select-Object -ExpandProperty Properties | Select-Object DisplayName
# Get all clusters
$clustersIds = az rest -m get -u "https://management.azure.com/subscriptions/$subId/providers/Microsoft.ContainerService/managedClusters?api-version=2022-11-01" --query "value[*].id" -o tsv
# Iterate all clusters
try {
   
foreach ($clusterId in $clustersIds) {
    Write-Host "Finding affected components in cluster: $clusterId"
        $query = "https://management.azure.com$clusterId/providers/Microsoft.PolicyInsights/policyStates/latest/queryResults?api-version=2019-10-01&`$filter=policyAssignmentId eq '$azureSecurityBenchmarkAssignment' and policyDefinitionId eq '$policyDefinitionId'&`$expand=components(`$filter=complianceState eq 'NonCompliant' and type ne '*')"
    $affectedcomponents = az rest -m post -u $query --query "value[0].components" -o tsv 
    #$affectedcomp = az rest -m post -u $query --query "value[0].components" -o table
    # Iterate affected components
    if ($affectedcomponents -ne $null)
    {
    foreach ($component in $affectedcomponents){
        $values = $component -split '\s+'
        $Recommendations = New-Object psobject -Property @{
            ClusterID = $clusterId
            RecommendationName = $RecommendationName.DisplayName
            Compliant = $values[0]
            Namespace = $values[1]
            PodName = $values[2]
            Date = $values[3]
            type = $values[4]
       }
       $RecommendationTable += $Recommendations
        Write-Host "Affected component: $component"
    }
    }
}      
}
catch {
     Write-Host "Error Message: " $_.Exception.Message -ForeGroundColor Red
}

try
{
    $RecommendationTable | Select-Object "ClusterID", "RecommendationName", "Compliant", "Namespace", "PodName", "Date", "type" | Export-Csv -Path ($outputFolder + "\" + $outputFileName) -Force -NoTypeInformation
    Write-Host "Done! `r`n" -ForegroundColor Yellow
}
catch {Write-Host "Could not create output file.... Please check your path, filename and write permissions." -ForeGroundColor Red}