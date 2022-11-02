$VMs = Get-AzVM $WindowsVMs = $VMs | Where-Object { $PSItem.StorageProfile.ImageReference.Offer -eq "WindowsServer" }
foreach ($VM in $WindowsVMs) {    $extension = Get-AzVMExtension -ResourceGroupName $Vm.ResourceGroupName -VMName $VM.Name
if ($extension.Name -contains "MicrosoftMonitoringAgent") {        Write-Host "Microsoft Monitoring Agent is Installed on" $VM.Name
Start-AzVM -ResourceGroupName $Vm.ResourceGroupName -Name $VM.Name
Remove-AzVMExtension -ResourceGroupName $Vm.ResourceGroupName -Name "MicrosoftMonitoringAgent" -VMName $VM.Name
}    }
