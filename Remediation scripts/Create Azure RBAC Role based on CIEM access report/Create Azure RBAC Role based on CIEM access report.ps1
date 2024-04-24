<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2022 v5.8.213
	 Created on:   	05-01-2024 18:41
	 Created by:   	Michael Morten Sonne
	 Organization: 	Sonne´s Cloud
	 Blog:          https://blog.sonnes.cloud
	 GitHub:        https://github.com/michaelmsonne
	 Filename:     	'Create Azure RBAC Role based on CIEM access report - used access scopes.ps1'
	===========================================================================
	.DESCRIPTION
		PowerShell script to create custom Azure RBAC role based on output from CIEM access report in CSV format.

        The script will prompt for the name and description of the custom role to be created.
        The script will prompt for confirmation before creating the custom role.
        The script will prompt for the path to the CSV file containing the CIEM access report.
        The script will prompt for the resource group or subscription to scope the custom role to.
        The script will prompt for confirmation before creating the custom role.

    .REQUREMENT
        - Azure subscription
        - Microsoft Azure PowerShell Az module (at least 'Az.Accounts' and 'Az.Resources')
        - Right permissions to create custom Azure RBAC roles (Owner or User Access Administrator, or custom role with Microsoft.Authorization/roleDefinitions/write permission)

    .CHANGELOG
        05-01-2024 - Michael Morten Sonne - Initial release
        06-02-2024 - Michael Morten Sonne - Some small changes to the script and add GridView for large datasets if needed (some work done too before here but not documented)
        07-03-2024 - Michael Morten Sonne - Some small changes and typos fixed and added try/catch to the script for install of Az modules

	.EXAMPLE
        Create a custom Azure RBAC role based on CIEM access report in CSV format and display the unique access scopes and count in the console
        PS C:\> .\'Create Azure RBAC Role based on CIEM access report - used access scopes.ps1' -CsvFilePath "C:\Users\MichaelMortenSonne\Actions.csv"

        Create a custom Azure RBAC role based on CIEM access report in CSV format and display the unique access scopes and count in a grid view (usefull for large datasets)
        PS C:\> .\'Create Azure RBAC Role based on CIEM access report - used access scopes.ps1' -GridView -CsvFilePath "C:\Users\MichaelMortenSonne\Actions.csv"
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$CsvFilePath,

    [Parameter(Mandatory=$false)]
    [switch]$GridView = $null,

    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup
)

function Invoke-Script
{
    <# 
    .SYNOPSIS
        Starts the script and checks for required modules and login to Azure

    .EXAMPLE 
        Invoke-Script -Banner
    #>

    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$false)][switch]$Checks = $null,
    [Parameter(Mandatory=$false)][switch]$CheckLogin = $null,
    [Parameter(Mandatory=$false)][switch]$Banner = $null)

    # Check if the user is logged in to Azure
    If ($CheckLogin)
    {
        #Login Check
        $AZSUser = Get-AzContext
        if(!$AZSUser)
        {
            # Prompt the user to login to Azure
            Write-Host "Please login with Connect-AzAccount - see popup promt" -ForegroundColor Yellow
            
            # Try to connect to Azure via Az module
            try{
                # Connect to Azure via Az module
                Connect-AzAccount
            }catch{
                # Failed to connect to Azure
                Write-Host "Failed to call Connect-AzAccount: $($_.Exception.Message)" -ForegroundColor Red
                return $False
            }
        }
    }

    # Check if the required modules are installed and supported PowerShell version
    If($Checks)
    {
        # Set ErrorActionPreference to Stop
        $ErrorActionPreference = "Stop"

        # Check for supported PowerShell version
        $Version = $PSVersionTable.PSVersion.Major
        If ($Version -lt 5)
        {
            # PowerShell version is not supported - 5.1 or later is required
            Write-Host "Az requires at least PowerShell 5.1 - Exiting..." -ForegroundColor Red
            Exit
        }

        # Check Modules Az.Accounts and Az.Resources is installed
        $Modules = Get-InstalledModule
        if ($Modules.Name -notcontains 'Az.Accounts' -and $Modules.Name -notcontains 'Az.Resources')
        {
            # Az PowerShell Modules not installed - prompt the user to install the modules
            Write-host "Install Az PowerShell Modules?" -ForegroundColor Yellow 
            $Readhost = Read-Host " ( y / n ) " 

            # Install Az PowerShell Modules if the user confirms
            if ($ReadHost -eq 'y' -or $Readhost -eq 'yes')
            {
                try {
                    # Install Az PowerShell Modules
                    Install-Module -Name Az -AllowClobber -Scope CurrentUser

                    # Get installed modules
                    $Modules = Get-InstalledModule

                    # Check if the Az PowerShell Modules are installed
                    if ($Modules.Name -contains 'Az.Accounts' -and $Modules.Name -contains 'Az.Resources')
                    {
                        Write-Host "Successfully installed Az modules" -ForegroundColor Green
                    }
                }
                catch {
                    # Failed to install Az PowerShell Modules show error message
                    Write-Host "Failed to install Az modules: $($_.Exception.Message)" -ForegroundColor Red
                }                
            }
            # Exit if the user does not confirm to install the Az PowerShell Modules
            if ($ReadHost -eq 'n' -or $Readhost -eq 'no') 
            {
                # User did not confirm to install the Az PowerShell Modules - exit
                Write-Host "Az PowerShell not installed, This script cannot operate without this modules, exiting..." -ForegroundColor Red
                Exit
            }
        }
        else
        {
            # Az PowerShell Modules needed is installed!
            Write-Host "Az PowerShell Modules needed is installed - good!`n" -ForegroundColor Green
        }

        #Login Check
        $AZSStartUser = Get-AzContext
        if(!$AZSStartUser)
        {
            Write-Host "Remember to login with Connect-AzAccount if you will create a custom role in Azure RBAC!`n" -ForegroundColor Yellow
        }
    }

    # Banner
    if($Banner)
    {
        Write-Host "Please set your default subscription with " -ForegroundColor yellow -NoNewline 
        Write-Host "Set-AzContext " -ForegroundColor Magenta -NoNewline
        Write-Host "if you have multiple subscriptions. Functions will fail if you not set one. Use "  -ForegroundColor yellow -NoNewline 
        Write-Host "Get-AzSubscription" -ForegroundColor Magenta -NoNewline
        Write-Host " to get a list of your subscriptions.`n" -ForegroundColor Yellow
    }

    # If not logged in to Azure
    if(!$Checks -and !$CheckLogin -and !$Banner)
    {
        Write-Host "Please login with Connect-AzAccount" -ForegroundColor Red
	}            
}

