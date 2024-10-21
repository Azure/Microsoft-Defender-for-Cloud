# Module 24 - AI Workloads

![asc-labs-intermediate](https://github.com/user-attachments/assets/a96db39c-df4f-4a09-a164-edbeb6d19189)


#### 🎓 Level: 200 (Intermediate)
#### ⌛ Estimated time to complete this lab: 1-2 hours

#### 💁‍♀️ Author: 
Safeena Begum [Github](https://github.com/safeenab786)

## Objectives
This exercise guides you through enabling and configuring AI workloads plan in Microsoft Defender for Cloud and will help you simulate Jailbreak attack proving the value Microsoft Defender for Cloud brings to secure the AI workloads in your environments. 

## Exercise 1: Enable AI Workloads 

To enable the AI workloads plan, follow these steps:
1.	Sign in to the Azure portal.
2.	Search for and select Microsoft Defender for Cloud.
3.	In the Defender for Cloud menu, select Environment settings.
4.	Select the relevant Azure subscription.
5.	On the Defender plans page, toggle the AI workloads to On.


<img width="468" alt="Defender plans" src="https://github.com/user-attachments/assets/3579d854-3cce-45ae-9aec-a80ff68a4dcf">

6.	Click on ‘Settings’ to ‘enable user prompt evidence’ if you wish to expose the prompts passed between user and the model for deeper analysis of AI related alerts.

<img width="468" alt="Settings" src="https://github.com/user-attachments/assets/3fbf3583-367a-49cd-82d7-39246264f368">


Detailed prerequisites can be found in our [documentation](https://learn.microsoft.com/en-us/azure/defender-for-cloud/ai-onboarding).

> [NOTE]
> AI workloads plan is in limited preview, to get started, you must [sign up](https://aka.ms/D4AI/PublicPreviewAccess) and be accepted to the limited preview, you can start onboarding threat protection for AI workloads.
    1.	Fill out the [registration form](https://aka.ms/D4AI/PublicPreviewAccess).
    2.	Wait to receive an email that confirms your acceptance or rejection from the limited preview.
If you're accepted into the limited preview, you can enable threat protection for AI workloads on your Azure subscription.

## Exercise 2: Simulate Jailbreak attacks

1.	Launch Azure portal, and create a resource group dedicated for the demo (or use one that you have high permissions on- Owner/Contributor).
   
*Please create the resources detailed in the following steps under the same region and subscription as you did for the resource group, created in step 1*

2.	Create a Managed Identity resource (we're going to use it to make sure we see ATPs).
3.	Create an Azure AI Search service
4.	Create a Virtual Machine resource:
   a.	Configure the following:
  	
  	![VMsettings](https://github.com/user-attachments/assets/8141cbf4-1ffb-4c12-ab61-dc730c76ff00)

  	i.	Within that resource, under "Resource Management" select "Identity".

  	  a.	Under "System assigned", move the Status toggle to "on" and click save.
   
   b.	Under "User assigned" click "Add" and select the managed identity you created in step 2.
  	
   ii.	Make sure you have DCSPM enabled on the resource.
  	
  iii.	Under "Connect", go to the "Connect" tab and change the VM port to 22 or 80 (to make the VM is public to the internet)
  	
  iv.	Deploy your VM and install the [following](https://dotnet.microsoft.com/en-us/download/dotnet/6.0)
  	
5.	Create a Storage account resource within the resource group you created in step 1.
   
     a.	Under "Access Control (IAM)" add the following role assignment (if you can't manage to do so, please contact your Subscription admin):
  	
       i.	**Role**

  	Storage Blob Data Reader & Storage Blob Data Contributor
  	
       ii.	**Members**
  	
    • the managed identity you created in step 2
          •	the VM you created in step 4
          •	your user
  	
     b.	Create a new container within your storage account.
  	
  	 c.	Unzip the files in the following folder- [**ContosoData**](https://github.com/Azure/Microsoft-Defender-for-Cloud/tree/main/Labs/Files/ContosoData) and upload them to the container created above.
  	
     d.	Perform the following steps to make sure your Storage account is recognized as containing sensitive data: [Test the Defender for Storage data security features](https://learn.microsoft.com/en-us/azure/defender-for-cloud/defender-for-storage-test#testing-sensitive-data-threat-detection) (continue from step 4)
  	
     e.	Make sure you have DCSPM enabled on the resource.
  	
7.	Create an **Azure OpenAI** resource within the resource group you created in step 1.
   
    i.	Under **Access Control (IAM)** add the following role assignment (if you can't manage to do so, please contact your Subscription admin):
  	
    a.	*Role* Cognitive Services OpenAI User & Cognitive Services User
  	
    b.	*Members*: 
              •	the managed identity you created in step 2 
              •	the VM you created in step 4
  	
       b.  In order to continue to next steps, make sure your account has the following permission:
  	**Cognitive Services OpenAI Contributor**
  	
     c. Via the Overview panel, launch **Azure AI Studio**.
  	
   d. When launching the studio, you'll be prompted to create an AI hub- click on Create Now and wait for your Hub to be ready.
  	
  i. Once your AI Hub is ready, you'll automatically see the AI Project created for you by default, within that hub.
                
  ii. Go to **Content filters** tab and click on + Create a content filter

 iii. Name your configuration **Jailbreak** and under **Additional filters** make sure you enable Jailbreak
  	
  ![Additional prebuilt filters](https://github.com/user-attachments/assets/7117ee0a-c2ce-4ac1-acd1-62bb154d6aea)
  	
   iv. Click 'Save'.
                    
  v. Create a new model deployment: under the 'Deployments' tab click +Create (Real-Time endpoint).
                        
  a. Choose gpt-35-turbo (or another gpt model) and confirm.
  
  b. Under 'Advanced options' assign the content filter you created above.

  c. Click 'Save'.

  vi. Choose the model deployment you just created and click on 'Open in playground'.

  vii. In the playground, open the 'Add your data' tab and click +add your data.
                    
  [Good documentation: How to add a new connection in Azure AI Studio - Azure AI Studio | Microsoft Learn (anything under "Data and Connections")](https://learn.microsoft.com/en-us/azure/ai-studio/how-to/connections-add?tabs=azure-ai-search)
  	
  a.	Under 'Source data', click on +Add connection
  
  i.	Choose the storage account you created in step 3, and specifically choose the blob container containing your data.
  
  ii.	Under 'Authentication method' choose Microsoft Entra ID.
  
  iii.	Name your connection- Grounding data.
  
  iv.	Click 'Add connection'.
  
  v.	Choose that connection from the drop-down list, and then pick one of the folders.
  
  vi.	click Next.
  
  b.	Connect the AI Search service, you created in step 4, click Next.
  
  c.	Under 'Search settings' tick the required boxes
  	
   ![searchsettings](https://github.com/user-attachments/assets/14cbeb1c-2491-48b0-a613-327847b71b98)

  d.	Name your index "Index-1" (or anything you'll be able to track later)
  
  e.	Finish and click 'Create'
  
  vii.	Once your data is all connected, click 'Deploy to web app' and then Launch when ready (the button will turn blue)
  
  ![deploy webapp](https://github.com/user-attachments/assets/10d46b5e-d3c3-4202-b19f-c3a96770eca8)

 viii.	Name your web app- for eg., "webapp assistant"
 
ix.	Go back to Azure Portal, and search for the resource group you created in step 1

a.	Search for an Azure Web App resource type, named webapp assistant (this is the resource containing your web app. You can use it to deploy your app as well)

b.	rename your app:

i.	Under "Environment variables", search for "UI_TITLE"- if you find it then simply edit the title so the app will have the name you want.

ii.	If it doesn't exist, click "+add application settings" and add the app name as the value.
  	
![application settings](https://github.com/user-attachments/assets/2658dfda-fc96-466f-8113-46ea1d741386)

iii.	add the following variable: "MS_DEFENDER_ENABLED" : True

iv.	click apply and restart the app.

x.	once you have your app deployed, [run one of the following prompts to create a jailbreak alert](https://github.com/0xk1h0/ChatGPT_DAN)
 


