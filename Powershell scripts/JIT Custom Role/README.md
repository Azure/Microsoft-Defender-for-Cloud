## Creates least privileged custom Role for Azure Security Center Just-in-time access


 This script creates custom Role for Azure Security Center Just-in-time access for least privileged users.              
 Purposed for those wish to have users to be able to request access to VMs but not any other permissions.                                                              
 Usage:                                                                                      
 Set-JitLeastPrivilegedRole                                                                  
	-subscriptionId <Mandatory: subscription ID>                                              
	-roleName <Optional: default is "JIT Access Role">                                        
	-forApiOnly <Optional: if the requests are meant to initiate only from powershell/REST API
<br>
