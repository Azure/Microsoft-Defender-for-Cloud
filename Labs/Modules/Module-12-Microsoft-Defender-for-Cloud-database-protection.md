# Module 12 - Microsoft Defender for Cloud database protection

![yellowshieldwithwhitestar](../Images/asc-labs-advanced.gif?raw=true)

## 🎓 Level: 300 (Intermediate)

⌛ Estimated time to complete this lab: 60 minutes

## Objectives

This exercise guides you MDC's database protection plans. Database protection in Defender for Cloud contains four flavors, dependong on which database type you are looking to protect.

1. Defender for SQL PaaS (SQL on Azure VM)
Vulnerability assessment and threat protection is available for this plan. Read more about it [here](https://learn.microsoft.com/en-us/azure/defender-for-cloud/defender-for-sql-introduction).
2. Defender for SQL on machines (SQL servers hosted on premise, in Azure, AWS or GCP)
For this plan, Azure Monitoring Agent (AMA) is required, in place of Microsoft Monitoring Agent (MMA). Read more about this [here](https://learn.microsoft.com/en-us/azure/defender-for-cloud/defender-for-sql-usage). Vulnerability assessment and detecting anomalous activities are available to protect your Iaas SQL Servers.
3. Defendr for Open-source relational database
Protect your PostgreSQL, MySQL and MariaDB resources by detecting anomalous activities. Read more about these security alerts [here](https://learn.microsoft.com/en-us/azure/defender-for-cloud/defender-for-databases-introduction).
4. Defender for Cosmos DB (NoSQL)
Detect potential threats against Cosmos DB accounts like SQL injection, compromised identities or potential exploitation. Read more about CosmosDB protection [here](https://learn.microsoft.com/en-us/azure/defender-for-cloud/concept-defender-for-cosmos).

### Exercise 1: Create a SQL Server on an Azure VM, enable Defender for SQL servers on machines plan and validate alerts

To enable the Defender plan on a specific subscription:

1. Sign into the **Azure portal**.
2. Navigate to **Microsoft Defender for Cloud**, then **Environment settings**.
3. Select the relevant subscription.
4. Locate **Databases**.
5. Click on **Select types** and ensure **SQL servers on machines** is toggled `On`.
6. In the Monitoring Coverage column, click on **Settings**:
    >It is *strongly* recommended to use the new Azure Monitoring Agent for SQL server on machines experience over the legacy Log Analytics/MMA option.
    1. Ensure that `Azure Monitoring Agent for SQL server on machines` is toggled to `On`  
    2. (Optional): In the `Configuration` column, you have the option of configuring which Log Analytic Workspace to use as well as the ability to register Azure SQL server instances by enabling SQL IaaS extension automatic registration.  
7. Click **Continue** and **Save**.

Now all your existing and upcoming Azure SQL servers on machines are protected.

#### Create a SQL Server on a Windows Virtual Machine

First use the ARM template to create a SQL server on a Windows Virtual Machine [here](https://learn.microsoft.com/en-us/azure/azure-sql/virtual-machines/windows/sql-vm-create-portal-quickstart?view=azuresql&tabs=conventional-vm).

1. To deploy, click on the blue **Deploy to Azure** button below:

    [![BlueAzurebutton][def]](<https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fazure-quickstart-templates%2Fmaster%2Fquickstarts%2Fmicrosoft.sqlvirtualmachine%2Fsql-vm-new-storage%2Fazuredeploy.json target="_blank">)

2. Click **Review and Create** and then when it's ready, click **Create**.

    ![SQLVMtemplate](../Images/module12_sqlvmtemplate_yl.png)

3. Once created, make sure **Defender for SQL on machines** plan is enabled.

4. Navigate to the virtual machine. Click on **Extensions + applications**. Notice three extensions: `AzureMonitorWindowsAgent`, `MicrosoftDefenderforSQL` and `SqlIaasExtension`.

#### Validate alerts for Defender for SQL for servers on machines

To validate alerts for Defender for SQL Servers on machines:

1. Sign into the **Azure portal**.
2. Navigate to the virtual machine.
3. Click on the **Connect** dropdown and choose **RDP**
4. Log into your virtual machine using the username and password from Exercise 1.
5. Open Command Prompt and navigate to:
`C:\Packages\Plugins\Microsoft.Azure.AzureDefenderForSQL.AdvancedThreatProtection.Windows\2.0.2650.205\bin`

    >As of this writing, 2.0.2650.205 is the version installed. Depending on when you run this lab, the versioning might change.

6. Run the available attacks as displayed. For example, in the command prompt, you can run:

    `Microsoft.SQL.ADS.DefenderForSQL.exe simulate --Attack BruteForce`.

    ![CmdPrompt simulateattack](../Images/module12_cmdpromptsimulateattack_yl.png)

    >Note: Make sure to use the local username and password (you've assigned this in exercise 1, step 3 when creating the VM) to continue running the tests

7. In a few minutes, navigate to **Microsoft Defender for Cloud**, click on **Security Alerts**.
8. Filter by **Time** or by **Affected resources** and choose your values.
![SQL ATP Alerts](../Images/12sqlatpalerts-yl.png)
9. Notice the alert details pertaining to the SQL server.

#### View vulnerability assessments

1. Navigate to the SQL virtual machine resource in the Azure portal.
2. Under Security, click on **Microsoft Defender for Cloud**.
3. There are **Recommendations**, **Security incidents and alerts** and **Vulnerability assessment findings** on this page.
4. Under **Vulnerability assessment findings**, choose a finding.  
5. Take note of vulnerability assessment details.
6. Under **Affected resources**, click on **resource**.
7. Locate and click on **Vulnerability assessment** under **Findings**.
8. See option to **Add all results as baseline** or **Remove all from baseline**.
![SQL VA Baseline](../Images/12sqlbaseline_yl.png)
Vulernerability assessment findings come from a knowledge base of best practices built-in scanning service in Azure SQL database. It will flag any deviations from best practices like misconfigurations. Read more about this [here](https://learn.microsoft.com/en-us/azure/defender-for-cloud/sql-azure-vulnerability-assessment-overview). Remediate any findings or accept as is.

### Exercise 2: Enable and protect your Azure SQL Databases using Microsoft Defender for Azure SQL Databases

#### Enable database protection on your Azure SQL Database

A SQL server should also have been created, earlier in module 1, and it should be labeled as “asclab-sql-[string]”. If so, you should also be able to locate your SQL databased, labeled as “asclab-db”.

1. Sign into the **Azure portal**.
2. Navigate to **Microsoft Defender for Cloud**, then **Environment settings**.
3. Select the relevant subscription.
4. To protect all database types, toggle the Databases plan to **On**.
5. Select **Select types**.
6. Make sure **Azure SQL Database** has been toggled to **On**.
7. Select **Continue** and **Save**.

Now all your existing (asclab-db from Module 1) and upcoming Azure SQL Databases are protected.

#### Understand vulnerability assessment on your Azure SQL Database

This part of the exercise will leverage "asclab-db".

1. Sign into the **Azure portal**.
2. Navigate to the SQL server or to database directly by searching **“asclab-db”**.
3. Click on **Microsoft Defender for Cloud** under **Security**.
4. **Recommendations** and **Vulnerability assessment findings** should be available.
![Azure SQL Database findings](../Images/12sqldatabaseRecsVAFindings-yl.png)
5. Vulernerability assessment findings come from a knowledge base of best practices built-in scanning service in Azure SQL database. It will flag any deviations from best practices like misconfigurations. Read more about this [here](https://learn.microsoft.com/en-us/azure/defender-for-cloud/sql-azure-vulnerability-assessment-overview). Remediate any findings or accept as is.

### Exercise 3: Enable and protect your OSS RDBs using Microsoft Defender for Open-source relational databases

Defender for Cloud protects PostgreSQL, MySQL flexible servers and MariaDB.

#### Enable database protection for your open source relational databases

1. Sign into the **Azure portal**.
2. Navigate to **Microsoft Defender for Cloud**, then **Environment settings**.
3. Select the relevant subscription.
4. To protect all database types, toggle the Databases plan to **On**.
5. Select **Select types**.
6. Make sure **Open source relational Database** has been toggled **On**.
7. Select **Continue** and **Save**.

#### Create an Azure database for PostgreSQL flexible server

1. To create a PostgreSQL flexible server, follow these instructions [here](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/quickstart-create-server-portal).  
2. Fill in all the necessary fields.
3. Click **Review and Create** and then when it's ready, click
**Create**.
4. Once created, navigate to the resource.
5. Find **Defender for Cloud** under **Security** and make sure the database is **protected**.

#### Understand Azure Maria DB protection

1. Sign into the **Azure portal**.
2. Navigate to **Microsoft Defender for Cloud**
3. Click on **Inventory** and search for your Azure Maria DB resource.
4. **Recommendations** and **Security incidents and alerts** should be available, if applicable.

#### Understand AWS RDS protection

Defender for Cloud now extends its protection to AWS RDS. See this announcement here: Microsoft Defender for Open-Source Relational Databases Now Supports Multicloud (AWS RDS).
In addition to the advance threat protection capabilities for AWS RDS, Defender for open-source relational databases also bundles sensitive data discovery as part of its core value. 
Refer to Module 11 to familiarize yourself with the AWS connector in MDC. 

##### Enable and protect your AWS RDSs using Microsoft Defender for Open-source relational database plan:

1.	Sign into the Azure portal.
2.	Navigate to Microsoft Defender for Cloud, then Environment settings.
3.	Select the relevant AWS Connector.
4.	Navigate to Databases and then select Settings
5.	Expand list next to Open-source relational databases (preview)
6.	Toggle on Open-source relational databases (preview)
7.	Toggle on Sensitive data discovery 
    >Notice SQL Servers on machines – Defender for SQL protects SQL machines outside of Azure, including AWS. Azure Arc must be installed on those machines. 
8.	Click Save.

##### Create an RDS instance with sensitive information
1.	Sign into your AWS portal and create one of the supported RDS resources. 
2.	Upload sensitive data into the just created RDS database
    >Refer to [Module 23, exercise 5 for guidance](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module%2023%20-%20Data%20security%20posture%20management.md?plain=1) or [AWS doc](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/MySQL.Procedural.Importing.AnySource.html) for assistance. 
3.	Wait 24 hours

##### Look for enriched findings in Cloud Security Explorer:
1.	Navigate to Cloud Security Explorer in Defender for Cloud 
2.	Under “Select resource types”, choose “Managed database (PaaS)” then “AWS RDS DB instances
3.	Click “+” to add another condition
4.	For “Select condition”, choose “Data” and then “Contains sensitive data”
5.	Click **Search**
6.	Your AWS RDS DB should populate in the Results section. 

Other places to look for findings:
 - **Alerts**: filter alerts by resources with sensitive data discovery findings
 - **Inventory**: filter RDS resources with sensitive data discovery findings
 - **Resource health**: enrichment with sensitive data discovery findings
 - **Attack path**: identify potential attack paths for RDS with sensitive data discovery findings

### Exercise 4: Explore Defender for Azure Cosmos DB

First use the ARM template to create an Azure Cosmos DB or follow the instructions [here](https://learn.microsoft.com/en-us/azure/cosmos-db/nosql/quickstart-portal).

1. To deploy, click on the blue **Deploy to Azure** button below:

    [![BlueAzurebutton][def]](<https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fazure-quickstart-templates%2Fmaster%2Fquickstarts%2Fmicrosoft.documentdb%2Fcosmosdb-sql-autoscale%2Fazuredeploy.json" target="_blank">)

2. Click **Deploy to Azure**.
3. Fill in all the necessary fields.
4. Click **Review and Create** and then when it's ready, click
**Create**.

#### Enable database protection on your CosmosDB

1. Sign in to the **Azure portal**.
2. Navigate to **Microsoft Defender for Cloud**, then **Environment settings**.
3. Select the relevant subscription.
4. Select **Database types** and toggle **Azure Cosmos DB** plan to **On**.
5. Select **Continue** and **save**.

Now all your existing and upcoming Azure Cosmos DB accounts are protected.

#### Understand Azure Cosmos DB protection

1. Sign into the **Azure portal**.
2. Navigate to the Azure Cosmos DB or to database directly by searching for it in the search box up top.
3. Click on **Microsoft Defender for Cloud** under **Settings**.
![Cosmos DB MDC page](../Images/12cosmosdbRecsAlerts.png)
4. **Recommendations** and **Security incidents and alerts** should be available, if applicable.

### Continue with the next lab [Module 13: Defender for APIs](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module-13-Defender%20for%20APIs.md)

[def]: https://aka.ms/deploytoazurebutton/
