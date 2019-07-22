$nics = Get-AzNetworkInterface
foreach($nic in $nics){
$nic.EnableIPForwarding = 1
Set-AzNetworkInterface -NetworkInterface $nic
}