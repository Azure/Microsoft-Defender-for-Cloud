
# **Module 27 – Implementing Gated Deployment for Container Security**

<p align="left"><img src="../Images/asc-labs-intermediate.gif?raw=true"></p>

#### 🎓 Level: 200  

#### ⌛ Estimated time to complete: 1hr

#### 💁 Authors: Future Kortor

## Objectives

Runtime gated deployment refers to the process of evaluating container images against predefined security rules before they are allowed to be deployed within a Kubernetes environment. This approach acts as a checkpoint, or "gate," that ensures only images meeting specific security criteria, like having no vulnerabilities above a certain level, are allowed to be deployed.

The significance of gating lies in its ability to prevent insecure container images from entering production systems. By enforcing these security checks as part of the deployment workflow, organizations can reduce the risk of introducing vulnerabilities and maintain a strong security posture throughout the software development lifecycle. Gating mechanisms also help automate compliance with security policies, streamline audits, and provide greater visibility and control over what is being deployed in cloud-native environments.

Participants will learn how to implement vulnerability scanning and gating mechanisms to ensure the security and integrity of container images. By the end of the lab, participants will be able to:

1. Apply gating mechanisms to enforce security policies and prevent the deployment of insecure container images.
2. Demonstrate the use of audit and deny rules to manage and control the deployment of container images.
3. View artifacts created from Defender for Containers vulnerability scanning.

