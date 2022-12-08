[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$url1 = "https://go.microsoft.com/fwlink/?linkid=2088631"
$localFolder1="c:\dotnet"
New-Item -Path $localFolder1 -ItemType Directory
$exePath1 = "c:\dotnet\4.8-net-runtime.exe"
$Wget1 = New-Object System.Net.WebClient
$Wget1.DownloadFile($url1, $exePath1)
cmd /c start /wait "$exePath1" /q /norestart
Remove-Item $exePath1 -Force -ErrorAction Ignore
Remove-Item $localFolder1 -Force -ErrorAction Ignore
