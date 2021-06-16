# Scheduled automation

When using automation tools other than Azure Policy, customers need to ensure that commands and scripts run on a regular basis to keep their resources secure and their configurations up to date.

The following table lists different options on how to run an automation regularly:
Automation	| Options
--- | ---
Azure PowerShell	| 1)	Use Azure Functions <br /> 2)	Use Azure Automation <br /> 3) Use Azure DevOps and a scheduled pipeline with an Azure PowerShell task
Azure CLI	| Use Azure DevOps and a scheduled pipeline with an Azure CLI task.
Azure REST API	| 1)	Use a scheduled Logic App <li>Trigger: Recurrence (e.g., once per day)</li><li> Action: HTTP Request</li> 2)	Use Azure DevOps and a scheduled pipeline
