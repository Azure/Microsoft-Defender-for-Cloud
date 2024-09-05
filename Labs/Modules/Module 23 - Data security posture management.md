# Module 23 - Data security posture management

<p align="left"><img src="../Images/asc-labs-intermediate.gif?raw=true"></p>

#### 🎓 Level: 200 (Intermediate)
#### ⌛ Estimated time to complete this lab: 1-2 hours

#### 💁💁‍♀️ Authors: 
Pavel Kratky [Github](https://github.com/pavelkratky), [Linkedin](https://www.linkedin.com/in/pavelkratky/)

Yura Lee  [Github](https://github.com/yura-lee/), [Linkedin](https://www.linkedin.com/in/yura-lee/)

## Objectives 
This exercise guides you through enabling and configuring sensitive data discovery in Microsoft Defender for Cloud and will show you various ways of how you can leverage the added sensitivity context provided by Defender CSPM and Defender for Storage plans.

## Exercise 1: Enabling sensitive data discovery

To enable the sensitive data discovery, you need to enable Defender CSPM or Defender for Storage plan on a specific subscription:

1. Sign in to the **Azure portal**.
2. Navigate to **Microsoft Defender for Cloud**, then **Environment settings**.
3. Select the relevant subscription.
4. Toggle the **Defender CSPM** or **Storage** plan to **On**.

   ![Enable DCSPM or Storage plan](../Images/daspenableplan.png?raw=true) 
   
   Detailed permissions to run sensitive data discovery are described in our [documentation](https://learn.microsoft.com/en-us/azure/defender-for-cloud/concept-data-security-posture-prepare#whats-supported).

> [!NOTE]
> If you have only Storage plan enabled, sensitive data discovery will only be available for resources supported by this plan. If you enable Defender CSPM plan, all supported resources will be included in the scanning, including databases and multicloud resources.

5. Click on **Settings & monitoring** on top of the page.
6. In the **Sensitive data discovery** component, make sure the toggle is **ON**.

   ![Enable sensitive data discovery](../Images/daspenablediscovery.png?raw=true)

8. Select **Continue** and in the next screen **Save**.

> [!Important]
> It takes up to 24 hours to see the results for a first-time discovery after enabling the plan. Following scans are done on a weekly basis. If you have enabled any of these plans in previous Modules, allow at least 8 days for the scan to finish its discovery. Alternatively you can add a new Storage account to your subscription. A new Azure storage account that's added to an already discovered subscription is discovered within 24 hours or less.

## (Optional) Exercise 2: Enabling sensitive data discovery for AWS and GCP

### AWS integration

If you want to use sensitive data discovery for AWS S3 Buckets and RDS databases, visit [**Module 11 - Connecting an AWS project**](Module-11-AWS). Even if you have already done this step, you may have to redeploy the connection scripts with updated permissions.

1. Enable sensitive data discovery as described in **Excercise 1**.

2. Proceed with the instructions to download the CloudFormation template and to run it in AWS.

The snapshot is used to create a live instance that is spun up, scanned and then immediately destroyed (together with the copied snapshot).

Only scan findings are reported by the scanning platform.

### GCP integration

In case of GCP storage buckets, please visit [**Module 10 - Connecting a GCP project**](Module-10-GCP).

1. Enable sensitive data discovery as described in **Excercise 1**.

2. Proceed with the instructions to use GCP Cloud Shell or Terraform to connect GCP resources.

<br>

> [!NOTE]
> It takes up to 48 hours for first scan results in case of AWS and GCP.

  
#  Data Sensitivity Settings

## Exercise 3: Configure sensitive data categories

1. Navigate to **Microsoft Defender for Cloud > Environment settings**.

3. Select **Data sensitivity** on top of the page.

   ![Edit data sensitivity settings](../Images/daspsensitivitysettings1.png?raw=true)

4. Select the info types category **Other**:

   ![Select info type category Other](../Images/daspsensitivitysettings2.png?raw=true)

5. By default, info types in the **Other** category are excluded from sensitive data discovery. For purposes of this exercise, select **All** and then **Apply**.

   ![Select all info types in category Other](../Images/daspsensitivitysettings3.png?raw=true)

6. Select **Save** on top of the Data sensitivity page to confirm new settings.



## (Optional) Exercise 4: Import and configure custom sensitive info types and sensitivity labels

Defender for Cloud provides built-in sensitive info types (SITs) from Microsoft Purview out-of-the-box. If you have Enterprise Mobility and Security E5/A5/G5 licensing you can also optionally import your own custom sensitive info types and labels from Microsoft Purview compliance portal. After enabling integration with Microsoft Purview, you will get the option to set-up label thresholds and select your custom SITs to be used for sensitive data discovery.

### Enable integration with Microsoft Purview

1. Log into **Microsoft Purview compliance portal**.
2. Navigate to **Information Protection > Labels**.
3. In the consent notice messages, select **Turn on** and then select **Yes** to share your custom info types and sensitivity labels with Defender for Cloud.

   ![Enable Purview integration 1](../Images/turnonpurviewintegration1.png?raw=true)

   ![Enable Purview integration 2](../Images/turnonpurviewintegration2.png?raw=true)

<!--
> [!NOTE]
> Purview portal integration messages are subject to changes, so it is possible they will not look exactly the same like in this excercise.
-->

### Create a custom sensitive info type

1. Navigate to **Data classification > Classifiers > Sensitive info types**.
    - In case of the new Microsoft Purview portal, this can be found in the **Information Protection** blade.

      ![Custom SIT creation 1](../Images/customsit1.png?raw=true)

2. Select **Create sensitive info type**.
3. Enter name and description.
 
   ![Custom SIT creation 2](../Images/customsit2.png?raw=true)

4. On the **Patterns** step, select **Create pattern**.
5. Add primary element and choose **Keyword list**.

   ![Custom SIT creation 3](../Images/customsit3.png?raw=true)

6. In the **ID** field, type  *"DSPM"*.
7. In the **Keyword group #1, Case insensitive**, type *"data security posture management"*.
8. Select the **String match** option and click **Done**.

   ![Custom SIT creation 4](../Images/customsit4.png?raw=true)

9. Confirm by selecting the **Create** button.
10. Leave **High confidence level** selected in the next step.
11. On the Finish page review the settings and save the new Custom SIT by selecting the **Create** button.
 
    ![Custom SIT creation 5](../Images/customsit5.png?raw=true)

You can now select your Custom SIT from the **Custom** category in the **Data sensitivity** settings described in **Excercise 3**. Create and upload a document which will include the phrase *"data security posture management"* to test your Custom SIT.

### Set the threshold for sensitivity labels
 In the Microsoft Purview compliance portal, make sure your sensitivity label scope is set to *Items*; under which you should configure auto labeling for *Files* and *Emails*. Labels must be published with a label policy to take effect.

> [!NOTE] 
> If you don't have any existing sensitivity labels, follow [this link](https://learn.microsoft.com/en-us/purview/how-to-automatically-label-your-content) for instruction on how to create them.

 You can use the previously created Custom SIT to be used as auto-labeling condition. If you then create a document with the key phrase, the document will then be automatically labeled. Alternatively, you can manualy label documents for example in Office applications.
 
 ![Auto-labeling](../Images/autolabeling.png?raw=true)

To have your labeled data visible in Defender for Cloud, follow these steps to check that your labels are included in the sensitive data discovery:

1. Navigate to **Microsoft Defender for Cloud > Environment settings > Data sensitivity** as described in **Exercise 3**.

2. Select **Change** to see the list of sensitivity labels and select the sensitivity label that will serve as your threshold. If you select the **(Lowest sensitivity)** label, all discovered labeled resources will be shown in Defender for Cloud.

   ![Setting label threshold](../Images/labelthreshold.png?raw=true)

3. Select **Apply** and **Save**.  

# Exercise 5: Upload sensitive data


### Upload data to Storage account

Create a new storage account based on the instructions in [Module 19](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module%2019%20-%20Defender%20for%20Storage.md#exercise-2-create-a-storage-account). 
1. In the **Azure Portal**, navigate to **Storage accounts**.
2. Open the storage account you have created.
3. Navigate to **Data storage > Containers** and create new container by selecting the **+ Container** button on top of the page.

   ![Create Container](../Images/createcontainerdasp.png?raw=true)

4. Choose a name, leave other settings by default and select **Create**.
5. Open the new container by clicking on its name and select the **Upload** button on top of the page.
6. Navigate to [Files](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Files/TestData.zip) and download the *TestData.zip* file. This is a file that contains sample of sensitive data we will use in this exercise. 
7. Select the file *"Credit Card Expenses.docx"* located in *CreditCardNumber* folder from the extracted zip archive and upload it to the container.

   ![Upload data to Container](../Images/uploaddatatocontainerdasp.png?raw=true)

> [!NOTE]
> It takes up to 24 hours for first scan results in case of newly created storage account. Databases are scanned on a weekly basis or within 24 hours on newly enabled subscriptions.

### (Optional) Upload data to Azure SQL database

In [Module 1](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module-1-Preparing-the-Environment.md), you created an Azure SQL database, *asclab-db*. In this exercise, we will connect to the database and upload sensitive information. 

1. Follow instructions [on this page](https://learn.microsoft.com/en-us/sql/relational-databases/import-export/import-data-from-excel-to-sql?view=sql-server-ver16) to upload the .xlsx file into the database created as part of **Module 1**. We recommend to use Microsoft SQL Management Studio for the import (SMSS) with the following steps.
2. In SMSS, select the **asclab-db** database and choose **Import Data** via **Tasks**. 
    
   ![SMSS import data 1](../Images/smssimportdata1.png?raw=true)

3. In the wizard, select the *"Sales Force Expense Cards.xlsx*" file and choose version *Microsoft Excel 2016*. 
      
   ![SMSS import data 2](../Images/smssimportdata2.png?raw=true)

4. On the destination selection step, choose *Microsoft OLE DB Provider for SQL Server* and enter the credentials you used in **Module 1**. 
    
   ![SMSS import data 3](../Images/smssimportdata3.png?raw=true)

5. In the next step, select **Copy data from one or more tables or views**. 
    
   ![SMSS import data 4](../Images/smssimportdata4.png?raw=true)

6. Click on **Edit Mappings**. 

   ![SMSS import data 5](../Images/smssimportdata5.png?raw=true)

7. Change *CC Number* and *CVV* type to **numeric**.

   ![SMSS import data 6](../Images/smssimportdata6.png?raw=true)

8. Confirm and finish the Wizard.

> [!NOTE]
> As described in **Exercise 1** you will now have to wait for the specified time, depending on when you have enabled the plans or created the resources, to allow the scan to finish. Follow [this link](https://learn.microsoft.com/en-us/azure/defender-for-cloud/concept-data-security-posture-prepare#discovery) to our documentation for more details.

# Explore risks to sensitive data

After you discover resources with sensitive data, Microsoft Defender for Cloud lets you explore sensitive data risk for those resources in several ways. We will have a look at the following options:

- **Security Explorer**: You can use Cloud Security Explorer to find sensitive data insights.
- **Attack Paths**: You can use attack paths to discover risk of data breaches.
- **Security alerts**: You can prioritize and explore ongoing threats to sensitive data stores by applying sensitivity filters Security Alerts settings.
- **Inventory**: You will get enhanced context in the Inventory for supported resources.
- **Data security dashboard**: Data-centric security dashboard helps effectively prioritize alerts and potential attack paths for data across multicloud data resources.

## Exercise 6: Explore risks with Cloud Security Explorer

Explore data risks and exposure in cloud security graph insights using a query template, or by defining a manual query.

1. In Defender for Cloud, open **Cloud Security Explorer**.

2. In the Query builder, from the **Select resource types** drop down menu, select *Data > Object storage > **Azure Storage accounts*** and click **Done**.

   ![Security explorer query 1](../Images/daspsecurityexplorer1.png?raw=true)

3. Add condition by selecting the **+** button. Choose *Data > **Contains sensitive data***

   ![Security explorer query 2](../Images/daspsecurityexplorer2.png?raw=true)

4. Run the query by clicking on the **Search** button.

   ![Security explorer query 3](../Images/daspsecurityexplorer3.png?raw=true) 

5. In the *Results* section, look for the Storage account you've created in previous exercise and where you uploaded the *Credit Card Expenses.docx* file. After selecting it, *Result details* window will pop-up in the side, where you can review details. Select the **Export** button to export finding details to a csv file.

   ![Security explorer query 4](../Images/daspsecurityexplorer4.png?raw=true)

4. After opening the exported csv file, you can identify the specific files in which Defender for Cloud identified sensitive content and what sensitive info types did it match.

   ![Security explorer query 5](../Images/daspsecurityexplorer5.png?raw=true)

> [!NOTE]
> Sensitive data discovery in Defender for Cloud uses smart sampling scanning to achieve high efficiency of scanning and does not provide by design, an exhaustive list of all files in the scanned resource. 

## Exercise 7: Identify sensitive resources in Inventory

1. In Defender for Cloud, open **Inventory**.
2. Add a filter **Sensitive info types** to narrow down the list.

   ![Inventory sensitive data 1](../Images/daspinventory1.png?raw=true)

3. In the **Value** drop-down list, uncheck ***(Unclassified)*** to show only resources containing sensitive info types and confirm by selecting **Ok**.

   ![Inventory sensitive data 2](../Images/daspinventory2.png?raw=true)

4. Click on the name of the Storage account where you have uploaded sensitive data sample in previous exercise.

   ![Inventory sensitive data 3](../Images/daspinventory3.png?raw=true)

5. On the *Resource health overview*, you can review the *Sensitive info types* in the **Security value** section.
   
   ![Inventory sensitive data 4](../Images/daspinventory4.png?raw=true)

## (Optional) Exercise 8: Explore risks through attack paths

1. In Defender for Cloud, open **Attack path analysis**.

2. In **Risk Factors**, select **Sensitive data** to filter the data-related attack paths.

   ![Attack Path risk factors](../Images/daspattackpaths1.png?raw=true)

3. Review the attack paths. 

4. To view sensitive information detected in data resources, select the resource name and then **Insights**. There is a section **Insights - Contains sensitive data**, where you can investigate details of the sensitive data discovery.

   ![Attack Path insights](../Images/daspattackpaths2.png?raw=true)



## (Optional) Exercise 9: Explore sensitive data security alerts

When sensitive data discovery is enabled in the Defender for Storage plan, you can prioritize alerts that affect resources with sensitive data.

1. In Defender for Cloud, open **Security alerts**.
2. Click on **Add filter** and search for **Sensitive info types**. In the **Value** parameter, uncheck **(Unclassified)** and confirm the filter by selecting **Ok**.

   ![Alerts SIT 1](../Images/daspalerts1.png?raw=true) 

3. After selecting one of the alerts, you can identify the sensitive info types by scrolling down in the details window.

   ![Alerts SIT 2](../Images/daspalerts2.png?raw=true) 

## (Optional) Exercise 10: Data security dashboard investigation

1. In Defender for Cloud, open **Data security**.
Check the following tiles and look for unusual data:

    ![Data security dashboard 1](../Images/datasecuritydashboard1.png?raw=true) 

- **Data resources requiring attention** - displays the number of sensitive resources that have either high severity security alerts or attack paths. Click on **high severity alerts** or **attack paths** to further drill down on the findings.
   - **Data resources with high severity alerts** - summarizes the active threats to sensitive data resources and which data types are at risk.
   
     ![Data security dashboard 2](../Images/datasecuritydashboard2.png?raw=true) 

   - **Data resources with critical and high attack paths** - summarizes the potential threats to sensitive data resources by presenting attack paths leading to sensitive data resources and which data types are at potential risk. 
   
     ![Data security dashboard 3](../Images/datasecuritydashboard3.png?raw=true) 

- **Data queries in security explorer** - presents the top data-related queries in security explorer that helps focus on multicloud risks to sensitive data. Click on **View** to narrow down the specific query.

   ![Data security dashboard 4](../Images/datasecuritydashboard4.png?raw=true) 

- **Sensitive data discovery** - summarizes the results of the sensitive resources discovered, allowing you to explore a specific sensitive information type and label. You can also open the data sensitivity settings described in **Exercise 3** by using the **Manage data sensitivity settings** button. 

   ![Data security dashboard 5](../Images/datasecuritydashboard5.png?raw=true) 
   
- **Internet-exposed data resources** - summarizes the discovery of sensitive data resources that are internet-exposed for storage and managed databases. Click on **View all data resources exposed to the internet** to run a query in Cloud security explorer. 

   ![Data security dashboard 6](../Images/datasecuritydashboard6.png?raw=true) 