# Private Preview- Onboard your subscription to VM Scanners feature
This powershell script allows you to onboard your subscription to the VM Scanners feature.<br>
For the registration to the private preview, please make sure to sign up to this feature via the private community so your tenant can be onboarded to the preview.<br><br>
Exclusion tags are Azure tags which indicate us not to scan the resources that have one or more of these tags. By default, the script configures the new onboarding resource to have no exclusion tags. You can add as an argument to the script a dictionary with exclusion tags.

For example:
```csharp
./Onboard-VmScanners.ps1 -exclusionTags @{'scanning' = 'noscan'}
```

