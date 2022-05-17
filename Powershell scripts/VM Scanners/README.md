# Private Preview- Onboard your subscription to VM Scanners feature
This powershell script allows you to onboard your subscription to the VM Scanners feature.<br>
For the registration to the private feature, your tenant has to be whitlisted by MDC for onboarding.<br><br>
Exclusion tags are Azure tags which indicate us not to scan the resources that have one or more of these tags. By default, the script configures the new onboarding resource to have no exclusion tags. You can add as an argument to the script a dictionary with exclusion tags.

For example:
```csharp
./Onboard-VmScanners.ps1 -exclusionTags @{'scanning' = 'noscan'}
```

