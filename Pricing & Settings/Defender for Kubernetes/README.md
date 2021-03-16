# Azure Defender for Arc enabled Kubernetes - preview
In this section you can find code snippets & setting configurations required for Azure defender for Arc enabled Kubernetes private preview 

# Description
Azure Defender for Kubernetes is expanding its support from Azure Kubernetes Service to *any* Kubernetes cluster, leveraging Azure Arc enabled Kubernetes.

This preview brings the management layer threat detection capabilities that Azure Security Center offers today (through Azure Defender for Kubernetes) to Arc connected Kubernetes clusters.

## Architecture overview

Azure Defender for Kubernetes' ability to monitor and provide threat protection capabilities relies on an Azure Arc extension. The extension collects Kubernetes audit logs data from all control plane (master) nodes in the cluster and sends them to the Azure Defender for Kubernetes backend in the cloud for further analysis. The extension is registered with a Log Analytics workspace that's used as a data pipeline. The audit log data isn't stored in the Log Analytics workspace.

This is a high-level diagram outlining the interaction between Azure Defender for Kubernetes and the Azure Arc-enabled Kubernetes cluster:

![defender-for-kubernetes-architecture-overview](https://user-images.githubusercontent.com/62830936/111069341-4c6c5280-84d5-11eb-8df3-d52be7aae8ca.png)

## Ensuring you're collecting the necessary events to your Kubernetes audit log

To provide runtime threat protection capabilities, the extension collects [Kubernetes audit logs](https://kubernetes.io/docs/tasks/debug-application-cluster/audit/) from your cluster. To validate you Kubernetes audit logs are configured correctly:

* If you've already enabled audit logs, use the audit_policy.yaml policy file in this repository to verify that you're collecting the necessary events for Azure Defender for Kubernetes. If audit logs are already enabled on your cluster, your cluster's audit configuration and settings will remain untouched.

* If you haven't enabled audit logs, they'll automatically be enabled during the installation of the Azure Defender for Kubernetes containerized agent. When audit logs are automatically enabled in your cluster, a backup is generated to provide you with rollback option.

In OpenShift, audit logs are enabled by default. In this case, audit logs policy will be automatically updated from ``Default`` to ``WriteRequestBodies``.
