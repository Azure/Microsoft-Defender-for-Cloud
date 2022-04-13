<#  
.SYNOPSIS  
  Automation script to include ASC vulnerability assessment scan summary for provided image as a gate. 
  Check result and assess whether to pass security gate by findings severity.
     
.DESCRIPTION  
  Azure secuirty center (ASC) scan Azure container registry (ACR) images for known vulnerabilities on multiple scenarios including image push. 
 (https://docs.microsoft.com/en-us/azure/security-center/defender-for-container-registries-introduction#when-are-images-scanned)  
  Using this tool you can have a security gate as part of image release(push) or 
  deployment to cluster to check if for image there is existent scan in ASC (for example part following push) - retry ,
  And assess it's findings by configurable thresholds to decide whether to fail the gate - i.e the release/deployment.
  Script extracts provided ACR image digest, try to extract ASC scan summary using Azure resource graph AZ CLI module and check if result is healthy or not.
  If Healthy, will exit gate successfully, otherwise if unhealthy, 
  Check for any high findings or medium findings count suppress their thresholds to fail the gate, otherwise will set gate in warning mode.
  In case there's a major vulnerability in image, gate(script) will fail to allow exit in CI/CD pipelines.
  
  
.PARAMETER registryName
  [mandatory] 
  Azure container registry resource name image is stored.
.PARAMETER repository
  [mandatory] 
  It can be any EXISTING resource group, using the ASC default "DefaultResourceGroup-XXX" is one option.
  Note: Since the ASC VA solution is not an Azure resource it will not be listed under the resource group, but still it is attached to it.
.PARAMETER tag
  [mandatory] 
  The name of the new solution
.PARAMETER scanExtractionRetryCount
  [optional] 
  Max retries to get image scan summary from ASC. (Useful for waiting for scan result to finish following image push).
.PARAMETER mediumFindingsCountFailThreshold
  [optional] 
  Threshold to fail gate on Medium severity findings count in scan (default is 5)
  ** In the case of High servirty finging gate will always fail.**
.PARAMETER lowFindingsCountFailThreshold
  [optional] 
  Threshold to fail gate on Low severity findings count in scan (default is 15)
  ** In the case of High servirty finging gate will always fail.**
.PARAMETER ignoreNonPatchable
  [optional]
  Flag to set whether to fileter out non patchble findings from report (default is $false)
  
  
.EXAMPLE
	.\ImageScanSummaryAssessmentGate.ps1 -registryName <registryResourceName> -repository <respository> -tag <tag>

.EXAMPLE
	.\ImageScanSummaryAssessmentGate.ps1 -registryName tomerregistry -repository build -tag latest
 
.NOTES
   AUTHOR: Tomer Weinberger - Software Engineer at Microsoft Azure Security Center

#>

# Prerequisites
# Azure CLI installed
# Optional: Azure CLI Resource Grpah extension installed (installed as part of script)
Param(
	# Image registry name
	[Parameter(Mandatory=$true)]
	$registryName,
	
	# Image repository name in registry
   	[Parameter(Mandatory=$true)]
	$repository,
	
	# Image tag
   	[Parameter(Mandatory=$true)]
	$tag,
	
	# Max retries to get image scan summary from ASC.
	$scanExtractionRetryCount = 3,
	
	# Medium servrity findings failure threshold
	$mediumFindingsCountFailThreshold = 5,
	
	# Low servrity findings failure threshold
	$lowFindingsCountFailThreshold = 15,
	
	# Image tag
 	$ignoreNonPatchable = $false
)



az extension add --name resource-graph -y


$imageDigest = az acr repository show -n $registryName --image "$($repository):$($tag)" -o tsv --query digest
if(!$imageDigest)
{
	Write-Error "Image '$($repository):$($tag)' was not found! (Registry: $registryName)"
	exit 1
}

Write-Host "Image Digest: $imageDigest"

# All images scan summary ARG query.
$query = "securityresources
 | where type == 'microsoft.security/assessments/subassessments'
 | where id matches regex  '(.+?)/providers/Microsoft.ContainerRegistry/registries/(.+)/providers/Microsoft.Security/assessments/dbd0cb49-b563-45e7-9724-889e799fa648/'
 | extend registryResourceId = tostring(split(id, '/providers/Microsoft.Security/assessments/')[0])
 | extend registryResourceName = tostring(split(registryResourceId, '/providers/Microsoft.ContainerRegistry/registries/')[1])
 | extend imageDigest = tostring(properties.additionalData.imageDigest)
 | extend repository = tostring(properties.additionalData.repositoryName)
 | extend patchable = tobool(properties.additionalData.patchable)
 | extend scanFindingSeverity = tostring(properties.status.severity), scanStatus = tostring(properties.status.code)
 | summarize findingsCountOverAll = count(), scanFindingSeverityCount = countif(patchable or not(tobool($ignoreNonPatchable))) by scanFindingSeverity, scanStatus, registryResourceId, registryResourceName, repository, imageDigest
 | summarize findingsCountOverAll = sum(findingsCountOverAll), severitySummary = make_bag(pack(scanFindingSeverity, scanFindingSeverityCount)) by registryResourceId, registryResourceName, repository, imageDigest, scanStatus
 | summarize findingsCountOverAll = sum(findingsCountOverAll) , scanReport = make_bag_if(pack('scanStatus', scanStatus, 'scanSummary', severitySummary), scanStatus != 'NotApplicable')by registryResourceId, registryResourceName, repository, imageDigest
 | extend IsScanned = iif(findingsCountOverAll > 0, true, false)"
 
# Add filter to get scan summary for specific provided image
$filter = "| where imageDigest =~ '$imagedigest' and repository =~ '$repository' and registryResourceName =~ '$registryname'" 
$query  = @($query, $filter) | out-string 

Write-Host "Query: $query"

# Remove query's new line to use ARG CLI
$query = $query -replace [Environment]::NewLine,"" -replace "`r`n","" -replace "`n",""

# Get result wit retry policy
$i = 0
while(($result = az graph query -q $query -o json | ConvertFrom-Json).count -eq 0 -and ($i = $i + 1) -lt $scanExtractionRetryCount)
{ 
	Write-Host "No results for image $($repository):$($tag) yet ..."
	Start-Sleep -s 20
}

if(!$result -or $result.count -eq 0)
{
	Write-Error "No results were found for digest: $imageDigest after $scanExtractionRetryCount retries!"
	exit 1
}

if(!$result -or $result.count -gt 1)
{
	Write-Error "Too many rows returnes, unknown issue $imageDigest, investigate retunres result on top ARG"
	exit 1
}

# Extract scan summary from result
$scanReportRow = $result.data[0]
Write-Host "Scan report row: $($scanReportRow | out-string)"

if($scanReportRow.IsScanned -ne 1){
	Write-Error "Image not scanned, image: $imageDigest"
	exit 1
}

if ($ignoreNonPatchable)
{
  Write-Host "Notice: Filtering non patchble findings Flag is on! this will be cleared from $($scanReportRow.findingsCountOverAll) findinds overall"
  Write-Host ""
}


$scanReport = $scanReportRow.scanReport
Write-Host "Scan report $($scanReport | out-string)"

if($scanReport.scanstatus -eq "unhealthy")
{
	$scansummary = $scanReport.scanSummary
	# Check if there are major vulnerabilities  found - customize by parameters
	if($scansummary.high -gt 0 `
	-or $scansummary.medium -gt $mediumFindingsCountFailThreshold `
	-or $scansummary.low -gt $lowFindingsCountFailThreshold)
	{
		Write-Error "Unhealthy scan result, major vulnerabilities  found in image summary"
		exit 1
	}
	else
	{
		Write-Warning "Helathy scan result, as vulnerabilities found in image did not surpass thresholds"
		exit 0
	}
}
elseif($scanReport.scanstatus -eq "healthy"){
	Write-Host "Healthy Scan found for image!"
	exit 0
}
else{
	Write-Host "All non Applicable reuslts Scan -> default as all findings non applicable"
	exit 0
}





