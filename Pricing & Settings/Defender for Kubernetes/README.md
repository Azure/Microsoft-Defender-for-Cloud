# Azure Defender for Arc enabled Kubernetes - Private Preview
In this section you can find code snippets & setting configurations required for Azure defender for Arc enabled Kubernetes private preview 

# Description
Azure defender for Kubernetes is expanding its support from AKS to any Kubernetes cluster, leveraging Azure Arc for Kubernetes. The preview offers parity between the threat detection capabilities that ASC has today in AKS and brings these capabilities to Arc connected Kubernetes clusters.

# Register for the preview 

Members of our private preview program can sign up in [here](https://forms.office.com/Pages/ResponsePage.aspx?id=v4j5cvGGr0GRqy180BHbR29qPXYA7fJFpXjPCSwLwsNUNjVHR0ZVQzEwOEtMWFkxWFVSQzc3MVo5MC4u). 

# Ensuring you're collecting the necessary events to your Kubernetes audit log

Azure Defender for Kubernetes needs to collect your Kubernetes audit logs to analyze them for runtime threat protection capabilities.

To ensure they're setup as required before installing the Azure Defender for Kubernetes containerized agent (for private preview purpuses only):

* If you've already enabled audit logs, use the audit_policy.yaml policy file in this repository to verify that you're collecting the necessary events for Azure Defender for Kubernetes. If audit logs are already enabled on your cluster, your cluster's audit configuration and settings will remain untouched.

* If you haven't enabled audit logs, they'll automatically be enabled during the installation of the Azure Defender for Kubernetes containerized agent. When audit logs are automatically enabled in your cluster, a backup is generated to provide you with rollback option.

[!NOTE] In OpenShift, audit logs are enabled by default.

* To manually enable Kubernetes audit logs, before Azure Defender for Kubernetes agent installation follow the steps in Manually enable audit logs.
