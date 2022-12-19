
# Translate Defender for Cloud Recommendations

## Overview
Translates a CSV export of Defender for Cloud recommendations to the language specified by the language code.

> Defender for Cloud (DfC) recommendations are frequently exported to CSV and distributed within an organisation to the teams that will remediate them.
Recommendations are exported in English, and non-English speaking teams may need to match recommendations (via recommendation id) with their language-specific documentation pages to understand their meaning.

> This simple script automates the lookup and translation process by taking a CSV file of exported DfC recommendations as input and generating a new CSV as output with translated recommendation name and description.
It does this translation via https://learn.microsoft.com/xx-yy/azure/defender-for-cloud/recommendations-reference, where xx-yy is the appropriate language code provided as input.

> By default, all input columns are preserved in the output CSV with translated columns ("recommendationDisplayName_" and "recommendationDescription_") appended.
To select a subset of columns and choose their display order, modify the last 2 lines of the script accordingly.

## Example

```powershell
# Generate a new CSV file ("C:\Temp\AzureSecurityCenterRecommendations_2022-12-12T00_41_36Z_ja-JP.csv") with recommendation text in Japanese.
.\Translate-DfC-Recommendations.ps1 "C:\Temp\AzureSecurityCenterRecommendations_2022-12-12T00_41_36Z.csv" -LanguageCode ja-JP

# Display full help.
Get-Help .\Translate-DfC-Recommendations.ps1 -Full

```
