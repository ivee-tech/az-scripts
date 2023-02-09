# Login to Azure AD PowerShell With Admin Account
$tenantId = '6e424d97-163d-46e9-a079-e66d12f36c6e'

Connect-AzureAD -TenantId $tenantId

# Create the self signed cert
$currentDate = Get-Date
$endDate = $currentDate.AddYears(1)
$notAfter = $endDate.AddYears(1)
$pwd = "Test123!@#"
$thumb = (New-SelfSignedCertificate -CertStoreLocation cert:\currentuser\my -DnsName com.foo.bar -KeyExportPolicy Exportable -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider" -NotAfter $notAfter).Thumbprint
$pwd = ConvertTo-SecureString -String $pwd -Force -AsPlainText
Export-PfxCertificate -cert "cert:\currentuser\my\$thumb" -FilePath c:\temp\examplecert.pfx -Password $pwd

# Load the certificate
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate("C:\temp\examplecert.pfx", $pwd)
$keyValue = [System.Convert]::ToBase64String($cert.GetRawCertData())


# Create the Azure Active Directory Application
$app = New-AzureADApplication -DisplayName "test123" # -IdentifierUris "http://localhost"
New-AzureADApplicationKeyCredential -ObjectId $app.ObjectId -CustomKeyIdentifier "Test123" -StartDate $currentDate -EndDate $endDate -Type AsymmetricX509Cert -Usage Verify -Value $keyValue

# Create the Service Principal and connect it to the Application
$sp = New-AzureADServicePrincipal -AppId $app.AppId

# Give the Service Principal Reader access to the current tenant (Get-AzureADDirectoryRole)
# Add-AzureADDirectoryRoleMember -ObjectId 5997d714-c3b5-4d5b-9973-ec2f38fd49d5 -RefObjectId $sp.ObjectId

$unitId = 'a397394f-a925-4be1-8ba1-1e39b3daf669' # DAFF

$roleDefinition = Get-AzureADMSRoleDefinition -Filter "displayName eq 'User Administrator'"

$scope = "/administrativeUnits/$($unitId)"
$roleAssignment = New-AzureADMSRoleAssignment -DirectoryScopeId $scope -RoleDefinitionId $roleDefinition.Id -PrincipalId $sp.ObjectId
$roleAssignment

Disconnect-AzureAD

$thumb
$app.AppId
$sp
