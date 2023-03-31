# GuestConfiguration Result v1.7

This workbook gives an overview to GuestConfiguration results and machine configuration. Azure Arc is fully included.
All data is queried by the Azure Resource Graph (ARG) and has no dependencies to Microsoft Defender for Cloud generated data. 


The workbook provides different sections:

**By Policy**
*	Compliance by Subscription
*	Compliance by Computer Azure and Arc
*	Computer Details
*	Stale Reporting
*	GC Compliance Details, Reason and Reason Code per Check-up 

**Resource View**
* View from a Resource perspective  (independent of GC Result in ARG backend)
* OS/SKU overview by Azure/Arc VMs
* Overview by GC Policy, including VMs not sent a report (no checking whether policy is assigned)

**By Computer**
* Platform, SKU and Offer Overview
* Compliance by Platform and SKU
* Computer Overview

**Policy Details**
* Definition Details, Standalone or Initiative mapped
* Active Assignments

**Extensions**
* Installed and missing Extensions

**Identity**
* Installed and missing Identities

## Try on Portal
You can deploy the workbook by clicking on the buttons below:

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkbooks%2FGuestConfiguration%20Result%2FarmTemplate.json" target="_blank"><img src="https://aka.ms/deploytoazurebutton"/></a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkbooks%2FGuestConfiguration%20Result%2FarmTemplate.json" target="_blank"><img src="https://aka.ms/deploytoazuregovbutton"/></a>



##
![GC Policy Overview](./gc_overview.png)

** **

![GC Policy Reasons](./gc_reasons.png)

** **

![Resource View](./gc_resourceview.png)

** **

![Computer](./computerdetails.png)

** **
![GC Policy Assignments](./policy_assingment.png)

** **
![Extensions](./gc_extensions.png)

** **
![Identity](./gc_identity.png)

