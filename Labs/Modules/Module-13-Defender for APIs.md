# Module 13 - Defender for APIs

<p align="left"><img src="../Images/asc-labs-advanced.gif?raw=true"></p>

#### 🎓 Level: 300 (Advanced)
#### ⌛ Estimated time to complete this lab: 120 minutes
#### 💁 Author: Liana Anca Tomescu 


## Objectives
In this exercise, you will learn how to enable Defender for API with Azure API Management, and leverage Defender for API capabilities.

See the [official Defender for API announcement](https://techcommunity.microsoft.com/t5/microsoft-defender-for-cloud/microsoft-bolsters-cloud-native-security-in-defender-for-cloud/ba-p/3801818).

See the [Defender for API documentation](https://learn.microsoft.com/en-us/azure/defender-for-cloud/defender-for-apis-introduction).

### Exercise 1: CREATE AZURE API MANAGEMENT SERVICE

Note: The deployment time for a new Azure API Management service is ~ 1 hr.

1.	From the Azure portal menu, select **Create a resource**. You can also select Create a resource on the Azure Home page.
 ![](../Images/api1.png?raw=true)
2.  On the **Create a resource page**, select **Integration > API Management**.
![](../Images/api2.png?raw=true)
3.  In the Create API Management page, enter settings.

**Subscription**	The subscription under which this new service instance will be created.

**Resource group**	Create a new resource group and call it “labs-API”.

**Region**	North Europe

**Resource name**	API-Man-Service .net. 

**Organization name**	Contoso

**Administrator email**	Add your email address

**Pricing tier**	Select Developer tier 



4. Select **Review + create**.
5.	Once your API management service has been created after ~1 hour, then open it up in the Azure portal.


### Exercise 2: PUBLISH AN API WITHIN API MANAGEMENT

1.	In the left navigation of your API Management instance, select **APIs**.
 ![](../Images/api3.png?raw=true)
2.	Select the **OpenAPI** tile.
3.	In the Create from OpenAPI specification window, select **Basic**.
4.	Enter the following values.

**OpenAPI specification**	https://conferenceapi.azurewebsites.net?format=json			

**Display name**	Labs Test			

**Name**	After you enter the preceding Display Name, API Management fills out this field based on the JSON.		

**API URL suffix**	labs	

 ![](../Images/api4.png?raw=true)
 
 5. Select **Create** to create your API.

### Test your API
1.	Once the API has been created, then select it.
2.	Under Revision 1, select the **Test** tab.
3.	Click on **GetSessions**.

 ![](../Images/api5.png?raw=true)
 
4.	Leave all the default values in GetSessions as they are, and press **Send**.
You can then scroll through the results to verify that the API has been onboarded successfully to Azure API Management.

![](../Images/api6.png?raw=true)
 
Note: It will take up to 45 minutes for the API you just created to appear in Defender for Cloud for you to follow the next exercise.



### Exercise 3: ENABLE DEFENDER FOR API
1.	Go to the **Azure Portal (portal.azure.com)**. 
2.	Find the **Microsoft Defender for Cloud** blade and select **Environment settings** in the left-hand navigation bar. 
3.	Click the down arrow on Azure, through any management groups, and select the subscription you want to protect APIs on.
4.	Under Cloud Workload protections, ensure that the APIs plan is switched **On**.
 

 ![](../Images/api7.png?raw=true)

### Exercise 4: ONBOARD APIS TO DEFENDER FOR APIS
Next, you will onboard that API to be protected by Defender for API.
1.	Navigate to the **Recommendations** pane in Microsoft Defender for Cloud
2.	Under the category “Enable enhanced security features” select the recommendation **Azure API Management APIs should be onboarded to Defender for APIs**. 

![](../Images/api8.png?raw=true)
 
3.	In the recommendation **Azure API Management APIs should be onboarded to Defender for APIs**, tick the box of the API labs-test that you would like to onboard, and click **Fix**.

 ![](../Images/api9.png?raw=true)

4.	In the Fixing resources pane that appears, select **Fix 1 resource**. After a few minutes, you will receive a notification stating that the API has been onboarded.

Now you have onboarded that API to Defender for API.




### Exercise 5: EXPLORE THE DEFENDER FOR API TILE AND LOOK AT API RECOMMENDATIONS IN DEFENDER FOR CLOUD
1.	Navigate to the Microsoft Defender for Cloud’s **Workload Protections** pane (from the left-hand navigation bar). 

![](../Images/api10.png?raw=true)
 
2.	In the bottom part of the blade, under Advanced protection section, click the **API Security** tile at the bottom right.
 

![](../Images/api11.png?raw=true)

3.	Select the **API labs-test** that you want to check its security.

 
![](../Images/api12.png?raw=true)





4.	Select **GetSessions** endpoint name that you tested in Exercise 2 to see this endpoint’s **Resource Health** page.

![](../Images/api13.png?raw=true)
 
5.	Explore the **Resource Health** page 

![](../Images/api14.png?raw=true)

6.	Click on the **API endpoints in Azure API Management should be authenticated** recommendation to get more information into that recommendation.

![](../Images/api15.png?raw=true)
 
Next, you will explore other Defender for API recommendations.
1.	In **Microsoft Defender for Cloud**, select **Recommendations** from the left-hand navigation pane.
2.	In the Recommendations page, select the filter **Resource types**.
 
![](../Images/api16.png?raw=true)

3.	In the Value tab, **unselect all**, and then only select **API Management services, API Collections and API Endpoints**, and press **OK**.

![](../Images/api17.png?raw=true)
 
4.	Expand **Manage access and permissions, Enable enhanced security features and Implement security best practices**, to see the API recommendations that belong to these controls.


![](../Images/api18.png?raw=true)
 
5.	Select the recommendation **API Management services should use a virtual network**.
6.	Explore this recommendation by looking at what’s displayed, such as **Unhealthy resources**.

![](../Images/api19.png?raw=true)
   

### Exercise 6: TRIGGER AN ALERT “SUSPICIOUS USER AGENT DETECTED”

1.	Access the **API Management** resource through the **Azure Portal**.
2.	Select the **API Management** API-Man-Service service that you created.
3.	Navigate to the APIs blade.
4.	Select the **API Endpoint Echo API**.

![](../Images/api20.png?raw=true)



5.	Select the API Operation **Retrieve header only** and then open the **Test** tab. 

6. In the **Request URL**, copy the full request URL that will be required later and store it in a secure location. If you named your API Management service “API-Man-Service”, then the URL will be:
https://api-man-service.azure-api.net/echo/resource


7.	Press **Send** at the bottom of the page (still in the **Test** tab).
8.	In the HTTP response message, copy the **APIM subscription key** and store it in a secure location also.


![](../Images/api22.png?raw=true)
 
9.	In a separate tab on your broser, navigate to the web application **Postman API Platform** by going to **postman.com** and sign up for a new account or login to your existing account.
10.	In the Postman application, select **My Workspace** or any other workspace that you already have.
 
![](../Images/api23.png?raw=true)

11.	Select the **+** icon to start a new request. 

![](../Images/api24.png?raw=true)

12.	Using the HTTP request information that you copied in Step 6, enter the URL in **GET** (e.g., GET https://defenderapidemo.azure-api.net/echo/resource-cached?param1=sample) into Postman. 

![](../Images/api25.png?raw=true)
 
13.	Select the **Headers** tab. 

![](../Images/api26.png?raw=true)

14.	Enter the **APIM subscription key** as a **header**. 

**The key** Ocp-Apim-Subscription-Key

**The value** the unique value that you copied in Step 8. 

15.	Enter another **header** for the user agent value. For this step, enter 

**The key** User-Agent

**The value** javascript: 


![](../Images/api27.png?raw=true)

16.	**Send** the request. You will get a **200 OK** status if the request went through. 

The user agent javascript: contains distinct patterns typical of script code and is rarely used by legitimate user agents.

After some time, Defender for APIs will trigger an alert with detailed information about this suspicious activity, as shown below:

![](../Images/api28.png?raw=true)
  
Now you have successfully tested out Defender for API and triggered an alert.
