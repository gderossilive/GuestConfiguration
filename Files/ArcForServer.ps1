param(
    [string] $SubscriptionId,
    [string] $TenantId,
    [string] $ResourceGroupName,
    [string] $Location,
    [string] $ServicePrincipalId,
    [string] $Password,
    [string] $AAPLS,
    [string] $Proxy,
    [bool] $EnableArcAutoupdate,
    [bool] $EnableSSH
)

# Enable an Azure VM to be ARC enabled
Write-Host "Enabling an Azure VM to be ARC enabled" -foreground Green
Set-Service WindowsAzureGuestAgent -StartupType Disabled -Verbose
Stop-Service WindowsAzureGuestAgent -Force -Verbose
New-NetFirewallRule -Name BlockAzureIMDS -DisplayName "Block access to Azure IMDS" -Enabled True -Profile Any -Direction Outbound -Action Block -RemoteAddress 169.254.169.254

# Set the proxy to download the package
$servicePrincipalClientId=$ServicePrincipalId;
$servicePrincipalSecret=$Password;
$env:SUBSCRIPTION_ID = $SubscriptionId;
$env:RESOURCE_GROUP = $ResourceGroupName;
$env:TENANT_ID = $TenantId;
$env:LOCATION = $Location;
$env:AUTH_TYPE = "token";
$env:CORRELATION_ID = "e0abc3e6-4247-4774-abc7-a6c7fc02de59";
$env:CLOUD = "AzureCloud";

# Download the package
Write-Host "Downloading the Arc Agent package" -foreground Green
if ($Proxy) {
    Invoke-WebRequest -proxy $Proxy -Uri https://aka.ms/AzureConnectedMachineAgent -OutFile AzureConnectedMachineAgent.msi
} else {
    # download the latest agent version
    # Invoke-WebRequest -Uri https://aka.ms/AzureConnectedMachineAgent -OutFile AzureConnectedMachineAgent.msi 
    # download the agent version 1.43 - June 2024
    Invoke-WebRequest -Uri https://download.microsoft.com/download/0/7/8/078f3bb7-6a42-41f7-b9d3-9a0eb4c94df8/AzureConnectedMachineAgent.msi -OutFile AzureConnectedMachineAgent.msi 
}

# Install the package
Write-Host "Installing Arc agent" -foreground Green
$exitCode=(Start-Process -FilePath msiexec.exe -ArgumentList @("/i", "AzureConnectedMachineAgent.msi" , "/l*v", "installationlog.txt", "/qn") -Wait -Passthru).ExitCode
if ($exitCode -ne 0) {
    $message = (net helpmsg $exitCode)        
    throw "Installation failed: $message See installationlog.txt for additional details."
}

Write-Host "Connecting Arc agent to Azure" -foreground Green
if ($AAPLS) {
    $env:PRIVATELINKSCOPE = $AAPLS
    & "$env:ProgramW6432\AzureConnectedMachineAgent\azcmagent.exe" config set proxy.url $Proxy
    & "$env:ProgramW6432\AzureConnectedMachineAgent\azcmagent.exe" config set proxy.bypass "Arc"
    & "$env:ProgramW6432\AzureConnectedMachineAgent\azcmagent.exe" connect `
        --service-principal-id "$servicePrincipalClientId" `
        --service-principal-secret "$servicePrincipalSecret" `
        --resource-group "$env:RESOURCE_GROUP" `
        --tenant-id "$env:TENANT_ID" `
        --location "$env:LOCATION" `
        --subscription-id "$env:SUBSCRIPTION_ID" `
        --cloud "$env:CLOUD" `
        --private-link-scope "$env:PRIVATELINKSCOPE" `
        --correlation-id "$env:CORRELATION_ID"
} else {
    & "$env:ProgramW6432\AzureConnectedMachineAgent\azcmagent.exe" connect `
        --service-principal-id "$servicePrincipalClientId" `
        --service-principal-secret "$servicePrincipalSecret" `
        --resource-group "$env:RESOURCE_GROUP" `
        --tenant-id "$env:TENANT_ID" `
        --location "$env:LOCATION" `
        --subscription-id "$env:SUBSCRIPTION_ID" `
        --cloud "$env:CLOUD" `
        --correlation-id "$env:CORRELATION_ID"
}

# Enabling Arc Agent autoupdate
if ($EnableArcAutoupdate=1) {
    Write-Host "Enabling Arc Agent autoupdate" -foreground Green 
    $ServiceManager = (New-Object -com "Microsoft.Update.ServiceManager")
    $ServiceID = "7971f918-a847-4430-9279-4a52d1efe18d"
    $ServiceManager.AddService2($ServiceId,7,"")
}

if ($EnableSSH=1) {
    # Enabling SSH connectivity via Arc
    Write-Host "Enabling SSH connectivity via Arc" -foreground Green 
    ## Install the OpenSSH Client
    Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
    ## Install the OpenSSH Server
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
    ## Start the sshd service
    Start-Service sshd
    ## OPTIONAL but recommended:
    Set-Service -Name sshd -StartupType 'Automatic'
    ## Confirm the Firewall rule is configured. It should be created automatically by setup. Run the following to verify
    if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
        Write-Output "Firewall Rule 'OpenSSH-Server-In-TCP' does not exist, creating it..."
        New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
    } else {
        Write-Output "Firewall rule 'OpenSSH-Server-In-TCP' has been created and exists."
    }
}