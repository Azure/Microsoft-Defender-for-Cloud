Configuration MonitorAntivirus
{
    Import-DscResource -ModuleName EndPointProtectionDSC

    Node MonitorAntivirus
    {
        EPAntivirusStatus AV
        {
            AntivirusName = "Windows Defender"
            Status        = "Running"
            Ensure        = "Present"
        }
    }
}

cd $env:Temp
MonitorAntivirus