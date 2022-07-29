<#
  .SYNOPSIS
  Will query resources for their own Security Subassessments

  .DESCRIPTION
  Will query resources for their own Security Subassessments

  .PARAMETER SubAssessmentLink
  Identifier for the subassessment

  .EXAMPLE
  Get-SecSubAssessment -SubAssessmentLink '/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Security/assessments/00000000-0000-0000-0000-000000000000/subAssessments'
#>
function Get-SecSubAssessment {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, ParameterSetName = 'SubAssessmentLink', ValueFromPipeline)]
    [ValidateNotNullOrEmpty()]
    [System.String[]] $SubAssessmentLink,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [System.String] $ApiVersion = 'api-version=2020-01-01'
  )

  begin {
    $output = [System.Collections.Generic.List[pscustomobject]]::new()
  }

  process {
    $token = (Get-AzAccessToken -ErrorAction Stop).Token

    $invokeRestMethodArgs = @{
      Header = @{'Authorization' = "Bearer $token" }
      Method = 'GET'
    }

    $SubAssessmentLink.ForEach{
      $subassessment = $_
      $invokeRestMethodArgs.Uri = 'https://management.azure.com{0}?{1}' -f $subassessment, $ApiVersion

      try {
        $subassessments = (Invoke-RestMethod @invokeRestMethodArgs).value
      } catch {
        if (-not ($_.ErrorDetails.Message | ConvertFrom-Json).Error.Code -eq 'AssessmentNotFound') {
          throw $_
        }
      }
      $subassessments.ForEach{
        $null = $output.Add($_)
      }
    }
  }

  end {
    $output
  }
}
