# Get Security Assessment (Recommendation)

## Overview

This cmdlet is used as a wrapper of REST API. This cmdlet allows the user to query the assessment (`Microsoft.Security/assessments`) by its ID, also extensible to fetch sub-assessment object.

## Examples

```powershell
# Get specified assessments in all subscriptions
$getSecAssessmentparams = @{
        ResourceType     = 'Microsoft.Compute/virtualMachines'
        AssessmentId     = 'd1db3318-01ff-16de-29eb-28b344515626' # Log Analytics agent should be installed on virtual machines 
    }
Get-SecAssessment @getSecAssessmentparams

# Get specified assessments in specified subscription, extended to subassessments
$getSecAssessmentParams = @{
        SubscriptionId  = '00000000-0000-0000-0000-000000000000'
        ResourceType    = 'Microsoft.ContainerRegistry/registries'
        AssessmentId    = "dbd0cb49-b563-45e7-9724-889e799fa648" # Container registry images should have vulnerability findings resolved
    }
Get-SecAssessment @getSecAssessmentparams -SubAssessment
```
