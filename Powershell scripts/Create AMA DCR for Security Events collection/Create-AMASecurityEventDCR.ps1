param (
	[Parameter(Mandatory = $true)]
	[string]$DcrName,

	[Parameter(Mandatory = $true)]
	[string]$ResourceGroup,

	[Parameter(Mandatory = $true)]
	[string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$Region,

    [Parameter(Mandatory = $true)]
    [string]$LogAnalyticsWorkspaceARMId
)

Write-Output "Getting Log Analytics Workspace Id..."

$response = Invoke-AzRestMethod -Method GET -Uri "https://management.azure.com/$($LogAnalyticsWorkspaceARMId)?api-version=2021-12-01-preview"

if ($response.StatusCode -ne 200) {
    Write-Error "Failed to get Log Analytics Workspace Id. Error: $($response.Content)"
    return
}

$logAnalyticsWorkspaceId = ($response.Content | ConvertFrom-Json).properties.customerId

Write-Output "Log Analytics Workspace Id: $($logAnalyticsWorkspaceId)"

$body = @'
{
    "properties": {
        "dataSources": {
            "windowsEventLogs": [
                {
                    "streams": [
                        "Microsoft-SecurityEvent"
                    ],
                    "xPathQueries": [
                        "Security!*",
                        "Microsoft-Windows-AppLocker/EXE and DLL!*",
                        "Microsoft-Windows-AppLocker/MSI and Script!*"
                    ],
                    "name": "eventLogsDataSource"
                }
            ]
        },
        "destinations": {
            "logAnalytics": [
                {
                    "workspaceResourceId": "<Log Analytics Workspace ARM Id>",
                    "workspaceId": "<Log Analytics Workspace Id>",
                    "name": "DataCollectionEvent"
                }
            ]
        },
        "dataFlows": [
            {
                "streams": [
                    "Microsoft-SecurityEvent"
                ],
                "destinations": [
                    "DataCollectionEvent"
                ]
            }
        ]
    },
    "location": "<Azure Region>",
    "tags": {
    },
    "kind": "Windows"
}
'@

$body = $body.Replace("<Log Analytics Workspace ARM Id>", $LogAnalyticsWorkspaceARMId)
$body = $body.Replace("<Log Analytics Workspace Id>", $logAnalyticsWorkspaceId)
$body = $body.Replace("<Azure Region>", $Region)

Write-Output "Creating AMA DCR for Security Events collection..."

$response = Invoke-AzRestMethod -Method PUT -Payload $body -Uri "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/microsoft.insights/dataCollectionRules/$($DcrName)?api-version=2021-09-01-preview"

if (-not($response.StatusCode -in (200,201))) {
    Write-Error "Failed to create AMA DCR for Security Events collection. Error: $($response.Content)"
    return
}

Write-Output "AMA DCR for Security Events collection created successfully."