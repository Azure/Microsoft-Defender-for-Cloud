# Function App based on Event Grid events to Move Malicious Blobs

This FunctionApp moves files that are "Malicious" into the storage blob container "maliciousfiles" (you can modify this in the MoveMaliciousBlobEventTrigger.cs code); it will also move files that have "No threats found" to the storage blob container "cleanfiles". For a step-by-step on how to configure the FunctionApp, follow the instructions of the [NinjaLab](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module%2019%20-%20Defender%20for%20Storage.md#%EF%B8%8F-exercise-10-function-app-based-on-event-grid-events). 


## Instructions
A Function App provides high performance with a low latency response time.

1. Create a [Function App](https://learn.microsoft.com/en-us/azure/azure-functions/functions-overview?pivots=programming-language-csharp) in the same resource group as your protected storage account.

1. Add a role assignment for the Function app identity.

    1. Go to **Identity** in the side menu, make sure the **System assigned** identity status is **On**, and select **Azure role assignments**.

    1. Add a role assignment in the subscription or storage account levels with the **Storage Blob Data Contributor** role.

1. Consume Event Grid events and connect an Azure Function as the endpoint type.

1. When writing the Azure Function code, you can use our premade function sample - [MoveMaliciousBlobEventTrigger](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Workflow%20automation/Move%20Malicious%20Blob%20FunctionApp%20Defender%20for%20Storage/MoveMaliciousBlobEventTrigger.cs), or [write your own code](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blob-copy) to copy the blob elsewhere, then delete it from the source.

For each scan result, an event is sent according to the following schema.
