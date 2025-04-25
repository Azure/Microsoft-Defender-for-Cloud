# Module 10 - Connecting a GCP project

<p align="left"><img src="../Images/asc-labs-advanced.gif?raw=true"></p>

#### 🎓 Level: 300 (Advanced)
#### ⌛ Estimated time to complete this lab: 60 minutes

## Objectives
This exercise guides you on how to connect and protect GCP projects using Defender for Cloud.

### Exercise 1: Create a GCP project

First you need to create a GCP project. 

1.	Navigate to [Create free GCP](https://cloud.google.com/free).  
![Docker Version in Powershell](../Images/1gcpintro.png?raw=true) 
2.  Click **Get started for free**.
3.  Now select either an existing Google account or create a new one. 
4.  Follow the on-screen instructions to create the GCP project.
5.  At the end, you should be able to sign in to the [Google Cloud Console](https://console.cloud.google.com), and see the Dashboard:
![GCP console](../Images/2gcpconsole.png?raw=true)
6. Copy the project number and project ID, and keep them safe, as you'll be using them in the next exercise.

### Exercise 2: Create the GCP connector in Microsoft Defender for Cloud

In order to be able to protect your GCP resources in Microsoft Defender for Cloud, you need to create the GCP connector in Microsoft Defender for Cloud, which you will do in the following exercise. 


1. Go to the Azure Portal and open **Microsoft Defender for Cloud**. 
2. Go to **Environment Settings** in the left-hand tab.
3. Click **+ Add environment** and select **Google Cloud Platform** from the dropdown menu.

![GCP console](../Images/3gcpdropdown.png?raw=true)

4. In the **Create GCP connector** page, then fill in all the details:

**Connector Name**: select a new name

**Onboard**: Single project 

**Subscription**: Choose your existing subscription

**Resource Group**: Create a new resource group and name it GCP.

**Location**: Select the location nearest you.

**Scan interval**: You can leave as is.

**Organization ID**: You need to enter the organization ID for your GCP project.

![Create GCP connector](../Images/4creategcpconnector.png?raw=true)

5.  After filling everything in, click **Next: Select plans**.
6. In **Select plans**, the Foundational CSPM plan is enabled by default.

7. Ensure that the Defender CSPM, Servers, Containers and Database plans are set to **On**. 

![GCP plans](../Images/5gcpplans.png?raw=true)

8. Select **Next: Configure access**.

For the Management project details, you can either create a new one automatically or use your own existing one. To use the existing GCP project, **uncheck the "Create a dedicated billable GCP project automatically** (as part of the gcloud script)" option.

**Project ID**: Paste this from exercise 1, or alternatively go to [Google Cloud Console](https://console.cloud.google.com) and copy the project ID from the dashboard.

**Project number**: Paste this from exercise 1, or alternatively go to [Google Cloud Console](https://console.cloud.google.com) and copy the project number from the dashboard.

9. Copy the GCP Cloud Shell script. 
![GCP script](../Images/6scpscript.png?raw=true)
10. Click **GCP Cloud Shell** button which will open up the GCP console with Cloud Shell.
11. Click on **Authorize Cloud Shell** to grant permission for Google Cloud API calls.
![GCP script](../Images/6.2gcpscript.png?raw=true)
12. Paste the script into the Cloud Shell.

![GCP console with Cloud Shell](../Images/7gcpconsole.png?raw=true)

13. Let the script run and after it finishes successfully return to Defender for Cloud. 

14. Back in the **Configure access** page click **Next: review and Generate**.

15. In the next screen, after validation completes succesfully, click **Create**.

Now, you have successfully created a GCP connector in Microsoft Defender for Cloud. Now you'll be able to get GCP recommendations and alerts.

### Exercise 3: Investigate the GCP recommendations 

Once a vulnerable image has been pushed to the Azure Container Registry registry, then Microsoft Defender for Containers will start scanning the image for vulnerabilities. You will now look into the recommendations in Microsoft Defender for Cloud for this. 

> [!NOTE]
> You will need to create some GCP resources in order to see recommendations for GCP in Microsoft Defender for Cloud.
 
 1. Go to **Microsoft Defender for Cloud** in the **Azure Portal**.
 2. Go to the **Recommendations** tab in Defender for Cloud.
 3. In the upper taskbar, under **Environment type**, select **GCP** only. 
 
![GCP console with Cloud Shell](../Images/8gcprecommendations.png?raw=true)

If you have existing GCP resources, then you'll be able to see recommendations associated with them.
