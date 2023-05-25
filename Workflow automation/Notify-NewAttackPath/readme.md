# Notify - New Attack Path
author: Giulio Astori <br/> <br/>
One of the key challenges faced by organizations using Microsoft Defender for Cloud Attack Path analysis is the lack of built-in notification functionality for new attack paths.
One way to overcome this challenge is to he solution utilizes use Azure Logic Apps and custom notifications to provide security teams with real-time updates on new attack paths. By deploying the Logic App using the provided ARM template, organizations can establish a reliable and automated process for receiving notifications whenever Microsoft Defender for Cloud reports new attack paths. This empowers security teams to stay ahead of potential vulnerabilities and take proactive measures to secure their cloud environments effectively. 

Next, we will delve into the details of the solution, explaining how the Logic App works and the benefits it offers in terms of timely attack path notifications. 

Attack Path Notification Process 

Let's walk through the process of how this solution works: 

Trigger: The Logic App is set to run daily using a recurring trigger. This ensures that Attack Paths are evaluated regularly. 

Query Attack Paths: The Logic App retrieves Attack Paths data by making an API request to the Azure Resource Graph. It fetches important details such as Attack Path ID, display name, description, and attack path type. 

Evaluate Attack Paths: The Logic App processes each Attack Path using a loop. For each path, it performs the following steps: 

1. Check Existence: The Logic App checks if the Attack Path already exists in the storage account table by making an API request. 

2. Update or Insert Entity: If the Attack Path exists, the Logic App updates the LastUpdate timestamp. If it doesn't exist, a new entity is created with the Attack Path details, and the Notified flag is set to "False" to indicate a pending notification. 

3. Send Notification: After updating or inserting the entity, the Logic App sends email notification using the Office 365 connector. The notification includes important Attack Path details and a link to view the details in Defender for Cloud. 

Notification Body: The Logic App constructs the email notification body using HTML formatting, making it visually appealing and informative. 

Storage Account and Table: It's important to have a storage account and table in place for the Logic App to function correctly. Attack Path entities are stored in this table, enabling the Logic App to query and update them. This is necessary because the Azure Resource Graph data for Attack Paths lacks the specific date and time of their generation and update. 

Recurring Frequency: It is recommended to set the Logic App's recurrence frequency to once a day. This aligns with the frequency at which Attack Paths are evaluated and reported by Defender for Cloud. 

Prerequisites 

For the Logic App to work and utilize its capabilities to send Attack Path notifications, there are several prerequisites that need to be in place. Here are the prerequisites you need to consider: 

1. Logic App System Identity: A Logic App System Identity is created when deployed, however there is a need to configure it with the necessary permissions to read all subscriptions. This will enable the Logic App to query for Attack Paths data using the Azure Resource Graph API. The required permissions should include read access to relevant subscriptions where Attack Paths is enabled (Defender for CSPM). 

2. Storage Account and Table: Set up a storage account in Azure that will be used to store the Attack Path entities and enable the Logic App to query and update them. Create a table within the storage account to store the Attack Path data. This table will serve as the central repository for storing information related to Attack Paths. 

3. MS365 Outlook Account: Ensure that you have an active Microsoft 365 (MS365) Outlook account or an account with access to the Microsoft 365 email service. This account will be used by the Logic App to send email notifications for the new Attack Paths detected. 

4. Logic App API Connections: Configure the necessary API connections within the Logic App to access the Storage Account Table and send emails via MS365 Outlook. You will need to provide the appropriate connection details and authenticate the Logic App with the required permissions for accessing the Storage Account and sending emails. 

5. Storage Account Shared Storage Key: Obtain the shared storage key for the configured storage account. This key will be used to authenticate the Logic App when accessing the Storage Account Table and perform operations such as querying and updating Attack Path entities. 

Optional Step: Populating Azure Storage Account and Table with Existing Attack Paths 

As part of the solution, we provide an optional PowerShell script that enables you to create an Azure Storage Account and Table, and populate it with the existing Attack Paths. This step is particularly useful if you have multiple Attack Paths already present and you prefer not to receive notifications for all of them. By populating the table, you can set the state to zero and ensure that only new Attack Paths detected from that moment onward trigger notifications. 

To use the provided script, follow these instructions: 

Ensure that you have the Azure PowerShell modules "Az", “Az.ResourceGraph”, “AzTable” installed. 

 
Replace <Subscription ID> with the ID of the Azure subscription you want to work with. Replace <Storage Account Name> with the Azure Storage Account Name of your choice. 

After executing the script, you will see a success message indicating that the data has been successfully populated in the specified table. 

By following these steps and populating the Azure Storage Account and Table with existing Attack Paths, you can ensure that only new Attack Paths trigger notifications while excluding the ones already present in the table. 

Please note that this step is optional and only necessary if you have existing Attack Paths that you want to exclude from the initial notification process. 

Verifying and Configuring API Connections 

Once you have deployed the Logic App, it is essential to verify and configure the API connections used within the Logic App to ensure their proper functioning. The API connections, namely "Azuretables" and "Office365," require attention to establish successful communication with the corresponding services. Follow the steps below to verify and configure the API connections: 

1. Access the Azure portal and navigate to the deployed Logic App. 

2. Within the Logic App designer, identify the API connections utilized by the Logic App: "Azuretables" and "Office365." 

3. Click on each API connection to access its settings and configuration. 

4. For the "Azuretables" API connection: 

    * Confirm that the connection is enabled. 

     * Verify the connection details, including the storage account and table, to ensure they align with your configuration. 

    * Make any necessary modifications to the connection settings as per your requirements. 

5. For the "Office365" API connection: 

    * Enable the connection if it is not already enabled. 

    * Validate the connection details, such as the M365 Outlook account and other settings. 

    * Adjust the connection settings if needed to match your specific configuration. 

6. Save the changes made to the API connections. 

7. Proceed to test the API connections to ensure their proper functioning: 

    * Within the Logic App designer, locate the "Test" button at the top of the screen. 

    * Follow the provided prompts to supply any required inputs for the test. 

    * Execute the test and carefully examine the results for any errors or issues. 

8. If the test runs successfully without any errors, it indicates that the API connections are properly configured and functional. <br/><br/>

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FMicrosoft-Defender-for-Cloud%2Fmain%2FWorkflow%20automation%2FNotify-NewAttackPath%2Fazuredeploy.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>
