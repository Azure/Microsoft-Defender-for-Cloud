$ScanHttpServerFolder = "C:\ScanHttpServer\bin"
$ExePath = "$ScanHttpServerFolder\ScanHttpServer.dll"
Write-Host Starting Process $ExePath
while($true){
    $process = Start-Process dotnet -ArgumentList $ExePath -PassThru -Wait
    
    if($process.ExitCode -ne 0){
        Write-Host Process Exited with errors, please check the logs in $ScanHttpServerFolder\log
    }
    else {
        Write-Host Proccess Exited with no errors
    }

    Write-Host Restarting Process $ExePath
}

Read-Host "press enter to continue"