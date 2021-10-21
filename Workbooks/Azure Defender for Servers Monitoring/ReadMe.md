# Azure Defender for Servers monitoring dashboard

**Author: Tom Janetscheck**

The new Azure Defender for Servers monitoring dashboard is a presentation of all machines, Azure VMs and non-Azure machines (connected through Azure Arc), that are covered by Azure Security Center. Besides Azure Defender coverage, and Log Analytics agent installation status, this custom workbook also considers if a machine is currently reporting (i.e. if it is connected and sending logs to its workspace).

## Try it on the Azure Portal

To deploy the new workbook into your Security Center console, click on *Deploy to Azure* for Azure Public cloud or *Deploy to Azure Gov* for government cloud.
During the deployment, you must select a subscription and resource group to store the report. Once the workbook is successfully deployed, however to Security Center to start using it.

<a href="https://aka.ms/AAe4g56" target="_blank"><img src="https://aka.ms/deploytoazurebutton"/></a>
<a href="https://aka.ms/AAe4g57" target="_blank"><img src="https://aka.ms/deploytoazuregovbutton"/></a>

![Dashboard demo](defmon.gif)
