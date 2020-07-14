Connect-AzAccount

$spID = (Get-AzADServicePrincipal -DisplayName "Get-ASCData").Id

$subs = Get-AzSubscription
foreach($sub in $subs){
    $subid = $sub.Id
    New-AzRoleAssignment -ObjectId $spID -RoleDefinitionName "Security Reader" -Scope "/subscriptions/$subid"
}