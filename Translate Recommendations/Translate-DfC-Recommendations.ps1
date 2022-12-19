<#
.SYNOPSIS
    Translates a CSV export of Defender for Cloud recommendations to the language specified by the language code.
.DESCRIPTION
	Defender for Cloud (DfC) recommendations are frequently exported to CSV and distributed within an organisation to the teams that will remediate them.
	Recommendations are exported in English, and non-English speaking teams may need to match recommendations (via recommendation id) with their language-specific documentation pages to understand their meaning.
	This simple script automates the lookup and translation process by taking a CSV file of exported DfC recommendations as input and generating a new CSV as output with translated recommendation name and description.
	It does this translation via https://learn.microsoft.com/xx-yy/azure/defender-for-cloud/recommendations-reference, where xx-yy is the appropriate language code provided as input.
	By default, all input columns are preserved in the output CSV with translated columns ("recommendationDisplayName_" and "recommendationDescription_") appended.
	To select a subset of columns and choose their display order, modify the last 2 lines of the script accordingly.
.PARAMETER InFile
    Mandatory. The full path of the CSV export of Defender for Cloud recommendations.
.PARAMETER OutFile
    Optional. The full path to the translated CSV file. If omitted, a file with the language code as suffix will be created in the same folder as the input CSV.
.PARAMETER LanguageCode
    Mandatory. The language code to use (e.g. ja-JP for Japanese).
    See https://learn.microsoft.com/en-us/linkedin/shared/references/reference-tables/language-codes for the full list.
.PARAMETER StringComparison
    Optional. Determines how string operations are performed (see https://learn.microsoft.com/en-us/dotnet/api/system.stringcomparison?view=net-7.0).
	If omitted, "OrdinalIgnoreCase" will be used.
.EXAMPLE
    .\Translate-DfC-Recommendations.ps1 "C:\Temp\AzureSecurityCenterRecommendations_2022-12-12T00_41_36Z.csv" -LanguageCode ja-JP
	Will generate a new CSV file ("C:\Temp\AzureSecurityCenterRecommendations_2022-12-12T00_41_36Z_ja-JP.csv") with recommendation text in Japanese.
#>
[CmdletBinding()]  
param(
  [Parameter(Mandatory = $true)]
  [String]$InFile,
  [Parameter(Mandatory = $false)]
  [String]$OutFile,
  [Parameter(Mandatory = $true)]
  [ValidateSet("en-US", "ar-AE", "zh-CN", "zh-TW", "cs-CZ", "da-DK", "ms-MY", "nl-NL", "fr-FR", "fi-FI", "de-DE", "it-IT", "ja-JP", "ko-KR", "pl-PL", "pt-BR", "ro-RO", "ru-RU", "es-ES", "sv-SE", "th-TH", "tr-TR")]
  [String]$LanguageCode,
  [Parameter(Mandatory = $false)]
  [StringComparison]$StringComparison = 5
)

if (!(Test-Path $InFile -PathType Leaf))
{
  Write-Host "`nFile $($InFile) not found.`n" -ForegroundColor Red
  return
}
$inputSheet = Import-Csv $InFile

if (!$OutFile)
{
	$inputFile = Get-Item $InFile
	$OutFile = $inputFile.DirectoryName + "\" + $inputFile.BaseName + "_" + $LanguageCode + $inputFile.Extension
}

$output = @()
# $url = "https://raw.githubusercontent.com/MicrosoftDocs/azure-docs/main/includes/asc-recs-compute.md"
$url = "https://learn.microsoft.com/" + $LanguageCode + "/azure/defender-for-cloud/recommendations-reference"

$responseFile = Invoke-WebRequest $url
if ($responseFile.StatusCode -ne 200)
{
	Write-Host "`nUnable to retrieve $url`n" -ForegroundColor Red
	return
}

$response = $responseFile.Content
foreach ($row in $inputSheet)
{
	
	$recommendationGuid = $row.recommendationName
	if ($recommendationGuid)
	{
		$recTitle = ""
        $recDescription = ""
        
		# find the recommendation guid in the response
		$idxStart = $response.IndexOf($recommendationGuid, $StringComparison)
        if ($idxStart -gt 0)
		{
            # find the recommendationDisplayName
			$idxStart = $response.IndexOf(">", $idxStart, $StringComparison) + 1
            $idxEnd = $response.IndexOf("</a>", $idxStart, $StringComparison)
            $recTitle = $response.SubString($idxStart, $idxEnd - $idxStart)
            
			# find the recommendation description
			$idxStart = $response.IndexOf("<td>", $idxEnd, $StringComparison) + 4
            $idxEnd = $response.IndexOf("</td>", $idxStart, $StringComparison)
            $recDescription = $response.SubString($idxStart, $idxEnd - $idxStart)
        }
	    $row | Add-Member -MemberType NoteProperty -Name "recommendationDisplayName_" -Value $recTitle
        $row | Add-Member -MemberType NoteProperty -Name "recommendationDescription_" -Value $recDescription
        $output += $row
	}	
}

# customise the line below (and comment out the final line) to output the specific columns you want and the order to display them. Otherwise, all input columns are preserved with translated columns ("recommendationDisplayName_" and "recommendationDescription_") appended.
# $output | Select-Object -Property exportedTimestamp, subscriptionId, subscriptionName, resourceGroup, resourceType, resourceName, resourceId, recommendationId, recommendationName, recommendationDisplayName_, recommendationDescription_, remediationSteps, severity, state, notApplicableReason, firstEvaluationDate, statusChangeDate, controls, azurePortalRecommendationLink, nativeCloudAccountId, tactics, techniques, cloud, owner, eta, dueDate, gracePeriod | Export-Csv $OutFile -NoTypeInformation -Encoding Unicode
$output | Export-Csv $OutFile -NoTypeInformation -Encoding Unicode
