$publicSettings = @{"workspaceId" = "Add_your_workspaceID"}
$protectedSettings = @{"workspaceKey" = "Add_Your_WorkspaceKey"}


$scaleSets = Get-AzVmss -ResourceGroupName $ResourceGroupName -VMScaleSetName $VMScaleSetName
$scaleSets = Get-AzVmss 

foreach ($scaleSet in $scaleSets)
{
#check if the MMA agent is already install
if($scaleSet.VirtualMachineProfile.ExtensionProfile.Extensions.name -contains "MicrosoftMonitoringAgent"){
write-host agent on $scaleSet.Name is already installed no action was taken -ForeGroundColor yellow 

}
else
{
write-host agent on $scaleSet.Name  is not installed -ForeGroundColor Green

#checking if this is Windows VM
if($scaleSet.VirtualMachineProfile.StorageProfile.ImageReference.Offer -match "Windows"){
  Write-Host "Installing VMSS Extension of type Windows ....please wait..." -ForeGroundColor Green
   Add-AzVmssExtension -VirtualMachineScaleSet $scaleSet -Name MicrosoftMonitoringAgent -Publisher "Microsoft.EnterpriseCloud.Monitoring" -Type "MicrosoftMonitoringAgent" -TypeHandlerVersion 1.0 -AutoUpgradeMinorVersion $True -Setting $publicSettings -ProtectedSetting $protectedSetting  

}
else{
 Write-Host "Installing VMSS Extension of type Linux ....please wait..." -ForeGroundColor Green
Add-AzVmssExtension -VirtualMachineScaleSet $scaleSet -Name MicrosoftMonitoringAgent -Publisher "Microsoft.EnterpriseCloud.Monitoring" -Type "OmsAgentForLinux" -TypeHandlerVersion 1.7 -AutoUpgradeMinorVersion $True -Setting $publicSettings -ProtectedSetting $protectedSetting

}
Update-AzVmss -ResourceGroupName $scaleset.ResourceGroupName -VMScaleSetName $scaleset.Name -VirtualMachineScaleSet $scaleset
}
}
