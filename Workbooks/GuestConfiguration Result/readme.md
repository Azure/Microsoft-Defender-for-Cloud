# GuestConfiguration Result

This workbook gives an overview to GuestConfiguration results and machine configruation. Azure Arc is fully included.
All data is queried by the Azure Resource Grapsh (ARG) and has no dependencies to Microsoft Defender for Cloud generated data. The initiative mapping to Defender makes sense :-) but is not required.

The workbook provides different sections:

**By Policy**
*	Compliance by Subscription
*	Comliance by Computer Azure and Arc
*	Computer Details
*	GC Compliance Details, Reason and Reason Code per Checkup 

**By Computer**
* Platform, SKU and Offer Overview
* Compliance by Plattofrm and SKU
* Computer Overview

**Policy Details**
* Definition Details, Standalone or Initative mapped
* Active Assignments

**Agents and Identity**
* Installed Extensions
* Installed Identity

## Try on Portal
You can deploy the workbook by clicking on the buttons below:

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkbooks%2FASC%20Recommendations%20Graph%2FarmTemplate.json" target="_blank"><img src="https://aka.ms/deploytoazurebutton"/></a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Fmaster%2FWorkbooks%2FASC%20Recommendations%20Graph%2FarmTemplate.json" target="_blank"><img src="https://aka.ms/deploytoazuregovbutton"/></a>

##
![GC Policy Overview](./gc_overview.png)
![GC Policy Reasons](./gc_reasons.png)

** **
![Computer](./computerdetails.png)

** **
![GC Policy Assignments](./policy_assingment.png)

** **
![Extensions and Identites](./agent_identity.png)

