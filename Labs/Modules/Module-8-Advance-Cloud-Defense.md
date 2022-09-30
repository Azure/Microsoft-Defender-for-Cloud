# Module 8 – Enhanced Security

<p align="left"><img src="../Images/asc-labs-advanced.gif?raw=true"></p>

#### 🎓 Level: 300 (Advanced)
#### ⌛ Estimated time to complete this lab: 60 minutes

## Objectives
In this exercise, you will understand how to use just-in-time (JIT) for virtual machines to reduce your attack surface. Moreover, you will understand the benefits of file integrity monitoring (FIM).

### Exercise 1: Using JIT to reduce attack surface

1.	From Microsoft Defender for Cloud sidebar, click on **Workload Protections**.
2.	On the Advanced protection part at the bottom, click on **Just-in-time VM access** (You should see 2 unprotected status).

![Advanced protection options](../Images/asc-defender-advanced-protection-jit.gif?raw=true)

3.	On the Just-in-time VM access page, select the **Not configure** tab. You should see at least two virtual machines listed: `asclab-linux` and `asclab-win`.
4.	Select **asclab-win** and then click on the **Enable JIT on 1 VM** button.

![Enable JIT on Windows VM](../Images/asc-enable-jit-win-vm.jpg?raw=true)

5.	On the JIT VM access configuration, keep just the **3389 (RDP) port** and delete others.  
![JIT VM access configuration](../Images/asc-jit-vm-access-config.gif?raw=true)
6.	Click **Save** to apply the VM access configuration.
7.	Review the **Configured** tab, now you should see your VM configured: `asclab-win`.
8.	On the Azure portal sidebar, click on **Virtual Machines**.
9.	Click on **asclab-win**.
10.	From the top menu, click on **Connect** button and then select **RDP**.

![Windows VM - Connect RDP](../Images/asc-win-vm-connect-rdp.gif?raw=true)

11.	Return to the VM blade. On the Connect page, request JIT access. On the **Source IP**, select **My IP** and then click on **Request access**. You should now see the following message: *Download file*.

![](../Images/lab8download.gif?raw=true)
12.	Try to connect again to validate your JIT access to the VM. Use the same file you downloaded previously.
13.	Now you should get the prompt for the local admin credentials. **Type your username and password** and click **OK**.
14.	You **are now connected to asclab-win** server. Close the remote control session/log off.

### Exercise 2: Adaptive Application Control

Application control helps you deal with malicious and/or unauthorized software, by allowing only specific applications to run on your machines.

1.	From Microsoft Defender for Cloud sidebar, click on **Workload Protections**.
2.	On the Advanced protection part at the bottom, click on **Adaptive application control**.

![](../Images/lab8aac.gif?raw=true)
3.	The Adaptive application controls page opens with your VMs grouped into the following tabs: Configured, Recommended and No recommendations.
4.	Click on the **Recommended** tab.
5.	If this tab does not contain any group yet, it means that Microsoft Defender for Cloud needs at least two weeks of data to define the unique recommendations per group of machines.

### Exercise 3: File Integrity Monitoring

File integrity monitoring (FIM), also known as change monitoring, examines operating system files, Windows registries, application software, Linux system files, and more, for changes that might indicate an attack.
It maps the current state of these items with the state during the previous scan and alerts you if suspicious modifications have been made. To enable FIM, follow the instructions below:

1.	From Microsoft Defender for Cloud sidebar, click on **Workload Protections**.
2.	On the Advanced protection part at the bottom, click on **File Integrity Monitoring** tile.
3.	On the FIM configuration page, select the Log Analytics workspace **asclab-la-xxx**.
![](../Images/mdfc-fim.png?raw=true)
4.	On the Enable FIM, **review the default recommended settings** for Windows files, Registry and Linux files.
5.	Click on **Enable File Integrity Monitoring** button.

![](../Images/mdfc-enablefim.png?raw=true)

You'll now be able to track changes to files in resource associated with the log analytics workspace.

![](../Images/mdfc-fimtrack.png?raw=true)

### Exercise 4: Enable the integration with Microsoft Defender for Endpoint for Windows

[Workload Protections for servers](https://docs.microsoft.com/en-gb/azure/security-center/defender-for-servers-introduction) includes an integrated license for [Microsoft Defender for Endpoint](https://www.microsoft.com/microsoft-365/security/endpoint-defender). Together, they provide comprehensive endpoint detection and response (EDR) capabilities.
When Defender for Endpoint detects a threat, it triggers an alert. The alert is shown in Microsoft Defender for Cloud. From Microsoft Defender for Cloud, you can also pivot to the Defender for Endpoint console, and perform a detailed investigation to uncover the scope of the attack.
 
 
If you've never enabled the integration for Windows, the Allow Microsoft Defender for Endpoint to access my data option will enable Microsoft Defender for Cloud to deploy Defender for Endpoint to both your Windows and Linux machines.
1.	From Microsoft Defender for Cloud's menu, select **Environment settings** and select the subscription (**Azure Subscription 1**) with the Linux machines that you want to receive Defender for Endpoint.
2.	Then select **Integrations** from the sidebar.

![](../Images/mdfc-integrations.png?raw=true)

3.	Select **Allow Microsoft Defender for Endpoint** to access my data (if it's not already on), and select **Save**.

Microsoft Defender for Cloud will:
1.	Automatically onboard your Windows and Linux machines to Defender for Endpoint
2.	Ignore any Linux machines that are running other fanotify-based solutions (see details of the fanotify kernel option required in [Linux system requirements](https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/microsoft-defender-endpoint-linux#system-requirements))
3.	Detect any previous installations of Defender for Endpoint and reconfigure them to integrate with Microsoft Defender for Cloud.
Onboarding might take up to 24 hours.
