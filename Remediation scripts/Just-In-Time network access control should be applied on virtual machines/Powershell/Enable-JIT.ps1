# Prepare Modules

Write-Verbose "Checking for Azure module..."
$AzModule = Get-Module -Name "Az.*" -ListAvailable
if ($AzModule -eq $null) {
    Write-Verbose "Azure PowerShell module not found"
    # Check for Admin Privileges
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isadmin = ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
    if($isadmin -eq $False){
        # No Admin, install to current user
        Write-Warning -Message "Can not install Az Module.  You are not running as Administrator"
        Write-Warning -Message "Installing Az Module to Current User Scope"
        Install-Module Az -Scope CurrentUser -Force
        Install-Module Az.Security -Scope CurrentUser -Force
    }
    Else{
        # Admin, install to all users
        Install-Module Az -Force
        Install-Module Az.Security -Force
    }
else {
    if ($AzModule.Name -notcontains "Az.Security") {
    Write-Verbose "Azure Security PowerShell module not found"
        if($isadmin -eq $False){
        Write-Warning -Message "Can not install Az Security Module.  You are not running as Administrator"
        Write-Warning -Message "Installing Az Security Module to Current User Scope"
        Install-Module Az.Security -Scope CurrentUser -Force

    }
        Else{
        # Admin, install to all users
        Install-Module Az.Security -Force
    }
}
}
}

# Check/Set Execution Policy
if ((Get-ExecutionPolicy).value__ -eq '3') {
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
}

# Import Modules
Import-Module Az
Import-Module Az.Security

# Login to Azure
Login-AzAccount

# Get All Subs
$Subscriptions = Get-AzSubscription

# Loop Through Subs for Tasks
foreach($Subscription in $Subscriptions){
    $Id = ($Subscription.Id)
    Select-AzSubscription $Id
    $SecurityTasks += Get-AzSecurityTask | Where-Object {$_.RecommendationType -eq "Just-In-Time network access control should be applied on virtual machines"}
}

# Enable JIT
foreach($SecurityTask in $SecurityTasks){
    $sub = $securityTask.Id.Split("/")[2]
    $vm = $securityTask.ResourceId.Split("/")[8]
    $vmlocation = (Get-AzVm -Name $vm).Location
    $vmrg = (Get-AzVm -Name $vm).ResourceGroupName
    
    # Create JIT Policy
    $JitPolicy = (@{
        id="/subscriptions/${sub}/resourceGroups/${vmrg}/providers/Microsoft.Compute/virtualMachines/${vm}"
        ports=(@{
            number=22;
            protocol="*";
            allowedSourceAddressPrefix=@("*");
            maxRequestAccessDuration="PT3H"},
            @{
            number=3389;
            protocol="*";
            allowedSourceAddressPrefix=@("*");
            maxRequestAccessDuration="PT3H"})}
    )
    $JitPolicyArr=@($JitPolicy)

    # Set JIT Policy
    Set-AzJitNetworkAccessPolicy -Kind "Basic" -Location $vmlocation -Name "${vm}JITPolicy" -ResourceGroupName $vmrg -VirtualMachine $JitPolicyArr
}