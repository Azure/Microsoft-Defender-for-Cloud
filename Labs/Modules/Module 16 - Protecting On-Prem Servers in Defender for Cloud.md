# Module 16 – Protecting On-Prem Servers in Defender for Cloud 

<p align="left"><img src="../Images/asc-labs-intermediate.gif?raw=true"></p>

#### 💁 Authors: 
Alexander Ortha [Github](https://github.com/alexor-ms), [Linkedin](https://www.linkedin.com/in/alexanderortha/)

Liana Tomescu [Github](https://github.com/LianaT), [Linkedin](https://www.linkedin.com/in/liana-anca-tomescu/)
#### 🎓 Level: 300 (Intermediate)
#### ⌛ Estimated time to complete this lab: 120 minutes
<br />

## Objectives
In this exercise, you will learn how to deploy an server on your personal client machine using Hyper-V (which will act as the "on-premise server"), and then deploy Azure Arc on it in order to protect it using Microsoft Defender for Cloud.

## Prerequisites
For server protection of on-premises machines, Defender for Servers (Plan 1, or Plan 2) needs to be enabled. To enable the plan, follow the instruction in [Exercise 1 of module 8](./Module-8-Advance-Cloud-Defense.md#exercise-1-enable-microsoft-defender-for-servers-plan-2).

## Exercise 1: Install Hyper-V which will be used to create the server on your own machine

Pre-requisites: Windows 10/11
Windows 10 Hyper-V System. The guidance also works for Windows 11, see more [here](https://learn.microsoft.com/en-us/virtualization/hyper-v-on-windows/reference/hyper-v-requirements))  


1.  Go to your desktop, and in your Settings, search for Hyper-V
![Settings](../Images/settings-desktop.png?raw=true)
2. Select **“Turn Windows features on or off”**. 
3. Then tick the boxes associated with both Hyper-V features and click okay - **Hyper-V Management Tools** and **Hyper-V Platform**.
![Windows Features](../Images/windowsfeatures.png?raw=true)
4. You will need to re-start your PC to let the changes take effect.
5. Search for **Hyper-V** in the Windows search bar and open it.
6. Download an ISO image which will install an operating system, such as Windows Server 2022, by going [here](https://www.microsoft.com/en-us/evalcenter/download-windows-server-2022).
Select the image most suitable to your PC environment and download it (Note: This process may take a few minutes). 

Take note of where this ISO downloaded, as you'll need it later.

The guidance in the remainder of this module is based on the Windows Server 2022 64-bit edition ISO.
![64 bit ISO](../Images/64bitiso.png?raw=true)

---------------------------------------
## Exercise 2: Using Hyper-V, confirm that there's a virtual switch already installed on your desktop.  

1.	Open up **Hyper-V** by searching for it. 
2. Select your desktop in the Hyper-V Manager in the left-hand side.

![Select Hyper-V desktop](../Images/hypervdesktop.png?raw=true)

3. Next, you need to confirm that there's a virtual switch installed by selecting the "virtual switch manager" in the Actions pane on the right-hand side.

![Virtual Switch pane](../Images/virtualswitchpane.png?raw=true)

There, under virtual switches, you should see the "Default Switch", which confirms that the virtual switch is installed.

If you don't see the default switch already installed, then follow the guidance [here](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/get-started/create-a-virtual-switch-for-hyper-v-virtual-machines?tabs=hyper-v-manager) to install it.

## Exercise 3: Using Hyper-V, create a VM (virtual machine) which will act as the virtual on-premises server that you will be protecting via Defender for DevOps.

1. In Hyper-V under the Actions pane on the right, select **New** and **Virtual Machine**.

2. In the **New Virtual Machine Wizard**, under "Before you begin", select **Next**.

![New Virtual Machine Wizard- Before you Begin](../Images/newvmbeforeyoubegin.png?raw=true)

3. Then give the VM the name **Arc Server**, and leave the default location selected. Hit **next**.

![name the VM](../Images/arcservername.png?raw=true)

4. Select **Generation 2** and hit **next**. 
5. Assign startup memory- minimum memory should be 2048 MB, and recommended is 4096MB. Choose 2048MB. 
Untick **Use dynamic memory for this VM.** and hit **next**.
6. Under **Configure Networking**, select **Default Switch**, and then clik **Next**.

![Configure networking, select Default Switch](../Images/configurenetworking.png?raw=true)

7. Under **Connect Virtual Hard Disk**, leave all the defaults as they are, and click **Next**.
8. For the **Installation Options**, select **Install an operating system from a bootable image file**. **Browse** for the ISO image file you downloaded earlier and select it. Click**next**.

![Installation Options](../Images/installationoptions.png?raw=true)

9. Under the Summary, click **Finish**. 

Now you have created your VM!

## Exercise 4: Install the operating system in your VM

1. Go to your **Arc-Server** VM in the **Hyper-V Manager**, under the **Actions** pane on the right-hand side.

![arc server](../Images/arcserver.png?raw=true)

2. Select the VM and click **Connect** underneath it.

![connect to arc server](../Images/connectarcserver.png?raw=true)

3. In the Virtual machine Connection pop-up that appears, click **Start**. 

![start arc server](../Images/startvm.png?raw=true)

4. Now press any key on the keyboard such as the space bar, and wait for roughly one minute.

Note: If the following screen appears, then select **restart now**. 

Alternatively, click on the start button, as shown below.

![start arc server](../Images/restartvm.png?raw=true)

When the machine reboots, and you need to click on any key, click on the space bar as quickly as possible.

If this fails, keep re-trying this process, until it passes.

5. Then, when the **Microsoft Server Operating System Setup** has appeared, then leave the defaults as they are, and click **Next**.

![start arc server](../Images/ossetupdefaults.png?raw=true)

6. Click **Install now**. 

![start arc server](../Images/installosnow.png?raw=true)

6. Select, the second option of **Windows Servers 2022 Standard Evaluation (Desktop Experience)** (not the one highlited below), and click **next**.

![start arc server](../Images/standarddesktopexperience.png?raw=true)

7. Accept the **Terms and Conidtions**. 

![start arc server](../Images/termsandconditions.png?raw=true)

8. Select **Custom: Install microsoft Server Operating System only (advanced)** (not the one highlited below)

![start arc server](../Images/customos.png?raw=true)

9. Then leave the default drive selected and click **Next**.

![start arc server](../Images/drive0.png?raw=true)

10. Now, the VM is installing, including installing the OS on the VM.

![start arc server](../Images/installingos.png?raw=true)

## Exercise 5: Setup the Azure Arc RP. 

1. Go to the [Azure portal](portal.azure.com).
2. Open up the **Azure cloud shell** by selecting theicon to the right of the search bar. 

![Open Cloud Shell](../Images/opencloudshell.png?raw=true)

3. In Cloud Shell, switch to **Powershell**.

![Cloud Shell](../Images/switchtopowershell.png?raw=true)

4. Go [here](https://learn.microsoft.com/en-us/azure/azure-arc/servers/prerequisites#azure-resource-providers) and copy the Powershell commands to register the Azure resource providers.

![Cloud Shell](../Images/switchtopowershell.png?raw=true)

5. Paste these commands into the Azure cloud shell, and run them by pressing **enter**.

## Exercise 6: Connect to your VM

1. Go to your **Arc-Server** VM in the **Hyper-V Manager**, under the **Actions** pane on the right-hand side.

![arc server](../Images/arcserver.png?raw=true)

2. Select the VM and click **Connect** underneath it.

![connect to arc server](../Images/connectarcserver.png?raw=true)

3. Select a password and click **Next**.

4. For the **Display configuration**, select **large** (full screen), and click **Connect**.

![connect to arc server](../Images/displayconfig.png?raw=true)

5. Now you have your virtual machine, and you can log in with the password that you just created.

![connect to arc server](../Images/login.png?raw=true)

6. Once your new virtual machine is running, then you can update the system. Search for **Windows Settings**.

![connect to arc server](../Images/updates.png?raw=true)

7. In Windows Settings, search for **Check for updates**, and run the updates. 

8. Wait for the updates to install and restart the VM if needed to complete the installation.

Now your VM is ready to go!

## Exercise 7: Install Azure Arc on the VM so the VM will be protected by Micrsosoft Defender for Cloud

Prerequisites: Check the prerequisites for installing Arc [here](https://learn.microsoft.com/en-us/azure/azure-arc/servers/learn/quick-enable-hybrid-vm#prerequisites)

After, you will generate the installation script for Arc.

1. Go to the Azure Portal and in the searchbox, look for **Azure Arc**.

![Arc](../Images/arcinportal.png?raw=true)

2. Click **Servers** under Infrastructure on the left-hand tab.

3. Select **+ Add**.

![Arc](../Images/addarcserver.png?raw=true)

4. Select **Generate script** in the **Add a single server** option.

![Arc](../Images/generatearcscript.png?raw=true)

5. In the **Prerequisites** page of **Add a server with Azure Arc**, press **Next**.

![Arc](../Images/nextarcprereq.png?raw=true)

Note: The sever should be able to reach the internet over port 443 and a set of outbound URLs for the Arc agent to function. You can view the outbound URLs [here](https://learn.microsoft.com/en-us/azure/azure-arc/servers/network-requirements?tabs=azure-cloud#urls).

6. In the **Resource details**, fill in the following info (change it as necessary):

![Arc](../Images/arcserverdetails.png?raw=true)

Note: for the connectivity method, select what’s most appropriate for your environment. As this is a test server in my case, I’m leaving it as Public endpoint.

7. Add a tag if you choose, and click **Next**.

![Arc](../Images/arctag.png?raw=true)

8. In the **Download and run script** page, copy the script to your clipboard.

9. Go back to your VM (start it if it's not already running).

10. Search for **Powershell ISE**, and right-click it and select **Run as administrator**.

![Arc](../Images/powershelladmin.png?raw=true)


11. Now that Powershell is open, Create a new file, and paste the Arc script (that we copied earlier) directly into this file, and then press run.

12. As the script runs, the VM's default browser should appear asking you to authenticate into your Azure subscription (where we will be connecting this server to). Sign in to your Azure subscription.

13. Once script has completed, the Azure Arc agent has been deployed and configured onto the server. 

This means that your Azure subscription, will be able to detect this server after approximately 24 hours. This VM will act as an on-premises server in Azure, and it will be protected by Microsoft Defender for Cloud.

## Exercise 8: Confirm that the "on-prem" server we created is being detected by the Azure portal

1. Go to the Azure Portal, and search for the resource group where you created the Arc server earlier.

2. Notice that your machine will be there (with a different name).

![Arc](../Images/rg.png?raw=true)

3. You will need to wait for approximately 24 hours after installing the Arc agent on the VM before the VM appears in Microsoft Defender for Cloud.

![Inventory in MDC](../Images/mdcinventory.png?raw=true)




4. From Inventory, click into the server name to open up **Resource Health** about that server. Then in the Resource Health, click again on the server name on the top-left hand corner. This will bring you to the Arc resource.

5. From the Arc resource, go to **Extensions**, and there you will notice that the agents have been installed automatically.

    The MDE.Windows agent refers to the MDE (Microsoft Defender for Endpoint) capabilities.

    The AzureSecurityWindowsAgent refers to the AMA (Azure Monitor Agent), which is due to my auto-provisioning settings in Microsoft Defender for Cloud. See more [here](https://learn.microsoft.com/en-us/azure/azure-monitor/agents/agents-overview) for the Azure Microsoft Agent.

    [Here](https://learn.microsoft.com/en-us/azure/azure-arc/servers/manage-vm-extensions) is a link for all possible Azure Arc extensions.

![Arc VM Extensions](../Images/extensionsInArcVM.png?raw=true)

Note: You should install the log analytics agent/ Azure Monitor Agent on the machine in order for it to be protected by Microsoft Defender for Servers as part of Microsoft Defender for Cloud automatically. See more [here](https://learn.microsoft.com/en-us/azure/azure-monitor/agents/log-analytics-agent) for the log analytics agent. 

! Please be aware that the Log Analytics agent is on a deprecation path and won't be supported after August 31, 2024. If you use the Log Analytics agent to ingest data to Azure Monitor, [migrate to the new Azure Monitor agent](https://learn.microsoft.com/en-us/azure/azure-monitor/agents/azure-monitor-agent-migration) prior to that date. 


### Now you have successfully onboarded a server outside of Azure to Microsoft Defender for Cloud by using Azure Arc.
<br />




### A possible next step to get more familiar with Azure Arc is to follow the guidance in the micro-hack [here](https://github.com/microsoft/MicroHack/tree/main/03-Azure/01-03-Infrastructure/02_Hybrid_Azure_Arc_Servers).
<br />

### Further Links
[Best practise configuration management for Azure Arc enabled servers](https://learn.microsoft.com/en-us/azure/architecture/hybrid/azure-arc-hybrid-config)

[Azure automanage for Arc-enabled servers](https://learn.microsoft.com/en-us/azure/automanage/automanage-arc)
