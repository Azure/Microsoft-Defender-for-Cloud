function Get-EPDSCInstalledAntivirus
{ 
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param(
        [Parameter(Mandatory = $true)]
        [System.String]
        $AntivirusName,

        [Parameter()]
        [System.String]
        $ComputerName = "$env:computername"
    ) 
 
    $wmiQuery = "SELECT * FROM AntiVirusProduct WHERE displayName ='$AntivirusName'"
    $AntivirusProduct = $null
    try
    {
        $AntivirusProduct = Get-WmiObject -Namespace "root\SecurityCenter2" `
            -Query $wmiQuery `
            -ComputerName $ComputerName `
            -ErrorAction 'SilentlyContinue'
    }
    catch
    {
        Write-Verbose -Message "Couldn't obtain the list of installed Antivirus"
    }          
    return $AntivirusProduct
} 
  
function Get-EPDSCProcessByReportingExecutable
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param(
        [Parameter()]
        [System.String]
        $ExecutableName
    )

    $processInfo = $null
    try
    {
        $processInfo = Get-Process -Name $ExecutableName -ErrorAction SilentlyContinue
    }
    catch
    {
        Write-Verbose -Message "Could not find process running executable file {$ExecutableName}"
    }
    return $processInfo
}
