# Module 12 - Microsoft Defender for Cosmos DB

<p align="left"><img src="../Images/asc-labs-advanced.gif?raw=true"></p>

#### 🎓 Level: 300 (Intermediate)
#### ⌛ Estimated time to complete this lab: 30 minutes

## Objectives
This exercise guides you on how to connect and protect your Azure Cosmos DB accounts using Microsoft Defender for Azure Cosmos DB.

### Exercise 1: Enable database protection on your subscription

To enable the database Defender plan on a specific subscription:

1. Sign in to the **Azure portal**.
2. Navigate to **Microsoft Defender for Cloud**, then **Environment settings**.
3. Select the relevant subscription.
4. To protect all database types toggle the **Databases** plan to **On**.
 ![Protect all databse types using Defender for Cloud](../Images/database-types.png?raw=true)
5. Use Select types to enable protections for specific database types. Toggle all resource types to **On**.
6. Select **Continue** and **save**.

Now all your existing and upcoming Azure Cosmos DB accounts are protected.

### Exercise 2: Create an Azure Cosmos DB account and protect it using Microsoft Defender for Azure Cosmos DB.
First you need to download an ARM template for a Cosmos DB. 
1.	Navigate to [ARM template for Azure Cosmos DB](https://azure.microsoft.com/en-gb/resources/templates/microsoft-defender-cosmosdb-create-account/)  
2.  Click **Deploy to Azure**.
3. Fill in all the necessary fields.
 ![Create Cosmos DB](../Images/create-cosmosdb.png?raw=true)
4. Click **Review and Create** and then when it's ready, click **create**.

This Azure Cosmos DB account will then appear under Inventory, and recommendations will appear for it in the Recommendations blade in Microsoft Defender for Cloud.