Learn more about securing Kubernetes deployments with gated container images: [Overview of Gated deployment](https://learn.microsoft.com/en-us/azure/defender-for-cloud/runtime-gated-overview).

For troubleshooting throughout this lab, visit [Troubleshoot Gated Deployment in Kubernetes](https://learn.microsoft.com/en-us/azure/defender-for-cloud/troubleshooting-runtime-gated).

For additional insights on gated deployment in Defender for Containers, consider viewing the [FAQ](https://learn.microsoft.com/en-us/azure/defender-for-cloud/faq-runtime-gated).

## Prerequisites

- This lab will demonstrate gated deployment on Azure, though the feature can also be implemented on AWS and GCP as well. An Azure subscription with owner permission is required for the lab. Defender for Containers must be enabled on the subscription including the following toggles:

![](../Images/lab27-34.png?raw=true)

Ensure that Security Findings is turned on as part of “Registry access” and Security Gating is also turned on as part of the “Defender sensor” toggle.

- An Azure Kubernetes Service (AKS) cluster attached to an Azure Container Registry (ACR). AKS must be on version 1.31 or higher.
- Creating or changing gated deployment policies requires Security Admin or higher tenant permission.
- [AZ command-line](https://learn.microsoft.com/en-us/cli/azure/authenticate-azure-cli-interactively), [kubectl](https://kubernetes.io/docs/tasks/tools/), [JQ](https://jqlang.org/download/) and [ORAS](https://oras.land/docs/installation/) command-line installed on your local machine.

Learn more about how to enable gated deployment in Defender for Containers: [Enable Gated Deployment](https://learn.microsoft.com/en-us/azure/defender-for-cloud/enablement-guide-runtime-gated)

---

## Exercise 1: Create and view audit rules for your Kubernetes Cluster

First, we will create a security rule for the Kubernetes cluster. A security rule defines what images can be deployed to the cluster based on certain conditions within a defined scope. Defender for Containers employs an admission controller along with the vulnerability findings artifact to assess deployments in accordance with applicable security rules within the defined scope. The action taken by the admissions controller is either audit (deploy the container and notify that the image is non-compliant) or deny (no deployment and notify that the image is non-compliant). In this exercise, we will start by creating an audit rule.

1. Go back to the Environment settings page in Defender for Cloud and click on Security Rules.
2. In Gated deployment, select Vulnerability assessment. Note that an out-of-the-box audit rule is already included.
3. Click on Add rule. Create a rule name. Ensure that the Action is set to Audit, and the Cloud scope includes the Kubernetes Cluster you would like to test for this lab. You can narrow the scope to specific Kubernetes entities like pod names or deployments, preventing this rule from affecting other cluster activity.

![](../Images/lab27-4.png?raw=true)

![](../Images/lab27-5.png?raw=true)

4. Click Next, set the Rule conditions; in this case, we will set the rule for High severity threshold higher than 0. meaning the rule will audit deployments with more than zero high seveirty vulnerabilities. While the rule is presently set to Audit mode, it will be updated to block deployments that do not include vulnerability findings artifact. This approach ensures that only images which have undergone scanning and possess the necessary artifact are deployed, effectively reducing risks associated with unverified images.

![](../Images/lab27-6.png?raw=true)

5. Resource based exemptions on various levels such as registry, image digest and namespace can be applied on the next screen. Exemptions for vulnerabilities can also be applied in addition to an expiration date.

![](../Images/lab27-35.png?raw=true)

6. Each rule created as part of the Gated Deployment capability is translated into a security artifact policy within the Kubernetes Cluster. After creating the rule, we can check for the security artifact policy on the cluster.

7. Open PowerShell on your machine and log in to the Azure subscription and Kubernetes cluster using the following:

   ```
   az login
   ```

   A window will open for you to log into the Azure Portal.

   ```
   az account set --subscription $subscriptionID
   az aks get-credentials –resource-group $resroucegroup –name $clustername –overwrite-existing
   ```

8. Now view the security artifact:

   ```
   kubectl get securityartifactpolicies -o json
   ```

- In the output, you should see the name of the rule we previously created as well as the Default rule. The security artifact policy may take a few minutes to appear after rule creation.

![](../Images/lab27-7.png?raw=true)

---

## Exercise 2: View the security artifact created in your Azure Container Registry

Security findings must be enabled in Defender for Containers to meet this lab's prerequisites. This feature generates a security artifact for each image pushed to the registry. Defender for Cloud checks the security artifact against the cluster’s policy before deployment. Consider Module 9 to see how to pull a vulnerable image into the ACR.

1. Navigate to the Azure portal.
2. Search for Container Registries, then select your ACR.
3. Click Services, then Repositories and select your vulnerable repository.
4. Click Referrers to see if an artifact has been created. If this is a new image, it may take a few minutes after scanning is complete.

![](../Images/lab27-28.png?raw=true)

5. You can view artifact created for your image using JQ. Select the artifact. In the manifest, you will notice a layer for the security artifact attestation. Note the digest.
   
   ![](../Images/lab27-39.png?raw=true)

6. Open PowerShell on your machine and run the following:

   ```
   az acr login –-name $registryname
   oras blob fetch $artifactURI -o va-attachment.json
   cat va-attachment.json | jq
   ```

  The artifactURI should include the same digest viewed in the manifest. The attestation will open in-toto format as shown in the example below.

![](../Images/lab27-29.png?raw=true)
---

## Exercise 3: Run the vulnerable image on your AKS cluster

Use the kubectl run command to deploy the vulnerable image. Note that you should be deploying the image itself, not the artifact from Exercise 2:

```
kubectl run $podname --image=$imageuri
```

It should deploy with an error message that the deployment violates the rule previously created. We will later track the event in Exercise 5.

![](../Images/lab27-36.png?raw=true)

---

## Exercise 4: Create, view and run deny rules for your Kubernetes Cluster

Now that we’ve seen how to create an audit rule, let’s look at how to create a deny rule and view the updated security artifact policy on the Kubernetes cluster.

1. Go back to the Defender for cloud portal and navigate to the Security Rules.
2. Click the rule created in Exercise 1 then Edit rule.
3. Change the rule action from Audit to Deny. Update the description and click next. Keep the conditions the same and save the rule.

![](../Images/lab27-8.png?raw=true)

4. Open PowerShell, if you are not logged in to the cluster, re-run the command from Exercise 1, step 7.
5. Now view the updated security artifact policy:

   ```
   kubectl get securityartifactpolicies -o json
   ```

   Notice that the policy action has changed from Audit to the Deny in the security artifact policy.

![](../Images/lab27-9.png?raw=true)

With the policy updated from Audit to Deny, let us examine how Defender for Cloud will prevent deployment.

6. Deploy a new pod with the same image using the command from Exercise 3. Defender should provide an error message which shows the deployment was blocked.

![](../Images/lab27-37.png?raw=true)

---

## Exercise 5: View the gating events

Defender for Cloud captures each audit or deny event that occurs on the cluster. In this step, we will view the events in the Defender for Cloud portal. Note that it can take up to 20 minutes for the gating rule to become visible.

View the gating event:

1. Go to the Defender for cloud portal and select environment settings then Security Rules.
2. Under Gated deployment, select Admission Monitoring. You should see both the audit event and deny event. Select either event.
3. Aside from the admission action, the event includes a timestamp, the rule name, violation and image digest that violated the rule.

![](../Images/lab27-38.png?raw=true)

