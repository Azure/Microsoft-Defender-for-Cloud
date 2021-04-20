#Init
$BuildPath = "C:\build-httpserver"
$RunPath = "C:\HttpServerApp"
$HttpServerSrcCodeUrl = $args[0]

New-Item -ItemType Directory $BuildPath
New-Item -ItemType Directory $RunPath

# Install .net 5 sdk + runtime
Invoke-WebRequest "https://dotnet.microsoft.com/download/dotnet/scripts/v1/dotnet-install.ps1" -OutFile $BuildPath\dotnet-install.ps1
cd $BuildPath
#installing SDK
.\dotnet-install.ps1 -Channel Current
#instaling runtime
.\dotnet-install.ps1 -Channel Current -Runtime dotnet

# Download Http Server src files app
Invoke-WebRequest $HttpServerSrcCodeUrl -OutFile httpServer.zip
#Unzip
Expand-Archive httpServer.zip -Force
cd $BuildPath\httpServer

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
