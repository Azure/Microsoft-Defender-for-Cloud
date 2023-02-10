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
    [string]$LogAnalyticsWorkspaceARMId,

    [Parameter(Mandatory = $false)]
    [ValidateSet("AllEvents","Common","Minimal","Custom")]
    [string]$EventFilter = "AllEvents",

    [Parameter(Mandatory = $false)]
    [string]$CustomEventFilter
)

if ($EventFilter -eq "Custom") {
    if ([string]::IsNullOrEmpty($CustomEventFilter)) {
        Write-Error "CustomEventFilter cannot be empty when EventFilter is set to Custom."
        return
    }
}

if (-not([string]::IsNullOrEmpty($CustomEventFilter))) {
    if ($EventFilter -ne "Custom") {
        Write-Error "CustomEventFilter can only be set when EventFilter is set to Custom."
        return
    }
}

switch ($EventFilter) {
    "AllEvents" {  
        $xPathQueries = @(
            "Security!*",
            "Microsoft-Windows-AppLocker/EXE and DLL!*",
            "Microsoft-Windows-AppLocker/MSI and Script!*"
        )
    }
    "Common" {
        $xPathQueries = @(
            "Security!*[System[(EventID=1) or (EventID=299) or (EventID=300) or (EventID=324) or (EventID=340) or (EventID=403) or (EventID=404) or (EventID=410) or (EventID=411) or (EventID=412) or (EventID=413) or (EventID=431) or (EventID=500) or (EventID=501) or (EventID=1100)]]",
            "Security!*[System[(EventID=1102) or (EventID=1107) or (EventID=1108) or (EventID=4608) or (EventID=4610) or (EventID=4611) or (EventID=4614) or (EventID=4622) or (EventID=4624) or (EventID=4625) or (EventID=4634) or (EventID=4647) or (EventID=4648) or (EventID=4649) or (EventID=4657)]]",
            "Security!*[System[(EventID=4661) or (EventID=4662) or (EventID=4663) or (EventID=4665) or (EventID=4666) or (EventID=4667) or (EventID=4688) or (EventID=4670) or (EventID=4672) or (EventID=4673) or (EventID=4674) or (EventID=4675) or (EventID=4689) or (EventID=4697) or (EventID=4700)]]",
            "Security!*[System[(EventID=4702) or (EventID=4704) or (EventID=4705) or (EventID=4716) or (EventID=4717) or (EventID=4718) or (EventID=4719) or (EventID=4720) or (EventID=4722) or (EventID=4723) or (EventID=4724) or (EventID=4725) or (EventID=4726) or (EventID=4727) or (EventID=4728)]]",
            "Security!*[System[(EventID=4729) or (EventID=4733) or (EventID=4732) or (EventID=4735) or (EventID=4737) or (EventID=4738) or (EventID=4739) or (EventID=4740) or (EventID=4742) or (EventID=4744) or (EventID=4745) or (EventID=4746) or (EventID=4750) or (EventID=4751) or (EventID=4752)]]",
            "Security!*[System[(EventID=4754) or (EventID=4755) or (EventID=4756) or (EventID=4757) or (EventID=4760) or (EventID=4761) or (EventID=4762) or (EventID=4764) or (EventID=4767) or (EventID=4768) or (EventID=4771) or (EventID=4774) or (EventID=4778) or (EventID=4779) or (EventID=4781)]]",
            "Security!*[System[(EventID=4793) or (EventID=4797) or (EventID=4798) or (EventID=4799) or (EventID=4800) or (EventID=4801) or (EventID=4802) or (EventID=4803) or (EventID=4825) or (EventID=4826) or (EventID=4870) or (EventID=4886) or (EventID=4887) or (EventID=4888) or (EventID=4893)]]",
            "Security!*[System[(EventID=4898) or (EventID=4902) or (EventID=4904) or (EventID=4905) or (EventID=4907) or (EventID=4931) or (EventID=4932) or (EventID=4933) or (EventID=4946) or (EventID=4948) or (EventID=4956) or (EventID=4985) or (EventID=5024) or (EventID=5033) or (EventID=5059)]]",
            "Security!*[System[(EventID=5136) or (EventID=5137) or (EventID=5140) or (EventID=5145) or (EventID=5632) or (EventID=6144) or (EventID=6145) or (EventID=6272) or (EventID=6273) or (EventID=6278) or (EventID=6416) or (EventID=6423) or (EventID=6424) or (EventID=8001) or (EventID=8002)]]",
            "Security!*[System[(EventID=8003) or (EventID=8004) or (EventID=8005) or (EventID=8006) or (EventID=8007) or (EventID=8222) or (EventID=26401) or (EventID=30004)]]",
            "Microsoft-Windows-AppLocker/EXE and DLL!*[System[(EventID=8001) or (EventID=8002) or (EventID=8003) or (EventID=8004)]]",
            "Microsoft-Windows-AppLocker/MSI and Script!*[System[(EventID=8005) or (EventID=8006) or (EventID=8007)]]"
        )
    }
    "Minimal" {
        $xPathQueries = @(
            "Security!*[System[(EventID=1102) or (EventID=4624) or (EventID=4625) or (EventID=4657) or (EventID=4663) or (EventID=4688) or (EventID=4700) or (EventID=4702) or (EventID=4719) or (EventID=4720) or (EventID=4722) or (EventID=4723) or (EventID=4724) or (EventID=4727) or (EventID=4728)]]",
            "Security!*[System[(EventID=4732) or (EventID=4735) or (EventID=4737) or (EventID=4739) or (EventID=4740) or (EventID=4754) or (EventID=4755) or (EventID=4756) or (EventID=4767) or (EventID=4799) or (EventID=4825) or (EventID=4946) or (EventID=4948) or (EventID=4956) or (EventID=5024)]]",
            "Security!*[System[(EventID=5033) or (EventID=8222)]]",
            "Microsoft-Windows-AppLocker/EXE and DLL!*[System[(EventID=8001) or (EventID=8002) or (EventID=8003) or (EventID=8004)]]",
            "Microsoft-Windows-AppLocker/MSI and Script!*[System[(EventID=8005) or (EventID=8006) or (EventID=8007)]]"
        )
    }
    "Custom" {
        $xPathQueries = @($CustomEventFilter)
    }
    Default {}
}

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
                    "xPathQueries": [ <XPATH Queries> ],
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

$body = $body.Replace("<XPATH Queries>", '"' + ($xPathQueries -join '","') + '"')
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