# Read-AzStorageTransactions

This script is used pull the Blob and File transactions metric from each storage account in a subcription or tenant.  The results are exported to a csv.  User can then use Excel to sort by account and calculate the total transactions for both services.  This can then be used to calculate Azure Security Center Storage pricing.

Here is a sample of the output:
```csv
"timeStamp","total","MetricType","StorageAccount","ResourceGroup","Location","Subscription","Id"
"9/3/2020 12:00:00 PM","153","Blob","<account>","<RG>","eastus","<SUB>","/subscriptions/<SUB>/resourceGroups/<RG>/providers/Microsoft.Storage/storageAccounts/<account>"
"9/4/2020 12:00:00 PM","160","Blob","<account>","<RG>","eastus","<SUB>","/subscriptions/<SUB>/resourceGroups/<RG>/providers/Microsoft.Storage/storageAccounts/<account>"
"9/3/2020 12:00:00 PM","122","File","<account>","<RG>","eastus","<SUB>","/subscriptions/<SUB>/resourceGroups/<RG>/providers/Microsoft.Storage/storageAccounts/<account>"
"9/4/2020 12:00:00 PM","110","File","<account>","<RG>","eastus","<SUB>","/subscriptions/<SUB>/resourceGroups/<RG>/providers/Microsoft.Storage/storageAccounts/<account>"
```

