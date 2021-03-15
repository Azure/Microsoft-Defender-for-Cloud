
# Azure Defender extension - installation on Arc enabled Kubernetes clusters
In this repository you can find examples & setting configurations required for the installation of Defender extension on Arc enabled Kubernetes clusters, in case you would like to install the extension manualy. 
Otherwise there is an you can automatic installation via Azure Security Center the Azure Security Center portal under the "Azure Defender extension for Kubernetes should be installed on your Arc connected clusters" recommendation which has a "Quick Fix" button for your convenience. 

## Installation of Azure Defender extension with an ARM tamplate - try on portal
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https:%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Security-Center%2Ftree%2Fmaster%2FPricing%20%26%20Settings%2FDefender%20for%20Kubernetes%2FDefender%20extension%20installation%20examples%2Fazure-defender-extension-arm-template.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>

## Ensuring you're collecting the necessary events to your Kubernetes audit log

To provide runtime threat protection capabilities, the extension collects [Kubernetes audit logs](https://kubernetes.io/docs/tasks/debug-application-cluster/audit/) from your cluster. To validate you Kubernetes audit logs are configured correctly:

* If you've already enabled audit logs, use the audit_policy.yaml policy file in this repository to verify that you're collecting the necessary events for Azure Defender for Kubernetes. If audit logs are already enabled on your cluster, your cluster's audit configuration and settings will remain untouched.

* If you haven't enabled audit logs, they'll automatically be enabled during the installation of the Azure Defender for Kubernetes containerized agent. When audit logs are automatically enabled in your cluster, a backup is generated to provide you with rollback option.

In OpenShift, audit logs are enabled by default. In this case, audit logs policy will be automatically updated from ``Default`` to ``WriteRequestBodies``.
