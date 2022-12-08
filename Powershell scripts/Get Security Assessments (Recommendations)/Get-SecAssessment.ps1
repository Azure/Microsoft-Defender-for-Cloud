<#
  .SYNOPSIS
  Will query resources for their own Security assessments

  .DESCRIPTION
  Will query security assessments on certain resource types

  .PARAMETER AssessmentId
  Guid for a security assessment can be found in Microsft Defender for Azure

  .PARAMETER ResourceId
  A single resource ID to query the Security Assessment against

  .PARAMETER ResourceType
  A resource type to query the Security Assessment against (ie.: Microsoft.Compute/virtualMachines)

  .PARAMETER SubscriptionId
  Subscription ID(s) where the resources are located

  .PARAMETER Status
  Statuses to query for (ie.: Healthy, Unhealthy)

  .PARAMETER ApiVersion
  Apiversion that you want to query against

  .PARAMETER SubAssessment
  Returns subassessments if available

  .EXAMPLE
  Get-SecAssessment -AssessmentId 'd1db3318-01ff-16de-29eb-28b344515626' -ResourceType 'Microsoft.Compute/virtualMachines'
#>
function Get-SecAssessment {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [System.Guid]$AssessmentId,

    [Parameter(Mandatory, ParameterSetName = 'ResourceId')]
    [ValidateNotNullOrEmpty()]
    [System.String]$ResourceId,

    [Parameter(Mandatory, ParameterSetName = 'ResourceType')]
    [ValidateNotNullOrEmpty()]
    [System.String]$ResourceType,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [System.Guid[]] $SubscriptionId,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [System.String[]] $Status = @('Unhealthy'),

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [System.String]$ApiVersion = 'api-version=2020-01-01',

    [Parameter()]
    [switch] $SubAssessment
  )

  begin {
    $azGraphArgs = @{}

    if ($SubscriptionId) {
      $azGraphArgs.Subscription = $SubscriptionId.Guid
    }

    if ($PSCmdlet.ParameterSetName -eq 'ResourceId') {
      $resources = Search-AzGraph -Query "resources | where id =~ '$ResourceId'" @azGraphArgs
    } else {
      $resources = Search-AzGraph -Query "resources | where type =~ '$ResourceType'" @azGraphArgs
    }

    $output = [System.Collections.Generic.List[pscustomobject]]::new()
  }

  process {
    $token = (Get-AzAccessToken -ErrorAction Stop).Token

    $invokeRestMethodArgs = @{
      Header = @{'Authorization' = "Bearer $token" }
      Method = 'GET'
    }

    $resources.ForEach{
      $resource = $_
      $invokeRestMethodArgs.Uri = 'https://management.azure.com{0}/providers/Microsoft.Security/assessments/{1}?{2}' -f $resource.id, $AssessmentId, $ApiVersion

      try {
        $assessment = (Invoke-RestMethod @invokeRestMethodArgs)
      } catch {
        if (-not ($_.ErrorDetails.Message | ConvertFrom-Json).Error.Code -eq 'AssessmentNotFound') {
          throw $_
        }
      }

      if ($assessment.properties.additionalData.subAssessmentsLink -and $SubAssessment) {
        $subAssessments = Get-SecSubAssessment -SubAssessmentLink $assessment.properties.additionalData.subAssessmentsLink
      }

      if ($subAssessments) {
        $subAssessments.Where{ $_.properties.status.code -in $Status }.ForEach{ $null = $output.Add($_) }
      } elseif ($assessment) {
        $assessment.Where{ $_.properties.status.code -in $Status }.ForEach{ $null = $output.Add($_) }
      }
    }
  }

  end {
    $output
  }
}
