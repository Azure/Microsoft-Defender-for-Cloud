# Module 25 - Defender for Cloud and XDR Integration

<p align="left"><img src="../Images/asc-labs-intermediate.gif?raw=true"></p>

#### 🎓 Level: 200 (Intermediate)
#### ⌛ Estimated time to complete this lab: 1-2 hours

#### 💁💁‍♀️ Author:  
Giulio Astori [Github](https://github.com/gastori), [Linkedin](https://www.linkedin.com/in/giulioastori)

## Objectives  
This lab is designed to demonstrate the integration between **Microsoft Defender for Cloud (MDC)** and **Extended Detection and Response (XDR)** to provide a comprehensive **Cloud Detection and Response (CDR)** solution. Participants will explore how MDC detects and protects containerized workloads and how XDR unifies telemetry from multiple sources to enable seamless investigation and response.  

This lab is structured into five key steps:  

1. **Setting up the Environment:**  
   - Deploy an Azure Kubernetes Service (AKS) cluster.  
   - Enable and configure Defender for Containers in Microsoft Defender for Cloud.  
   - Validate that the environment is ready for attack simulation.  

2. **Deploying the Attack Simulation:**  
   - Set up the attacker and victim pods using a Helm chart.  
   - Understand the role of each component in simulating container threats.  

3. **Running Individual and Combined Attack Scenarios:**  
   - Execute various attack scenarios, such as reconnaissance, lateral movement, secrets gathering, and cryptomining.  
   - Observe the behaviors and results of these simulated attacks.  

4. **Observing and Analyzing MDC Alerts:**  
   - Explore how Microsoft Defender for Cloud generates security alerts in response to the simulated attacks.  
   - Understand the threat insights and remediation recommendations provided by MDC.  

5. **Correlating and Responding to Incidents Using XDR:**  
   - Investigate alerts in Microsoft 365 Defender and correlate them with telemetry from other sources (e.g., endpoints, identities).  
   - Execute response actions to contain and mitigate threats, leveraging the unified XDR interface.  

By the end of this lab, participants will be able to:  

1. **Understand Integration:**  
   - Grasp how Microsoft Defender for Cloud and XDR work together to provide seamless detection, investigation, and response workflows.  

2. **Simulate Threats:**  
   - Execute simulated attack scenarios to observe how MDC detects and reports container-specific threats.  

3. **Explore Alert Correlation:**  
   - Learn how XDR aggregates alerts from multiple telemetry sources into actionable incidents.  

4. **Perform Response Actions:**  
   - Use XDR tools to investigate and mitigate threats effectively, minimizing potential damage.  

5. **Showcase Value Proposition:**  
   - Highlight how the MDC-XDR integration accelerates threat detection, provides enriched threat context, and simplifies incident response.  

## Who Should Attend?  
This lab is designed for:  

- **Security Operations Teams:** Enhance their knowledge of threat detection and incident response.  
- **Cloud Security Professionals:** Learn how to secure environments using MDC.  
- **SOC Analysts:** Gain hands-on experience with XDR and its integration with MDC to streamline threat investigation and mitigation.  

## Step 1: Setting Up the Environment

### 1.1 Prerequisites

Ensure the following before starting:

- Azure Subscription with Microsoft Defender for Containers enabled
- Azure Cloud Shell (preferred) or a local environment with:
  - Azure CLI: For managing Azure resources
  - Kubernetes CLI (kubectl): For managing Kubernetes clusters
  - Helm CLI (v3.7.0 or later): For deploying resources using Helm charts

**Improvement:**
- If using Azure Cloud Shell, note that all required tools are pre-installed, simplifying the setup.

### 1.2 Create an AKS Cluster

Run the following commands to create a Kubernetes cluster in Azure:

```bash
# Set variables - note: you can use these value or use your own
RESOURCE_GROUP="DefenderLabRG"
CLUSTER_NAME="DefenderLabAKS"
LOCATION="eastus"

# Create a resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create an AKS cluster
az aks create --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --node-count 1 --enable-managed-identity --generate-ssh-keys
```

**Validation:**
- Verify the cluster is running:
  ```bash
  az aks list --resource-group $RESOURCE_GROUP --output table
  ```
  Look for the Succeeded provisioning state in the output.

- Ensure you can connect to the cluster:
  ```bash
  az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME
  kubectl get nodes
  ```
  The `kubectl get nodes` command should return the status of the node(s) in the cluster as Ready.

**Notes:**
- If `kubectl` cannot connect, ensure the `az aks get-credentials` command was successful and the cluster is in a healthy state.

### 1.3 Enable Defender for Containers

1. Navigate to Microsoft Defender for Cloud in the Azure portal.
2. Go to Environment Settings > Select your subscription > Defender Plans.
3. Enable Microsoft Defender for Containers by toggling the plan.

**Validation:**
- Confirm the AKS cluster appears under:
  - Environment Settings > Azure Kubernetes Service in Defender for Cloud
- Ensure that Defender for Containers is shown as Enabled for the subscription

**Notes:**
- (Optionally) Command to validate the Defender plan status:
  ```bash
  az security pricing list --query "[?name=='ContainerRegistry'].pricingTier"
  ```
  Expected output for the container plan should be "Standard".

## Local Computer Requirements (optional)

## 1. Tools Installation

Ensure the following tools are installed and properly configured on your local computer:

### 1.1 Azure CLI

**Installation:**
- For Windows: [Azure CLI installation](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows)
- For macOS/Linux: [Azure CLI installation](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)

**Validate installation:**
```bash
az version
```
The output should display the installed version.

### 1.2 Kubernetes CLI (kubectl)

**Installation:**
- Follow the official Kubernetes documentation to install kubectl for your operating system: [Install kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

**Validate installation:**
```bash
kubectl version --client
```
The output should show the client version.

### 1.3 Helm CLI (v3.7.0 or later)

**Installation:**
- Follow the official Helm documentation to install Helm: [Install Helm](https://helm.sh/docs/intro/install/)

**Validate installation:**
```bash
helm version
```
The output should display the installed version.

### 1.4 Additional Recommended Tools

**Git (Optional):**
- Required if cloning GitHub repositories
- [Git installation](https://git-scm.com/downloads)

**Curl or Wget:**
- Required for downloading files if Git is not used

**Validate curl installation:**
```bash
curl --version
```

**OR Validate wget installation:**
```bash
wget --version
```

## 2. Azure Authentication

### 2.1 Login to Azure

Log in to Azure using the CLI:
```bash
az login
```
- This will open a browser for authentication or prompt for a device login code
- After successful login, it displays your subscription details

### 2.2 Set Subscription

Set the correct subscription:
```bash
az account set --subscription "<SubscriptionNameOrID>"
```
Ensures that all subsequent commands are run in the right Azure subscription

## 3. AKS Cluster Authentication

Retrieve cluster credentials:
```bash
az aks get-credentials --resource-group <ResourceGroupName> --name <ClusterName>
```
- This adds the cluster's kubeconfig to your local `~/.kube/config` file

**Validate connectivity:**
```bash
kubectl get nodes
```
The output should show the AKS nodes in a Ready state

## Additional Notes

- If your local machine doesn't meet these requirements, use Azure Cloud Shell, which has all tools pre-installed
- Ensure stable internet connectivity for downloading tools, interacting with Azure, and pulling Helm charts
- Recommended: Keep all tools updated to their latest versions

## Step 2: Deploying the Attack Simulation

### 2.1 Clone the GitHub Repository (Optional)

If you want to access all scripts and configuration files locally:

```bash
git clone https://github.com/microsoft/Defender-for-Cloud-Attack-Simulation.git
cd Defender-for-Cloud-Attack-Simulation
```

> **Note**: Cloning the repository is optional. If you prefer, you can simply download the simulation.py script as described below.

### 2.2 Download the Simulation Tool

If you don't clone the repository, download the simulation.py script directly:

```bash
curl -O https://raw.githubusercontent.com/microsoft/Defender-for-Cloud-Attack-Simulation/main/simulation.py
```

Ensure that the file has been downloaded:

```bash
ls simulation.py
```

You should see `simulation.py` in the output.

> **Notes**: If the download fails, check your internet connection or ensure that curl is installed.

## Step 3: Running Individual and Combined Attack Scenarios

### 3.1 Point kubeconfig to the Target Cluster

For Azure Kubernetes Service (AKS), run:

```bash
az aks get-credentials --name <cluster-name> --resource-group <resource-group>
```

Validate connectivity to the cluster:

```bash
kubectl get nodes
```

The output should list the nodes in a Ready state.

> **Note**: If you're managing multiple clusters, ensure the correct cluster is set in your kubeconfig before proceeding:
> ```bash
> kubectl config use-context <context-name>
> ```

### 3.2 Verify Defender for Containers and Defender Sensor

1. Ensure Microsoft Defender for Containers is enabled in Microsoft Defender for Cloud.
2. Check that the Defender sensor is installed in the AKS cluster by running:

```bash
kubectl get ds microsoft-defender-collector-ds -n kube-system
```

Expected output:
```
NAME                             DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
microsoft-defender-collector-ds 1         1         1       1            1           <none>          Xh
```

> **Notes**: If the microsoft-defender-collector-ds daemonset is missing or not running, confirm that Defender for Containers is enabled in Environment Settings > Azure Kubernetes Service in Defender for Cloud.

### 3.3 Run the Simulation Script

Execute the simulation.py script to run individual or combined attack scenarios:

```bash
python3 simulation.py
```

Select an attack scenario from the menu or choose the option to simulate all scenarios.

### Available Simulated Scenarios and Expected Alerts

| Scenario | Expected Alerts |
|----------|-----------------|
| Reconnaissance | - Possible Web Shell activity detected<br>- Suspicious Kubernetes service account operation detected<br>- Network scanning tool detected |
| Lateral Movement | - Possible Web Shell activity detected<br>- Access to cloud metadata service detected |
| Secrets Gathering | - Possible Web Shell activity detected<br>- Sensitive files access detected<br>- Possible secret reconnaissance detected |
| Cryptomining | - Possible Web Shell activity detected<br>- Kubernetes CPU optimization detected<br>- Command within a container accessed ld.so.preload<br>- Possible Crypto miners download detected<br>- A drift binary detected executing in the container |
| Web Shell | - Possible Web Shell activity detected |

### Validation

After selecting a scenario, check the logs of the attacker pod (run this command from another shell terminal):

```bash
kubectl logs mdc-simulation-attacker -n mdc-simulation
```

1. Verify that the attack simulation executed successfully.
2. Navigate to Microsoft Defender for Cloud > Security Alerts in the Azure portal to view the generated alerts.

> **Notes**: If the simulation fails, check the attacker pod logs for errors:
> ```bash
> kubectl logs mdc-simulation-attacker -n mdc-simulation
> ```

> **Final Note**: The script is designed to simulate realistic container threats in a controlled environment. Ensure you do not run these simulations on production systems. At the end of the simulation you will be prompted to '**Run another scenario? (Y/N)**'. 

> ![Mod 25 Security Alerts](../Images/mod.25.simulation.end.png?raw=true)

> Depending on which scenario you have executed, you might run additional ones. It is reccommended to run all for a full end-to-end lab experience. Once done you can select '**N**' to complete the simulation script. The script is designed to delete the 2 images/pods and related Namespace once done. If you wish to interact with the images/pods as they are running, it is recommended to not terminate the script (perhaps if you decide to test remediation actions).

## Azure Defender Cloud Security Alert Analysis Guide

### Step 4: Observing and Analyzing MDC Alerts

### 4.1 Review Security Alerts

1. Navigate to Microsoft Defender for Cloud > Security Alerts in the Azure portal.

2. Review the alerts generated from the attack simulation:
   - Example alerts include:
     * "Cryptocurrency mining container detected"
     * "Suspicious Kubernetes API access"
     * "Sensitive data accessed"
   - Alerts will indicate which specific resources (e.g., attacker/victim pods) were affected.

3. Use the search bar to filter alerts by cluster name or affected resources for easier identification. You should see a list of Alerts as per the image below.

![Mod 25 Security Alerts](../Images/mod.25.sec.alerts.png?raw=true)

### 4.2 Analyze Alert Details

1. Click on an alert to open its details pane.

2. Review the following information:
   - **Description**: Provides an overview of the detected threat and its potential impact.
   - **Severity**: Indicates how critical the alert is (High, Medium, or Low).
   - **Affected Resources**: Lists resources impacted by the threat (e.g., Kubernetes pods or nodes).
   - **Suggested Remediation Steps**: Offers actionable guidance to address the threat, such as patching or isolating the resource.

### Validation

- Ensure each attack scenario generates the expected alerts in Microsoft Defender for Cloud.
- Use the table from Step 3.3 to cross-check the alerts for each scenario.

### Troubleshooting Tip

If no alerts are generated:
- Verify that the Defender sensor is installed and running:
  ```bash
  kubectl get ds microsoft-defender-collector-ds -n kube-system
  ```
- Confirm the AKS cluster is properly protected in MDC under Environment Settings > Azure Kubernetes Service.

### Step 5: Correlating and Responding to Incidents Using XDR

### 5.1 Correlate Alerts in Microsoft 365 Defender

1. Navigate to Microsoft 365 Defender > Incidents & Alerts in the Microsoft 365 Defender portal.

2. Search for incidents or alerts corresponding to the container-based threats detected by MDC:
   - Look for incidents related to:
     * Cryptomining activity
     * Web shell activity
     * Kubernetes metadata access

![Mod 25 Security Alerts](../Images/mod.25.xdr.inc.png?raw=true)

3. Click on an incident to view its details, including:
   - **Correlated Alerts**: Shows how the alert relates to others across telemetry sources (e.g., MDC, Defender for Endpoint, Defender for Identity).
   - **Incident Description**: Provides an overview of the attack chain.

![Mod 25 Security Alerts](../Images/mod.25.xdr.inc.2.png?raw=true)

### 5.2 Investigate the Incident

1. Open the incident and review the following:
   - **Attack Timeline**: Displays the sequence of events that occurred during the attack simulation.
   - **Affected Entities**: Lists impacted resources, such as specific containers, pods, or endpoints.
   - **Threat Context**: Explains how this threat correlates with other alerts (e.g., combining MDC's Kubernetes telemetry with Defender for Endpoint's runtime behavior analysis).

2. Use the available investigation tools in Microsoft 365 Defender:
   - **Advanced Hunting**: Run queries to dig deeper into specific events or behaviors associated with the incident.
   - **Automated Investigation**: Review automated investigation results to identify suspicious behaviors and root causes.

### 5.3 Take Response Actions

1. From the incident details, perform response actions directly in the XDR interface:
   - **Isolate the Affected Container**:
     Slect the affected container and click '**Actions**', then you can select to isolate or terminate the Pod. 
     ![Mod 25 Security Alerts](../Images/mod.25.xdr.actions.png?raw=true)

     Alternatively, you can do it manually by scale it down or cordon the affected Kubernetes nodes:
     ```bash
     kubectl cordon <node-name>
     kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
     ```

   - **Disable Compromised Credentials**:
     If sensitive files were accessed (e.g., .git-credentials), revoke the associated credentials immediately.

   - **Block Malicious IPs**:
     Add suspicious IPs detected in MDC to the firewall or network security group (NSG) deny list.

2. Monitor the incident resolution status in Microsoft 365 Defender.

### Final Notes

- **Near Real-Time Alerts**:
  - Some alerts, such as Web Shell activity, are generated in near real-time.
  - Others, like cryptomining, may take up to an hour to appear in Defender for Cloud.

### Validation

- Verify that incidents generated in Microsoft 365 Defender correlate correctly with alerts from MDC.
- Ensure response actions (e.g., isolation, blocking) are successfully executed.


## **Introduction to Advanced Hunting**

In this section, we dive into **Advanced Hunting** using **KQL (Kusto Query Language)** to gain deeper insights into the simulated attack scenarios executed in the lab. By leveraging advanced hunting capabilities, we can effectively trace attacker actions, correlate them with victim activities, and generate a comprehensive timeline of events.

This approach is particularly useful for:

1. **Forensic Analysis**:
   - Understanding the techniques used by the attacker (e.g., reconnaissance, lateral movement, cryptomining).
   - Identifying how the victim environment responds to those attacks.

2. **Incident Correlation**:
   - Linking attacker activities (e.g., `curl` commands targeting the webshell) with the processes spawned on the victim pod (`php-fpm`).
   - Tracing the full attack chain across the Kubernetes environment.

3. **Threat Validation**:
   - Validating the security alerts generated by Microsoft Defender for Cloud (MDC) and their alignment with observed activity.
   - Highlighting gaps, if any, in detection mechanisms.

### **Key Focus Areas**

1. **Attacker Behavior Analysis**:
   - Investigating the attack techniques initiated by the `attacker` pod, including the use of tools like `curl`, `nmap`, and `xmrig`, as well as attempts to access sensitive data.

2. **Victim Activity Monitoring**:
   - Tracking suspicious processes executed on the `victim` pod, such as commands spawned by `php-fpm` via the webshell or attempts to access Kubernetes secrets.

3. **Correlation of Events**:
   - Joining attacker and victim activities to establish a clear link between malicious inputs and their outcomes, ensuring a holistic understanding of the attack simulation.

### **Why Advanced Hunting Matters**

Advanced hunting allows security teams to move beyond predefined alerts and explore raw telemetry data. This capability is critical for:
- Uncovering subtle attack patterns.
- Correlating cross-source data for enriched context.
- Generating actionable insights to improve detection and response mechanisms.

In the following queries, you’ll learn how to:
1. Analyze specific attack actions from the `attacker` pod.
2. Monitor the response and suspicious processes on the `victim` pod.
3. Correlate attacker and victim activities into a unified timeline for actionable reporting.

Let’s start by examining attacker actions and move toward comprehensive correlation between attacker and victim activities.


## Detailed Queries
### Query Usage Guidance
1. **Attacker-Centric Query**: 
   - Perform initial forensic analysis of attacker techniques.

2. **Victim-Centric Query**: 
   - Understand the victim's response and identify compromised resources.

3. **Correlation Query**: 
   - Generate an attack timeline to understand end-to-end activity.

### 1. Attacker-Centric Query - Identify Attacker Actions

The first step in advanced hunting is to analyze the behavior of the attacker pod in the Kubernetes environment. This involves identifying processes, tools, and commands executed as part of the simulated attack scenarios. By focusing on the attacker pod, we gain visibility into the techniques and tools used during reconnaissance, lateral movement, secrets gathering, and cryptomining activities.

**Objective**: Trace all actions initiated by the attacker pod (attacker). Use the following query to identify all relevant commands executed within the attacker pod, such as curl, nmap, xmrig, and attempts to access sensitive files.

**What This Query Does:**

Filters events for the namespace `mdc-simulation` and the pod containing "attacker."
Identifies processes executed by the attacker pod that are relevant to the simulated scenarios:
* `curl`: Used for webshell invocation (e.g., HTTP requests to `ws.php`).
* `nmap`: Used for network reconnaissance.
* `xmrig`: A cryptomining binary.
* `.git-credentials`: Indicates attempts to gather secrets.
* `cmd=`: Signals possible command injection.

**Expected Outcome:**
A list of processes executed in the attacker pod, including their timestamps, commands, and process names.

```kusto
CloudProcessEvents
| where KubernetesNamespace == "mdc-simulation" and KubernetesPodName contains "attacker"
| where ProcessCommandLine has_any ("curl", "nmap", "xmrig", "cmd=", ".git-credentials")
| project Timestamp, ProcessName, ProcessCommandLine, KubernetesNamespace, KubernetesPodName, AccountName
| order by Timestamp desc
```

**Usage**:
- Use this to identify all attack attempts and techniques initiated by the attacker pod.
- Provides a focused view on attack behavior for forensic analysis.

### 2. Victim-Centric Query - Monitoring Victim Activity

The next step is to analyze the behavior on the victim pod, focusing on suspicious activity such as commands executed via the webshell, attempts to access Kubernetes secrets, or modification of critical files. By monitoring the php-fpm process (the parent of webshell commands), we can attribute victim-side activity directly to the attacker's inputs.

**Objective**: Monitor suspicious activity in the victim pod (victim), particularly those executed by php-fpm.

**What This Query Does:**

Filters events for the namespace `mdc-simulation` and the pod containing "victim."
Focuses on:
* Processes spawned by the php-fpm parent process (webshell activity).
* Commands likely linked to secrets access or privilege escalation.
* Sensitive file modifications (e.g., Kubernetes tokens or preload files).

**Expected Outcome:**
A list of suspicious processes and file access activities on the victim pod.

```kusto
CloudProcessEvents
| where KubernetesNamespace == "mdc-simulation" and KubernetesPodName contains "victim"
| where ParentProcessName == "php-fpm"
   or ProcessCommandLine has_any ("cmd=", ".git-credentials", "nmap", "xmrig", "curl", "sudo", "chmod", "setcap")
   or FileName has_any ("/var/run/secrets/kubernetes.io/serviceaccount/token", "/etc/ld.so.preload")
   or ActionType == "FileModified"
| project Timestamp, ProcessName, ProcessCommandLine, ParentProcessName, FileName, FolderPath, KubernetesNamespace, KubernetesPodName, AccountName
| order by Timestamp desc
```

**Usage**:
- Focuses on activities within the victim pod, identifying processes spawned by php-fpm or accessing sensitive files.
- Provides insight into how the victim reacts to the attacker's actions.

### 4. Correlation Query for Attacker and Victim Activities
To establish a unified view of the attack, correlate the actions performed by the attacker pod (e.g., curl to ws.php) with processes executed on the victim pod (e.g., commands spawned by php-fpm).

**Objective**: Link attacker curl commands with victim php-fpm processes.

**What This Query Does:**

This query correlates attacker commands (curl requests) with victim-side activity (processes spawned by php-fpm) in the mdc-simulation namespace, enabling you to establish a clear relationship between the attacker's actions and their impact on the victim pod.

**Expected Outcome:**
The output provides a correlated view of the attacker's curl requests (targeting the victim webshell) and the processes executed on the victim pod as a result of those requests.

```kusto
let AttackerActions = CloudProcessEvents
| where KubernetesNamespace == "mdc-simulation" and KubernetesPodName contains "attacker"
| where ProcessCommandLine has "curl" and ProcessCommandLine has "ws.php"
| project AttackerTimestamp = Timestamp, AttackerCommandLine = ProcessCommandLine, TargetURL = extract("http[s]?://([^/]+)", 1, ProcessCommandLine), KubernetesNamespace, KubernetesPodName;

let VictimObservations = CloudProcessEvents
| where KubernetesNamespace == "mdc-simulation" and KubernetesPodName contains "victim"
| where ParentProcessName == "php-fpm"
| project VictimTimestamp = Timestamp, VictimCommandLine = ProcessCommandLine, VictimPodName = KubernetesPodName, VictimParentProcess = ParentProcessName, KubernetesNamespace;

AttackerActions
| join kind=inner (VictimObservations) on KubernetesNamespace
| where TargetURL contains VictimPodName
| order by AttackerTimestamp desc
```

**Usage**:
- Best suited for correlating curl requests with PHP webshell commands in attack simulations.
- Demonstrates attacker-victim interaction and validates the simulation flow.

## Context and Recommendations

### Why Use php-fpm as a Focal Point?
- Since all commands executed via the webshell originate from php-fpm, it's critical for tracing attacker-victim interactions.
- This parent-child process relationship allows attribution of malicious activity to specific attacker commands.

