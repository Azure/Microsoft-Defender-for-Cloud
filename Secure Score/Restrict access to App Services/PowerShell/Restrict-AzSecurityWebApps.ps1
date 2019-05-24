<#

.Synopsis

  Adds an Azure Ip restriction rule to an Azure App Service by doing the following steps

  1. Seeking all of your subscrptions within your tenant, looking for the following rule "Restrict access to App Services"
  2. You'll be prompted for the WebApp service that is too open, asking for the following required configurations

    A. Name
    B. Action ( "Alloy or Deny' )
    C. Priority
    D. IP address block

More information mentioned here : https://docs.microsoft.com/en-us/azure/app-service/app-service-ip-restrictions


.Requirements

  Az.Resources
  Az.Accounts
  Az.Security

.Known Issues
    
  AzureRM Module mixed in with Az Module will break scripting due to conflict of current migration

#>




Function Add-AzIpRestrictionRule {

    [CmdletBinding()]

    Param

    (

        # Name of the resource group that contains the App Service.

        [Parameter(Mandatory=$true, Position=0)]

        $ResourceGroupName, 



        # Name of your Web or API App.

        [Parameter(Mandatory=$true, Position=1)]

        $AppServiceName, 



        # rule to add.

        [Parameter(Mandatory=$true, Position=2)]
        
        [PSCustomObject]$rule
        
        
       

    )



    $ApiVersions = Get-AzResourceProvider -ProviderNamespace Microsoft.Web | 

        Select-Object -ExpandProperty ResourceTypes |

        Where-Object ResourceTypeName -eq 'sites' |

        Select-Object -ExpandProperty ApiVersions



    $LatestApiVersion = $ApiVersions[0]



    $WebAppConfig = Get-AzResource -ResourceType 'Microsoft.Web/sites/config' -ResourceName $AppServiceName -ResourceGroupName $ResourceGroupName -ApiVersion $LatestApiVersion



    $WebAppConfig.Properties.ipSecurityRestrictions =  $WebAppConfig.Properties.ipSecurityRestrictions + @($rule) | 

        Group-Object name | 

        ForEach-Object { $_.Group | Select-Object -Last 1 }



    Set-AzResource -ResourceId $WebAppConfig.ResourceId -Properties $WebAppConfig.Properties -ApiVersion $LatestApiVersion -Force    

}


Write-Verbose "Checking for Azure module..."

$AzModule = Get-Module -Name "Az.*" -ListAvailable

if ($AzModule -eq $null) {

    Write-Verbose "Azure PowerShell module not found"

    #check for Admin Privleges

    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

    if(-not ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))){

        #No Admin, install to current user

        Write-Warning -Message "Can not install Az Module.  You are not running as Administrator"

        Write-Warning -Message "Installing Az Module to Current User Scope"

        Install-Module Az -Scope CurrentUser -Force

        Install-Module Az.Security -Scope CurrentUser -Force

        Install-Module Az.Resources -Scope CurrentUser -Force

        Install-Module Az.Accounts -Scope CurrentUser -Force



    }

    Else{

        #Admin, install to all users

        Install-Module -Name Az -AllowClobber -Force

        Import-Module -Name Az.Accounts -Force

        Import-Module -Name Az.Security -Force

        Import-Module -Name Az.Resources -Force

    }

}

#Login to Azure

Login-AzAccount



#Get All Subs

$Subscriptions = Get-AzSubscription

Write-Host "Collecting Subscrptions within tenant. Note: Looking through each subscrption might take some time"

#Loop Through Subs

foreach($Subscription in $Subscriptions){

    $Id = ($Subscription.Id)

    Select-AzSubscription $Id | Out-Null

    #Get Security Task for App Services

    $SecurityTasks += Get-AzSecurityTask | Where-Object {$_.RecommendationType -eq "Restrict access to App Services"}

}

Write-Host "Found Active 'Restrict Access to App Services' within your subscrption"


foreach($SecurityTask in $SecurityTasks){

    Write-Host ($SecurityTask.ResourceId)

$RuleConfig = $host.ui.Prompt("Access Restrictions for the resource group mentioned above","Enter values for these settings:",@("ipAddress","action","priority","name","description"))


# Setting rule into a customobject for importation

$rule = [PSCustomObject]@{

    ipAddress = "$($RuleConfig.ipAddress)"

    action = "$($RuleConfig.action)"  

    priority = "$($RuleConfig.priority)" 

    name = "$($RuleConfig.name)" 

    description = "$($RuleConfig.description)"

 } 


Add-AzIpRestrictionRule -ResourceGroupName ($ResourceGroupName=$SecurityTask.ResourceId.Split("/")[4]) -AppServiceName ($AppServiceName=$SecurityTask.ResourceId.Split("/")[8]) -rule $rule
    


   
    



}

