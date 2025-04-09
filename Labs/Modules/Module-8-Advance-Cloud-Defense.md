# Module 8 – Enhanced Security

<p align="left"><img src="../Images/asc-labs-advanced.gif?raw=true"></p>

#### 🎓 Level: 300 (Advanced)
#### ⌛ Estimated time to complete this lab: 60 minutes

## Objectives
Defender for Servers offers threat detection and advanced cloud defense capabilities for compute workloads. This includes Just In Time (JIT) VM Access to protect a machine's management ports and File Integrity Monitoring (FIM) to track changes and running applications on machines, but also OS-level threat detection offered by Microsoft Defender for Endpoint, and network layer threat detection for Azure VMs, including DNS- and network-based attacks.
In this exercise, you will understand how some of these enhanced capabilities in Defender for Servers Plan 2 are enabled to help you protect compute workloads in cloud environments.

### Exercise 1: Enable Microsoft Defender for Servers Plan 2
To enable the Defender plan on a specific subscription:
1.	Sign into the **Azure portal**.
2.	Navigate to **Microsoft Defender for Cloud**, then **Environment settings**.
3.	Select the relevant subscription.
4.  Locate Servers. 
5.	Ensure the **Status** is toggled **On**.
6.	Click on **Settings** and ensure all of them are toggled **On**.
7. Click **Continue** and **Save**. 

Now all your existing and upcoming Azure VMs and Azure Arc-enabled servers are protected.

### Exercise 2: Using JIT to reduce attack surface

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

### Exercise 3: File Integrity Monitoring

File integrity monitoring (FIM) scans and analyzes operating system files, Windows registries, application software, Linux system files for changes that might indicate an attack. To enable FIM, follow the instructions below:

1.	From Microsoft Defender for Cloud menu, select **Environment Settings**.
2.	Select the relevant subscription.
3.	Locate the Defender for Servers plan and select **Settings**.
4.  In the **File Integrity Monitoring** section, switch the toggle to **On**. Then select **Edit configuration**.
![](../Images/mdfc-fim.png?raw=true)
5.	The **FIM configuration** pane opens. In the **Workspace selection** dropdown, select the workspace where you want to store the file integrity monitoring data. If you want to create a new workspace, select **Create new**.
![](../Images/lab8-fimconf1.png?raw=true)
6.  In the lower section of the **FIM configuration** pane, select the **Windows registry**, **Windows files**, and **Linux files** tabs to choose the files and registries you want to monitor. If you choose the top selection in each tab, all files and registries are monitored. Select **Apply** to save your changes.
![](../Images/lab8-fimconf2.png?raw=true)
7.  Select **continue**.
8.  Select **Save**.

#### Review FIM findings
1.  In the Defender for Cloud navigation menu, go to **Workload protection** > **File integrity monitoring**.
![](../Images/lab8-reviewfim1.png?raw=true)
2.  Review the total amount of **Changes** in your environment and the amount of **Total changes** per machine.
![](../Images/lab8-reviewfimresults.png?raw=true)
3.  FIM results are exported to the Log Analytics workspace you selected at the beginning of this exercise. To review the results, select a machine or subscription from the view. 
![](../Images/lab8-reviewfimresults2.png?raw=true)

#### Review configuration status for FIM
Review the FIM enablement to ensure it is correct and all prerequisites are met.
1.  In the Defender for Cloud navigation menu, go to **Workload protection** > **File integrity monitoring**.
![](../Images/lab8-reviewfim1.png?raw=true)
2.  Select **Settings**.
![](../Images/lab8-reviewfim2.png?raw=true)
3.  Check for missing prerequisites.
4.  Select a subscription and review corrective actions if necessary. You will see all subscription that have/don't have FIM enabled.
![](../Images/lab8-reviewfim3.png?raw=true)
5.  Select **Apply**.
