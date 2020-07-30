## Creates a least-privileged custom role for Azure Security Center's just-in-time VM access features

This script creates a custom role for Azure Security Center's just-in-time virtual machine access for least-privileged users.

The goal is to enable users to request JIT access to VMs but give them no other Security Center permissions.

Usage:                                                                                      

```
Set-JitLeastPrivilegedRole                                                                  
	-subscriptionId <Mandatory: subscription ID>                                              
	-roleName <Optional: default is "JIT Access Role">                                        
	-forApiOnly <Optional: if the requests are meant to initiate only from powershell/REST API>
```
