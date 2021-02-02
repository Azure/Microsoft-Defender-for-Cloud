# Modification for Vulnerability Assessment quick fix

Problem: The Azure Security Center recommendation "Vulnerability assessment should be enabled on your SQL servers" includes a Quick Fix remediation, but this remediation creates a new storage account for every SQL server. Below is a modified policy definition to input a storage account as parameter. Upon policy assignment, the Vulnerability Assessment for any SQL server at the given scope will report data to the storage account defined. 

The policy assignment will need the blob container URI, the Resource ID of the storage account, and the location of the SQL server/Storage Account. 

**Please Note: The storage account MUST be in the same location as the SQL servers, as per the requirements of the Vulnerability Assessment. This policy will not behave as expected if there is a location mismatch between the storage account and SQL server.

Deployment steps
1.	Create a new policy definition based on the JSON included
2.	Create a custom security policy 
