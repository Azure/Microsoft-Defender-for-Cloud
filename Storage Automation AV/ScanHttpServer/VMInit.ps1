#Init
$BuildPath = "C:\build-httpserver"
$RunPath = "C:\HttpServerApp"
$githubRepoUrl = "https://github.com/t-ashitrit/Azure-Security-Center/archive/AutomationAvForStorage.zip"
# https://github.com/Azure/Azure-Security-Center/archive/master.zip

New-Item -ItemType Directory $BuildPath
New-Item -ItemType Directory $RunPath

# Install .net 5 sdk + runtime
$isExist = Test-Path $BuildPath\dotnet-install.ps1
if (-Not $isExist){
    Invoke-WebRequest "https://dotnet.microsoft.com/download/dotnet/scripts/v1/dotnet-install.ps1" -OutFile $BuildPath\dotnet-install.ps1
}
cd $BuildPath
#installing SDK
.\dotnet-install.ps1 -Channel Current
#instaling runtime
.\dotnet-install.ps1 -Channel Current -Runtime dotnet

# Download Http Server src files app
if (-Not (Test-Path $BuildPath\ASC-Github.zip)){
    Invoke-WebRequest $githubRepoUrl -OutFile $BuildPath\ASC-Github.zip
}

if (-Not (Test-Path $BuildPath\ScanHttpServer\)){
    Expand-Archive $BuildPath\ASC-Github.zip -DestinationPath $BuildPath\ -Force
    Copy-Item -Path "$BuildPath\Azure-Security-Center-AutomationAvForStorage\Storage Automation AV\ScanHttpServer\" -Destination $BuildPath -Recurse
}
# ASC-Github\Azure-Security-Center-master\Storage Automation AV\ScanHttpServer\

cd $BuildPath\ScanHttpServer

#Publish the app
Write-Host Building the app
dotnet publish -c Release -o $RunPath
cd $RunPath

#Adding firewall rules to enable traffic
Write-Host adding firewall rules
netsh http add urlacl url="http://+:4151/" user=everyone
New-NetFirewallRule -DisplayName "allowing port 4151" -Direction Inbound -LocalPort 4151 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "allowing port 4151" -Direction Outbound -LocalPort 4151 -Protocol TCP -Action Allow

#Adding VMInit.ps1 as startup job
$trigger = New-JobTrigger -AtStartup -RandomDelay 00:00:30
Register-ScheduledJob -Trigger $trigger -FilePath $BuildPath\httpServer\VMInit.ps1 -Name InitVmScanning.

#Updating antivirus Signatures
Write-Host Updating Signatures for the antivirus
& "C:\Program Files\Windows Defender\MpCmdRun.exe" -SignatureUpdate

Copy-Item $BuildPath\httpServer\runLoop.ps1 -Destination $RunPath

#Running the App
Write-Host Starting Run-Loop
Start-Process powershell -ArgumentList ".\runLoop.ps1"
