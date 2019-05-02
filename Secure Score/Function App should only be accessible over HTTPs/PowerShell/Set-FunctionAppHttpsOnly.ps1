#login-AzAccount
$websites = Get-AzWebApp
foreach($website in $websites){
    Set-AzWebApp -ResourceGroupName $website.ResourceGroup -Name $website.Name  -HttpsOnly $true 
}