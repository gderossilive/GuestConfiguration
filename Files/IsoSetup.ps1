param(
    [string] $servicePrincipalClientId,
    [string] $servicePrincipalSecret,
    [string] $TenantId,
    [string] $StorageAccountName,
    [string] $ContainerName,
    [string] $BlobName,
    [string] $Resource
)

Install-Module -Name SqlServerDsc -Force
Install-Module sqlserver -Force
#Install-Module -Name Az -Repository PSGallery -Force

$servicePrincipalClientId='20da7b2c-dd06-4080-b33d-e07292501cf8'; # ArcDeploySP-qzfc0
$servicePrincipalSecret='K~H8Q~Uq-Nf.WUHfa0oLUsCmGlagFOgOF2b~jc4X';
$TenantId = '16b3c013-d300-468d-ac64-7eda0820b6d3';

# Variables
$StorageAccountName = "gdrrepo3423"
$ContainerName = "iso"
$BlobName = "SQLServer2022-x64-ENU.iso"
$Resource = "https://gdrrepo3423.blob.core.windows.net"


# Get the access token
$Body = @{
    grant_type    = "client_credentials"
    client_id     = $servicePrincipalClientId
    client_secret = $servicePrincipalSecret
    resource      = $Resource
}
$TokenResponse = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantId/oauth2/token" -ContentType "application/x-www-form-urlencoded" -Body $Body
$AccessToken = $TokenResponse.access_token

# Set up headers
$Headers = @{
    "Authorization" = "Bearer $AccessToken"
    "x-ms-version"  = "2020-08-04"
}

# Download the SQL Server ISO
Invoke-WebRequest -Uri "https://$StorageAccountName.blob.core.windows.net/$ContainerName/$BlobName" -Headers $Headers -Method Get -OutFile "D:\SQLServer2022-x64-ENU.iso"

# Copy the ISO content to C:\SQL2022
New-Item -Path C:\SQL2022 -ItemType Directory
$mountResult = Mount-DiskImage -ImagePath 'D:\SQLServer2022-x64-ENU.iso' -PassThru
$volumeInfo = $mountResult | Get-Volume
$driveInfo = Get-PSDrive -Name $volumeInfo.DriveLetter
Copy-Item -Path ( Join-Path -Path $driveInfo.Root -ChildPath '*' ) -Destination 'C:\SQL2022\' -Recurse -Force
Dismount-DiskImage -ImagePath 'D:\SQLServer2022-x64-ENU.iso'