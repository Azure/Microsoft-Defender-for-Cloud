# Samples for remediating "DDoS Protection Standard should be enabled"
These samples provide various ways to resolve the "*DDoS Protection Standard should be enabled*" recommendation in Azure Security Center. There are four samples:
* **PowerShell script** - will loop through and remediate each instance 
    * Requires the Azure (Az) and Azure Security (Az.Security) PowerShell modules
* **Logic App Playbook** - No sample was created due to complexity of VNET API.
* **Azure Policy definitions**
    * Deny Policy - It is not recommended to use this since not all VNETs will be
    internet connected and won't require DDOS.
    * deployIfNotExist Policy - It is not recommend as Policy is not iterative 
    and you need to discover VNETs, then discover if they are public facing to 
    apply DDOS.
