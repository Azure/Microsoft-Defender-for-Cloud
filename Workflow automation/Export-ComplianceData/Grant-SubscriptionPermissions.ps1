Connect-AzAccount

$spID = (Get-AzADServicePrincipal -DisplayName "Get-ComplianceState").Id

$subs = Get-AzSubscription
foreach($sub in $subs){
    $subid = $sub.Id
    New-AzRoleAssignment -ObjectId $spID -RoleDefinitionName "Security Reader" -Scope "/subscriptions/$subid"
}