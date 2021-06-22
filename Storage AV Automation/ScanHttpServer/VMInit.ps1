#Init
$ScanHttpServerPath = "C:\ScanHttpServer"
$ExePath = "$ScanHttpServerPath\bin"

New-Item -ItemType Directory $ScanHttpServerPath
New-Item -ItemType Directory $ExePath

if($args.Count -gt 0){
    if(-Not (Test-Path $ExePath\vminit.config)){
        New-Item $ExePath\vminit.config
    }
    Set-Content $ExePath\vminit.config $args[0]
}

$ScanHttpServerBinZipUrl = Get-Content $ExePath\vminit.config

# Download Http Server bin files
Invoke-WebRequest $ScanHttpServerBinZipUrl -OutFile $ExePath\ScanHttpServer.zip
Expand-Archive $ExePath\ScanHttpServer.zip -DestinationPath $ExePath\ -Force
Copy-Item -Path "$ExePath\runLoop.ps1" -Destination $ScanHttpServerPath

cd $ScanHttpServerPath

#Adding firewall rules to enable traffic
Write-Host adding firewall rules
netsh http add urlacl url="http://+:4151/" user=everyone
New-NetFirewallRule -DisplayName "allowing port 4151" -Direction Inbound -LocalPort 4151 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "allowing port 4151" -Direction Outbound -LocalPort 4151 -Protocol TCP -Action Allow

#Adding VMInit.ps1 as startup job
$trigger = New-JobTrigger -AtStartup -RandomDelay 00:00:30
Register-ScheduledJob -Trigger $trigger -FilePath "$ScanHttpServerPath\runLoop.ps1" -Name StartRunLoopScanHttpServer

#Updating antivirus Signatures
Write-Host Updating Signatures for the antivirus
& "C:\Program Files\Windows Defender\MpCmdRun.exe" -SignatureUpdate

#Running the App
Write-Host Starting Run-Loop
Start-Process powershell -ArgumentList ".\runLoop.ps1"
