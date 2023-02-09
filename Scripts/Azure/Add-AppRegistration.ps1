Function Add-AppRegistration {
    param(
        [Parameter(Mandatory=$true)][string]$appName,
        [Parameter()][string]$appUri,
        [Parameter()][string]$appReplyUrl,
        [Parameter(Mandatory=$true)][boolean]$isNative,
        [Parameter()][switch]$createPrincipal
    )

if(!($app = Get-AzureADApplication -Filter "DisplayName eq '$($appName)'"  -ErrorAction SilentlyContinue))
{
	$guid = New-Guid
	$startDate = Get-Date
	
	$cred = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordCredential
	$cred.StartDate	= $startDate
	$cred.EndDate = $startDate.AddYears(1)
	$cred.KeyId	= $Guid
	$cred.Value = ([System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(($Guid))))+"="

    if($isNative) {
	    $app = New-AzureADApplication -DisplayName $appName -PasswordCredentials $cred -PublicClient $true
    }
    else {
        if([string]::IsNullOrEmpty($appReplyUrl)) {
            $app = New-AzureADApplication -DisplayName $appName -IdentifierUris $appUri -PasswordCredentials $cred
        }
        else {
            $app = New-AzureADApplication -DisplayName $appName -IdentifierUris $appUri -ReplyUrls $appReplyUrl -PasswordCredentials $cred
        }
    }

	$output = @{
        appName = $appName;
        appId = $app.AppId;
        secret = $cred.Value;
        principal = @{};
    }

    if($createPrincipal) {
        $principal = New-AzureADServicePrincipal -AppId $app.AppId
        $p = @{
            appId = $principal.AppId;
            objectId = $principal.ObjectId;
            displayName = $principal.DisplayName;
        }
        $output.principal = $p;
    }

    return $output
}
else
{
    Write-Host "Application $appName already exists." -ForegroundColor Yellow
    return $null
}

}