function CheckConnectionToAzure {
    # Check if connected to Azure
    $azContext = Get-AzContext -ErrorAction SilentlyContinue

    # If connected to Azure
    if ($azContext) {
        # If connected to Azure - prompt for logout if connected to Azure before exiting the script
        Write-Host "You are currently connected to Azure." -ForegroundColor Yellow
        $confirmLogout = Read-Host "Do you want to log out from Azure? (Type 'yes' to confirm)"

        # Check user confirmation
        if ($confirmLogout.ToLower() -eq 'yes' -or $confirmLogout.ToLower() -eq 'y') {
            try {
                # Log out from Azure
                Disconnect-AzAccount

                # Show logged out from Azure
                Write-Host "Logged out from Azure." -ForegroundColor Green
            } catch {
                # Show error message if failed to log out from Azure
                Write-Host "Not logged out from Azure." -ForegroundColor Red
                Write-Host "An error occurred while logging out from Azure: $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            # Show message if the user selected to not logout from Azure - Session is active in your console
            Write-Host "You selected to not logout from Azure - Session is active in your console." -ForegroundColor Red
        }
    } else {
        # Show message if not connected to Azure - do nothing
        Write-Host "You are not currently connected to Azure." -ForegroundColor Green
    }
}

# Start the script and check for required modules
Invoke-Script -Checks

# Read the CSV file
$data = Import-Csv -Path $CsvFilePath

# Extracting just the filename from the $CsvFilePath
$csvFileName = (Get-Item $CsvFilePath).Name

# Filter out rows where 'used' is not empty
$usedData = $data | Where-Object { $_.used -ne "" } | Select-Object -ExpandProperty used

if ($usedData.Count -gt 0) {
    # Filter out empty values and split the access scopes
    $accessScopes = $usedData -split ',' | Where-Object { $_ -ne "" } | ForEach-Object { $_.Trim() }

    # Count the unique access scopes
    $uniqueAccessScopes = $accessScopes | Sort-Object -Unique
    $numberOfAccessScopes = $uniqueAccessScopes.Count

    # Display the unique access scopes and count in a grid view or in the console
    if ($GridView){
        # Create a custom object with renamed columns
        $customuniqueAccessScopes = $uniqueAccessScopes | ForEach-Object {
            [PSCustomObject]@{
                'Custom Azure RBAC Scopes to use in new role' = $_ # Custom column name
            }
        }

        # Display the unique access scopes and count in a grid view
        $customuniqueAccessScopes | Out-GridView -Title "$numberOfAccessScopes Unique access scopes discovered within the exported file '$csvFileName' and are intended for use in a new custom Azure RBAC role" -PassThru
    }
    else {
        # Display the unique access scopes and count
        Write-Host "Unique access scopes were discovered within the exported file '$csvFileName' and are intended for use in a new custom Azure RBAC role:`n"
        
        # Display the unique access scopes
        $uniqueAccessScopes

        # Display the number of unique access scopes
        Write-Host "`nNumber of Unique Access Scopes: " -NoNewline
        Write-Host $numberOfAccessScopes `n -ForegroundColor Yellow
    }
} else {
    # No 'used' data found in the CSV file - abort
    Write-Host "`nNo 'used' data found. Aborting..."
    exit
}

# Prompt user confirmation
$confirmation = Read-Host "Do you want to proceed and create a custom role in Azure RBAC? (Type 'yes' to confirm)"

# Check user confirmation
if ($confirmation.ToLower() -eq "yes" -or $confirmation.ToLower() -eq "y") {
    # Create a new role definition - Ensure you have the necessary permissions and provide the required role definition details

    # Start the script and check for login
    Invoke-Script -CheckLogin

    # Get the current subscription data
    $subscriptionID = (Get-AzContext).Subscription.Id
    $subscriptionName = (Get-AzContext).Subscription.Name

    # Show the current Azure Subscription
    Write-Host "Current Azure Subscription for your session:`nID: $subscriptionID`nName: $subscriptionName`n"

    # Start the script and check for used subscription
    Invoke-Script -Banner

    # Prompt user confirmation
    $confirmation = Read-Host "Is the Azure Subscription above the correct one you will work with? (Type 'yes' to confirm)"

    # Check user confirmation
    if ($confirmation.ToLower() -eq "yes" -or $confirmation.ToLower() -eq "y")
    {
        # Ask for role name
        $var_RoleName = Read-Host "Enter the name of the custom role to be created"

        # Ask for role description
        $var_Description = Read-Host "Enter the description of the custom role to be created"

        # Create a new role definition - copy the role definition and update the name, description, and access scopes to match the exported data from CIEM
        $role = Get-AzRoleDefinition -Name "Reader"

        # Blank the ID to prevent overwriting
        $role.Id = $null
        $role.Name = $var_RoleName
        $role.Description = $var_Description

        # Initialize actions collections
        $role.actions = New-Object System.Collections.Generic.List[string]

        # Add access scopes to the role definition
        foreach ($scope in $accessScopes) {
            $role.Actions.Add($scope)
        }

        # Clear the assignable scopes and add the subscription ID as the assignable scope
        $role.AssignableScopes.Clear()
        if (-not $ResourceGroup) {
            $role.AssignableScopes.Add("/subscriptions/$subscriptionID")
        } else {
            $role.AssignableScopes.Add("/subscriptions/$subscriptionID/resourceGroups/$ResourceGroup/")
        }

        # Display the role definition is about to be created
        Write-Host "Creating custom role in Azure RBAC..." -ForegroundColor Yellow

        # Create the custom role in Azure RBAC
        try {
            New-AzRoleDefinition -Role $role
            Write-Host "Azure role definition created successfully.`n" -ForegroundColor Green
        } catch {
            Write-Host "An error occurred while creating the Azure role definition: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    else {
        Write-Host "Operation canceled. Set the current Azure Subscription to use."
    }    
} else {
    Write-Host "Operation canceled. Custom role creation aborted!"
}

# Check if connected to Azure and prompt for logout if connected to Azure before exiting the script
CheckConnectionToAzure
# SIG # Begin signature block
# MIIo7QYJKoZIhvcNAQcCoIIo3jCCKNoCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAMKZ+su5SIxycd
# pLpFwEwEgfIgiOp0ucQzt3opL534d6CCEd8wggVvMIIEV6ADAgECAhBI/JO0YFWU
# jTanyYqJ1pQWMA0GCSqGSIb3DQEBDAUAMHsxCzAJBgNVBAYTAkdCMRswGQYDVQQI
# DBJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNVBAcMB1NhbGZvcmQxGjAYBgNVBAoM
# EUNvbW9kbyBDQSBMaW1pdGVkMSEwHwYDVQQDDBhBQUEgQ2VydGlmaWNhdGUgU2Vy
# dmljZXMwHhcNMjEwNTI1MDAwMDAwWhcNMjgxMjMxMjM1OTU5WjBWMQswCQYDVQQG
# EwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMS0wKwYDVQQDEyRTZWN0aWdv
# IFB1YmxpYyBDb2RlIFNpZ25pbmcgUm9vdCBSNDYwggIiMA0GCSqGSIb3DQEBAQUA
# A4ICDwAwggIKAoICAQCN55QSIgQkdC7/FiMCkoq2rjaFrEfUI5ErPtx94jGgUW+s
# hJHjUoq14pbe0IdjJImK/+8Skzt9u7aKvb0Ffyeba2XTpQxpsbxJOZrxbW6q5KCD
# J9qaDStQ6Utbs7hkNqR+Sj2pcaths3OzPAsM79szV+W+NDfjlxtd/R8SPYIDdub7
# P2bSlDFp+m2zNKzBenjcklDyZMeqLQSrw2rq4C+np9xu1+j/2iGrQL+57g2extme
# me/G3h+pDHazJyCh1rr9gOcB0u/rgimVcI3/uxXP/tEPNqIuTzKQdEZrRzUTdwUz
# T2MuuC3hv2WnBGsY2HH6zAjybYmZELGt2z4s5KoYsMYHAXVn3m3pY2MeNn9pib6q
# RT5uWl+PoVvLnTCGMOgDs0DGDQ84zWeoU4j6uDBl+m/H5x2xg3RpPqzEaDux5mcz
# mrYI4IAFSEDu9oJkRqj1c7AGlfJsZZ+/VVscnFcax3hGfHCqlBuCF6yH6bbJDoEc
# QNYWFyn8XJwYK+pF9e+91WdPKF4F7pBMeufG9ND8+s0+MkYTIDaKBOq3qgdGnA2T
# OglmmVhcKaO5DKYwODzQRjY1fJy67sPV+Qp2+n4FG0DKkjXp1XrRtX8ArqmQqsV/
# AZwQsRb8zG4Y3G9i/qZQp7h7uJ0VP/4gDHXIIloTlRmQAOka1cKG8eOO7F/05QID
# AQABo4IBEjCCAQ4wHwYDVR0jBBgwFoAUoBEKIz6W8Qfs4q8p74Klf9AwpLQwHQYD
# VR0OBBYEFDLrkpr/NZZILyhAQnAgNpFcF4XmMA4GA1UdDwEB/wQEAwIBhjAPBgNV
# HRMBAf8EBTADAQH/MBMGA1UdJQQMMAoGCCsGAQUFBwMDMBsGA1UdIAQUMBIwBgYE
# VR0gADAIBgZngQwBBAEwQwYDVR0fBDwwOjA4oDagNIYyaHR0cDovL2NybC5jb21v
# ZG9jYS5jb20vQUFBQ2VydGlmaWNhdGVTZXJ2aWNlcy5jcmwwNAYIKwYBBQUHAQEE
# KDAmMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5jb21vZG9jYS5jb20wDQYJKoZI
# hvcNAQEMBQADggEBABK/oe+LdJqYRLhpRrWrJAoMpIpnuDqBv0WKfVIHqI0fTiGF
# OaNrXi0ghr8QuK55O1PNtPvYRL4G2VxjZ9RAFodEhnIq1jIV9RKDwvnhXRFAZ/ZC
# J3LFI+ICOBpMIOLbAffNRk8monxmwFE2tokCVMf8WPtsAO7+mKYulaEMUykfb9gZ
# pk+e96wJ6l2CxouvgKe9gUhShDHaMuwV5KZMPWw5c9QLhTkg4IUaaOGnSDip0TYl
# d8GNGRbFiExmfS9jzpjoad+sPKhdnckcW67Y8y90z7h+9teDnRGWYpquRRPaf9xH
# +9/DUp/mBlXpnYzyOmJRvOwkDynUWICE5EV7WtgwggYaMIIEAqADAgECAhBiHW0M
# UgGeO5B5FSCJIRwKMA0GCSqGSIb3DQEBDAUAMFYxCzAJBgNVBAYTAkdCMRgwFgYD
# VQQKEw9TZWN0aWdvIExpbWl0ZWQxLTArBgNVBAMTJFNlY3RpZ28gUHVibGljIENv
# ZGUgU2lnbmluZyBSb290IFI0NjAeFw0yMTAzMjIwMDAwMDBaFw0zNjAzMjEyMzU5
# NTlaMFQxCzAJBgNVBAYTAkdCMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxKzAp
# BgNVBAMTIlNlY3RpZ28gUHVibGljIENvZGUgU2lnbmluZyBDQSBSMzYwggGiMA0G
# CSqGSIb3DQEBAQUAA4IBjwAwggGKAoIBgQCbK51T+jU/jmAGQ2rAz/V/9shTUxjI
# ztNsfvxYB5UXeWUzCxEeAEZGbEN4QMgCsJLZUKhWThj/yPqy0iSZhXkZ6Pg2A2NV
# DgFigOMYzB2OKhdqfWGVoYW3haT29PSTahYkwmMv0b/83nbeECbiMXhSOtbam+/3
# 6F09fy1tsB8je/RV0mIk8XL/tfCK6cPuYHE215wzrK0h1SWHTxPbPuYkRdkP05Zw
# mRmTnAO5/arnY83jeNzhP06ShdnRqtZlV59+8yv+KIhE5ILMqgOZYAENHNX9SJDm
# +qxp4VqpB3MV/h53yl41aHU5pledi9lCBbH9JeIkNFICiVHNkRmq4TpxtwfvjsUe
# dyz8rNyfQJy/aOs5b4s+ac7IH60B+Ja7TVM+EKv1WuTGwcLmoU3FpOFMbmPj8pz4
# 4MPZ1f9+YEQIQty/NQd/2yGgW+ufflcZ/ZE9o1M7a5Jnqf2i2/uMSWymR8r2oQBM
# dlyh2n5HirY4jKnFH/9gRvd+QOfdRrJZb1sCAwEAAaOCAWQwggFgMB8GA1UdIwQY
# MBaAFDLrkpr/NZZILyhAQnAgNpFcF4XmMB0GA1UdDgQWBBQPKssghyi47G9IritU
# pimqF6TNDDAOBgNVHQ8BAf8EBAMCAYYwEgYDVR0TAQH/BAgwBgEB/wIBADATBgNV
# HSUEDDAKBggrBgEFBQcDAzAbBgNVHSAEFDASMAYGBFUdIAAwCAYGZ4EMAQQBMEsG
# A1UdHwREMEIwQKA+oDyGOmh0dHA6Ly9jcmwuc2VjdGlnby5jb20vU2VjdGlnb1B1
# YmxpY0NvZGVTaWduaW5nUm9vdFI0Ni5jcmwwewYIKwYBBQUHAQEEbzBtMEYGCCsG
# AQUFBzAChjpodHRwOi8vY3J0LnNlY3RpZ28uY29tL1NlY3RpZ29QdWJsaWNDb2Rl
# U2lnbmluZ1Jvb3RSNDYucDdjMCMGCCsGAQUFBzABhhdodHRwOi8vb2NzcC5zZWN0
# aWdvLmNvbTANBgkqhkiG9w0BAQwFAAOCAgEABv+C4XdjNm57oRUgmxP/BP6YdURh
# w1aVcdGRP4Wh60BAscjW4HL9hcpkOTz5jUug2oeunbYAowbFC2AKK+cMcXIBD0Zd
# OaWTsyNyBBsMLHqafvIhrCymlaS98+QpoBCyKppP0OcxYEdU0hpsaqBBIZOtBajj
# cw5+w/KeFvPYfLF/ldYpmlG+vd0xqlqd099iChnyIMvY5HexjO2AmtsbpVn0OhNc
# WbWDRF/3sBp6fWXhz7DcML4iTAWS+MVXeNLj1lJziVKEoroGs9Mlizg0bUMbOalO
# hOfCipnx8CaLZeVme5yELg09Jlo8BMe80jO37PU8ejfkP9/uPak7VLwELKxAMcJs
# zkyeiaerlphwoKx1uHRzNyE6bxuSKcutisqmKL5OTunAvtONEoteSiabkPVSZ2z7
# 6mKnzAfZxCl/3dq3dUNw4rg3sTCggkHSRqTqlLMS7gjrhTqBmzu1L90Y1KWN/Y5J
# KdGvspbOrTfOXyXvmPL6E52z1NZJ6ctuMFBQZH3pwWvqURR8AgQdULUvrxjUYbHH
# j95Ejza63zdrEcxWLDX6xWls/GDnVNueKjWUH3fTv1Y8Wdho698YADR7TNx8X8z2
# Bev6SivBBOHY+uqiirZtg0y9ShQoPzmCcn63Syatatvx157YK9hlcPmVoa1oDE5/
# L9Uo2bC5a4CH2RwwggZKMIIEsqADAgECAhAR4aCGZIeugmCCjSjwUXrGMA0GCSqG
# SIb3DQEBDAUAMFQxCzAJBgNVBAYTAkdCMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0
# ZWQxKzApBgNVBAMTIlNlY3RpZ28gUHVibGljIENvZGUgU2lnbmluZyBDQSBSMzYw
# HhcNMjMwMjE5MDAwMDAwWhcNMjYwNTE4MjM1OTU5WjBhMQswCQYDVQQGEwJESzEU
# MBIGA1UECAwLSG92ZWRzdGFkZW4xHTAbBgNVBAoMFE1pY2hhZWwgTW9ydGVuIFNv
# bm5lMR0wGwYDVQQDDBRNaWNoYWVsIE1vcnRlbiBTb25uZTCCAiIwDQYJKoZIhvcN
# AQEBBQADggIPADCCAgoCggIBALVGIWG57aPiOruK3bg3tlPMHol1pfnEQiCkYom7
# hFXLVxhGve4OcQmx9xtKy7QIHmbHdH3Vc4J4foS0/bv4cnzYRd0g2qcTjo0Q+b5J
# RUSZQ0yUbLyHJf1TkCJOODWORJlsi/xppcQdAbU7QX2KFE4NkQzNUIOTSlKctx99
# ZqFevKIvwhkmIoB+WWnl/qS4ipFMO/d4m7o8IIgi49LPq3tVxZs0aJ6N02X5Xp2F
# oG2fZynudHIf9waYFtYXA3B8msQwaREpQY880Kki/275pSC+T8+mbnbwrKXOZ8Gj
# W2vvEJZe5ySIrA27omMsBnmoZYkiNMmMGYWQiZ5E75ZIiZ4UqWpuahoGpBLoZNX+
# TjKFFuqmo8EqfYdCpLiYgw95q3gHONu6TwTg01WwaeZFtlhx8qSgD8x7L/SRn4qn
# x//ucBg1Q0f3Al6lz++z8t4ty6CxF/Wr9ZKOoYhHft6SAE7Td9VGdWJLkp6cY1qf
# rq+QA+xR7rjFi7dagxvP1RzZqeh5glAQ74g3/lZJdgDTv/yB/zjxj6dHjzwii501
# VW4ecSX9RQpwWbleDDriDbVNJxwz37mBcSQykGXVfVV8AcdXn1zvEDkdshtLUGAL
# 6q61CugAE4LoOWohBEtk7dV2X0rvEY3Wce47ATLY14VM5gQCEsRxkEqt1HwdK4R+
# v/LtAgMBAAGjggGJMIIBhTAfBgNVHSMEGDAWgBQPKssghyi47G9IritUpimqF6TN
# DDAdBgNVHQ4EFgQUdfN+UjqPPYYWLqh4zXaTNj8AfJswDgYDVR0PAQH/BAQDAgeA
# MAwGA1UdEwEB/wQCMAAwEwYDVR0lBAwwCgYIKwYBBQUHAwMwSgYDVR0gBEMwQTA1
# BgwrBgEEAbIxAQIBAwIwJTAjBggrBgEFBQcCARYXaHR0cHM6Ly9zZWN0aWdvLmNv
# bS9DUFMwCAYGZ4EMAQQBMEkGA1UdHwRCMEAwPqA8oDqGOGh0dHA6Ly9jcmwuc2Vj
# dGlnby5jb20vU2VjdGlnb1B1YmxpY0NvZGVTaWduaW5nQ0FSMzYuY3JsMHkGCCsG
# AQUFBwEBBG0wazBEBggrBgEFBQcwAoY4aHR0cDovL2NydC5zZWN0aWdvLmNvbS9T
# ZWN0aWdvUHVibGljQ29kZVNpZ25pbmdDQVIzNi5jcnQwIwYIKwYBBQUHMAGGF2h0
# dHA6Ly9vY3NwLnNlY3RpZ28uY29tMA0GCSqGSIb3DQEBDAUAA4IBgQBF8qhaDXok
# 5R784NqfjMsNfS97H+ItE+Sxm/QMcIhTiiIBhIYd/lLfdTwpz5aqTl5M4+FDBDeN
# m0mjY8k2Cdg+DOf4JfvZAv4tQVybhEd42E5NTfG5sWN6ruMjBLpSsjwVzvonmeUL
# SwnXY+AtVSag0MU/UnyFOTS69gTjOq3EC+H/OJa/DfI8T/sDICzTy55c5aCDHRXb
# 6Dsr+Hm7PiGCQ6c0AhYOt/etXK1+YjQo9T+FcIF0Ze34CKirIRa1FFe26gNjHdpr
# MA62TOXQJrK+x9DtVY8QCb+IUZNYj6lNiXno3t69JN6FvIU2EtPrKs8SBV2uDZQM
# ecNJ+3w77/EHod82uB73vGiOvX8Q2CkdMunz+VfXyY4Oh10AEnCqzl0UV2HHH66H
# sa8Zti+kXWH9HTUkDJCd2VHdDEOJ0o2kA1/SfETMPAO/yeFz1xXy6CIJ50dkfzuY
# gf9SsIAod1Dx9THs2qkXIwyf5lTJBvPHLRqxs/k+Mn70AUiyj50/JYMxghZkMIIW
# YAIBATBoMFQxCzAJBgNVBAYTAkdCMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQx
# KzApBgNVBAMTIlNlY3RpZ28gUHVibGljIENvZGUgU2lnbmluZyBDQSBSMzYCEBHh
# oIZkh66CYIKNKPBResYwDQYJYIZIAWUDBAIBBQCgfDAQBgorBgEEAYI3AgEMMQIw
# ADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYK
# KwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgIzbpLjtzs1kgX1MFCg9dIMrqDsZD
# HeCZXQFn5NMQOUEwDQYJKoZIhvcNAQEBBQAEggIAfpKZkrQdGIH8vY3huyOC2Ejl
# zav2xeJBml518ha6lgC8bqjAB3evtZcTDpUvfE+On64BoezADAfQ2UbvtqN70+0f
# 9xt7NnMgu21QWSa+3atqgm8X+Kg+6PVaN5v48ex5vUl/NA5c/LMMICdgrebKn+A0
# APpy/J93S1XheUEX0gaFFHOyYzcytzFz3vTPXTUSULFgYyWXpXJGfpk5+pyDjpkb
# uavweXt12SS6UIHgb0GsYSFVLPg6QtdCMd8NfiEBFqmpgUPvEONCzjLZxuE7gcJD
# Sy+u4BHrMlRHf133cueQE23qFP1dtbbSMzFkKOMQXi53CJ/B1gun6dwv8yk+wvKy
# 0f6I178CgmUER7j2d/62RpS6Lj0MotAzq0yKaJOeW0qNMYBM3K2ThuoVneJ1BYLW
# PQV6/80OgYl0GQs0MLzEFsziMGjeTu8tko3GyHLPPeUILOqlOa75iAhchmD1Lh+D
# 5T0dSQNaKHsic9B5Akvh1wxgwNFI2u7i0ColaiFm1o87F/7NBoMpgDVY04+rmEvi
# Qr3pDgnHLHvvtgxpCn9xffT7vtQpgax/WUGITibSMJpnw6nQAxkQyKMIKT/QZUh8
# 9mAYSn7GFTXdj7XpFNyffWsKSuRF4Y84hqpO13fubrhbWdtWgNRMF81hjeMlsHdR
# DXSc6Tcvi+8IACKBsLuhghNPMIITSwYKKwYBBAGCNwMDATGCEzswghM3BgkqhkiG
# 9w0BBwKgghMoMIITJAIBAzEPMA0GCWCGSAFlAwQCAgUAMIHwBgsqhkiG9w0BCRAB
# BKCB4ASB3TCB2gIBAQYKKwYBBAGyMQIBATAxMA0GCWCGSAFlAwQCAQUABCBlQ8i8
# MYy10uxTy0aHh3zM0EAerJn5nufbcmwiYuF6WQIVAJRGXC+QofEsS8vXQV7ozdAs
# 8W8jGA8yMDI0MDMwOTE0NDAxN1qgbqRsMGoxCzAJBgNVBAYTAkdCMRMwEQYDVQQI
# EwpNYW5jaGVzdGVyMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxLDAqBgNVBAMM
# I1NlY3RpZ28gUlNBIFRpbWUgU3RhbXBpbmcgU2lnbmVyICM0oIIN6TCCBvUwggTd
# oAMCAQICEDlMJeF8oG0nqGXiO9kdItQwDQYJKoZIhvcNAQEMBQAwfTELMAkGA1UE
# BhMCR0IxGzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMHU2Fs
# Zm9yZDEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSUwIwYDVQQDExxTZWN0aWdv
# IFJTQSBUaW1lIFN0YW1waW5nIENBMB4XDTIzMDUwMzAwMDAwMFoXDTM0MDgwMjIz
# NTk1OVowajELMAkGA1UEBhMCR0IxEzARBgNVBAgTCk1hbmNoZXN0ZXIxGDAWBgNV
# BAoTD1NlY3RpZ28gTGltaXRlZDEsMCoGA1UEAwwjU2VjdGlnbyBSU0EgVGltZSBT
# dGFtcGluZyBTaWduZXIgIzQwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoIC
# AQCkkyhSS88nh3akKRyZOMDnDtTRHOxoywFk5IrNd7BxZYK8n/yLu7uVmPslEY5a
# iAlmERRYsroiW+b2MvFdLcB6og7g4FZk7aHlgSByIGRBbMfDCPrzfV3vIZrCftcs
# w7oRmB780yAIQrNfv3+IWDKrMLPYjHqWShkTXKz856vpHBYusLA4lUrPhVCrZwMl
# obs46Q9vqVqakSgTNbkf8z3hJMhrsZnoDe+7TeU9jFQDkdD8Lc9VMzh6CRwH0SLg
# Y4anvv3Sg3MSFJuaTAlGvTS84UtQe3LgW/0Zux88ahl7brstRCq+PEzMrIoEk8ZX
# hqBzNiuBl/obm36Ih9hSeYn+bnc317tQn/oYJU8T8l58qbEgWimro0KHd+D0TAJI
# 3VilU6ajoO0ZlmUVKcXtMzAl5paDgZr2YGaQWAeAzUJ1rPu0kdDF3QFAaraoEO72
# jXq3nnWv06VLGKEMn1ewXiVHkXTNdRLRnG/kXg2b7HUm7v7T9ZIvUoXo2kRRKqLM
# AMqHZkOjGwDvorWWnWKtJwvyG0rJw5RCN4gghKiHrsO6I3J7+FTv+GsnsIX1p0OF
# 2Cs5dNtadwLRpPr1zZw9zB+uUdB7bNgdLRFCU3F0wuU1qi1SEtklz/DT0JFDEtcy
# fZhs43dByP8fJFTvbq3GPlV78VyHOmTxYEsFT++5L+wJEwIDAQABo4IBgjCCAX4w
# HwYDVR0jBBgwFoAUGqH4YRkgD8NBd0UojtE1XwYSBFUwHQYDVR0OBBYEFAMPMciR
# KpO9Y/PRXU2kNA/SlQEYMA4GA1UdDwEB/wQEAwIGwDAMBgNVHRMBAf8EAjAAMBYG
# A1UdJQEB/wQMMAoGCCsGAQUFBwMIMEoGA1UdIARDMEEwNQYMKwYBBAGyMQECAQMI
# MCUwIwYIKwYBBQUHAgEWF2h0dHBzOi8vc2VjdGlnby5jb20vQ1BTMAgGBmeBDAEE
# AjBEBgNVHR8EPTA7MDmgN6A1hjNodHRwOi8vY3JsLnNlY3RpZ28uY29tL1NlY3Rp
# Z29SU0FUaW1lU3RhbXBpbmdDQS5jcmwwdAYIKwYBBQUHAQEEaDBmMD8GCCsGAQUF
# BzAChjNodHRwOi8vY3J0LnNlY3RpZ28uY29tL1NlY3RpZ29SU0FUaW1lU3RhbXBp
# bmdDQS5jcnQwIwYIKwYBBQUHMAGGF2h0dHA6Ly9vY3NwLnNlY3RpZ28uY29tMA0G
# CSqGSIb3DQEBDAUAA4ICAQBMm2VY+uB5z+8VwzJt3jOR63dY4uu9y0o8dd5+lG3D
# IscEld9laWETDPYMnvWJIF7Bh8cDJMrHpfAm3/j4MWUN4OttUVemjIRSCEYcKsLe
# 8tqKRfO+9/YuxH7t+O1ov3pWSOlh5Zo5d7y+upFkiHX/XYUWNCfSKcv/7S3a/76T
# DOxtog3Mw/FuvSGRGiMAUq2X1GJ4KoR5qNc9rCGPcMMkeTqX8Q2jo1tT2KsAulj7
# NYBPXyhxbBlewoNykK7gxtjymfvqtJJlfAd8NUQdrVgYa2L73mzECqls0yFGcNwv
# jXVMI8JB0HqWO8NL3c2SJnR2XDegmiSeTl9O048P5RNPWURlS0Nkz0j4Z2e5Tb/M
# DbE6MNChPUitemXk7N/gAfCzKko5rMGk+al9NdAyQKCxGSoYIbLIfQVxGksnNqrg
# mByDdefHfkuEQ81D+5CXdioSrEDBcFuZCkD6gG2UYXvIbrnIZ2ckXFCNASDeB/cB
# 1PguEc2dg+X4yiUcRD0n5bCGRyoLG4R2fXtoT4239xO07aAt7nMP2RC6nZksfNd1
# H48QxJTmfiTllUqIjCfWhWYd+a5kdpHoSP7IVQrtKcMf3jimwBT7Mj34qYNiNsjD
# vgCHHKv6SkIciQPc9Vx8cNldeE7un14g5glqfCsIo0j1FfwET9/NIRx65fWOGtS5
# QDCCBuwwggTUoAMCAQICEDAPb6zdZph0fKlGNqd4LbkwDQYJKoZIhvcNAQEMBQAw
# gYgxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpOZXcgSmVyc2V5MRQwEgYDVQQHEwtK
# ZXJzZXkgQ2l0eTEeMBwGA1UEChMVVGhlIFVTRVJUUlVTVCBOZXR3b3JrMS4wLAYD
# VQQDEyVVU0VSVHJ1c3QgUlNBIENlcnRpZmljYXRpb24gQXV0aG9yaXR5MB4XDTE5
# MDUwMjAwMDAwMFoXDTM4MDExODIzNTk1OVowfTELMAkGA1UEBhMCR0IxGzAZBgNV
# BAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEYMBYGA1UE
# ChMPU2VjdGlnbyBMaW1pdGVkMSUwIwYDVQQDExxTZWN0aWdvIFJTQSBUaW1lIFN0
# YW1waW5nIENBMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAyBsBr9ks
# foiZfQGYPyCQvZyAIVSTuc+gPlPvs1rAdtYaBKXOR4O168TMSTTL80VlufmnZBYm
# CfvVMlJ5LsljwhObtoY/AQWSZm8hq9VxEHmH9EYqzcRaydvXXUlNclYP3MnjU5g6
# Kh78zlhJ07/zObu5pCNCrNAVw3+eolzXOPEWsnDTo8Tfs8VyrC4Kd/wNlFK3/B+V
# cyQ9ASi8Dw1Ps5EBjm6dJ3VV0Rc7NCF7lwGUr3+Az9ERCleEyX9W4L1GnIK+lJ2/
# tCCwYH64TfUNP9vQ6oWMilZx0S2UTMiMPNMUopy9Jv/TUyDHYGmbWApU9AXn/TGs
# +ciFF8e4KRmkKS9G493bkV+fPzY+DjBnK0a3Na+WvtpMYMyou58NFNQYxDCYdIIh
# z2JWtSFzEh79qsoIWId3pBXrGVX/0DlULSbuRRo6b83XhPDX8CjFT2SDAtT74t7x
# vAIo9G3aJ4oG0paH3uhrDvBbfel2aZMgHEqXLHcZK5OVmJyXnuuOwXhWxkQl3wYS
# mgYtnwNe/YOiU2fKsfqNoWTJiJJZy6hGwMnypv99V9sSdvqKQSTUG/xypRSi1K1D
# HKRJi0E5FAMeKfobpSKupcNNgtCN2mu32/cYQFdz8HGj+0p9RTbB942C+rnJDVOA
# ffq2OVgy728YUInXT50zvRq1naHelUF6p4MCAwEAAaOCAVowggFWMB8GA1UdIwQY
# MBaAFFN5v1qqK0rPVIDh2JvAnfKyA2bLMB0GA1UdDgQWBBQaofhhGSAPw0F3RSiO
# 0TVfBhIEVTAOBgNVHQ8BAf8EBAMCAYYwEgYDVR0TAQH/BAgwBgEB/wIBADATBgNV
# HSUEDDAKBggrBgEFBQcDCDARBgNVHSAECjAIMAYGBFUdIAAwUAYDVR0fBEkwRzBF
# oEOgQYY/aHR0cDovL2NybC51c2VydHJ1c3QuY29tL1VTRVJUcnVzdFJTQUNlcnRp
# ZmljYXRpb25BdXRob3JpdHkuY3JsMHYGCCsGAQUFBwEBBGowaDA/BggrBgEFBQcw
# AoYzaHR0cDovL2NydC51c2VydHJ1c3QuY29tL1VTRVJUcnVzdFJTQUFkZFRydXN0
# Q0EuY3J0MCUGCCsGAQUFBzABhhlodHRwOi8vb2NzcC51c2VydHJ1c3QuY29tMA0G
# CSqGSIb3DQEBDAUAA4ICAQBtVIGlM10W4bVTgZF13wN6MgstJYQRsrDbKn0qBfW8
# Oyf0WqC5SVmQKWxhy7VQ2+J9+Z8A70DDrdPi5Fb5WEHP8ULlEH3/sHQfj8ZcCfkz
# XuqgHCZYXPO0EQ/V1cPivNVYeL9IduFEZ22PsEMQD43k+ThivxMBxYWjTMXMslMw
# laTW9JZWCLjNXH8Blr5yUmo7Qjd8Fng5k5OUm7Hcsm1BbWfNyW+QPX9FcsEbI9bC
# VYRm5LPFZgb289ZLXq2jK0KKIZL+qG9aJXBigXNjXqC72NzXStM9r4MGOBIdJIct
# 5PwC1j53BLwENrXnd8ucLo0jGLmjwkcd8F3WoXNXBWiap8k3ZR2+6rzYQoNDBaWL
# pgn/0aGUpk6qPQn1BWy30mRa2Coiwkud8TleTN5IPZs0lpoJX47997FSkc4/ifYc
# obWpdR9xv1tDXWU9UIFuq/DQ0/yysx+2mZYm9Dx5i1xkzM3uJ5rloMAMcofBbk1a
# 0x7q8ETmMm8c6xdOlMN4ZSA7D0GqH+mhQZ3+sbigZSo04N6o+TzmwTC7wKBjLPxc
# FgCo0MR/6hGdHgbGpm0yXbQ4CStJB6r97DDa8acvz7f9+tCjhNknnvsBZne5VhDh
# IG7GrrH5trrINV0zdo7xfCAMKneutaIChrop7rRaALGMq+P5CslUXdS5anSevUiu
# mDGCBCwwggQoAgEBMIGRMH0xCzAJBgNVBAYTAkdCMRswGQYDVQQIExJHcmVhdGVy
# IE1hbmNoZXN0ZXIxEDAOBgNVBAcTB1NhbGZvcmQxGDAWBgNVBAoTD1NlY3RpZ28g
# TGltaXRlZDElMCMGA1UEAxMcU2VjdGlnbyBSU0EgVGltZSBTdGFtcGluZyBDQQIQ
# OUwl4XygbSeoZeI72R0i1DANBglghkgBZQMEAgIFAKCCAWswGgYJKoZIhvcNAQkD
# MQ0GCyqGSIb3DQEJEAEEMBwGCSqGSIb3DQEJBTEPFw0yNDAzMDkxNDQwMTdaMD8G
# CSqGSIb3DQEJBDEyBDCy62UnHdZkaEAF28AhCbM99FE2VM5NgGJdba0To2rmFpmZ
# TSTnxIPJVQTcLeD2m80wge0GCyqGSIb3DQEJEAIMMYHdMIHaMIHXMBYEFK5ir3UK
# DL1H1kYfdWjivIznyk+UMIG8BBQC1luV4oNwwVcAlfqI+SPdk3+tjzCBozCBjqSB
# izCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCk5ldyBKZXJzZXkxFDASBgNVBAcT
# C0plcnNleSBDaXR5MR4wHAYDVQQKExVUaGUgVVNFUlRSVVNUIE5ldHdvcmsxLjAs
# BgNVBAMTJVVTRVJUcnVzdCBSU0EgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkCEDAP
# b6zdZph0fKlGNqd4LbkwDQYJKoZIhvcNAQEBBQAEggIANZvO+YYXJ7AiO+NWqgmE
# 4inoS2zdq9+hhqsGDOVFDVIEMudEfUH0x3i79QWNzUhKG+pQAxhcYIChCk80dU4N
# je8oCiI1wbFPuEACJE1VZ0/MN1tSQctzUFVRTfao85xeD9+7zn01uLPqvf2U7rg/
# NPOC4Bu0A2VgAbE9wm2RW0/TbbT3SPS3doiLFTcewbZzTXlsmnvOZz7olrMjxxkL
# Npih2egIpy0M/GDkn0nUGCKqyV5YIQVRXjwKm2URD6x8FwsIaSUWTzDs5hQ0SKN1
# vn2+bDQNo4oobw3q6wnWO++JA/yDeb/C4FP3Xaa+iFZu/JHhesdnlzY2gvkh5Wwu
# 2J+m9ZiUISgZM4gWrjoiSV4kMuy4FEhp6xM2EGqWsOJl4A2c3ENrZQc+sKwWYtoq
# jzxibMghAvMIhC34UEKx2XgieAxrz92xak2c2fcHkF/FVNfa9fF2Le2bCKbyaC9s
# NnzgVw+IxsNI6O8B7rNvj10mMQHaPiOrD+Y0kP+2ZA5/o7zAVdfUbsEV9Wiv5OVZ
# JMl2hIT1HAr1j6H8mZDCWY9KEmzOcBNtSSD/9NputUPafSx5hdlmCMYYNHcMxw1Z
# ppJl4kz/tOXzVStVkc7frsYOC7IY8PYJKoLBRzGbFJA18m+qXxcECipQyBRCrnq+
# NQjCEnUf6+uB/kNirbizriE=
# SIG # End signature block
