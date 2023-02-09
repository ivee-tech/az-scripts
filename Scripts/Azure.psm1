Function Add-AADApplication
{
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][PSCustomObject]$appData,
    [Parameter(Mandatory=$true)][string]$accessToken
)

$contentType = "application/json"
$url = "https://graph.microsoft.com/v1.0/applications"
$url

$appJson = $appData | ConvertTo-Json -Depth 10
$headers = @{
    'Authorization' = 'Bearer ' + $accessToken
}

$app = Invoke-RestMethod -Uri $url -Headers $headers -Method POST -Body $appJson -ErrorAction Stop -ContentType $contentType -Verbose
return $app

}
Function Add-AADApplicationFromTemplate
{
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$displayName,
    [Parameter(Mandatory=$true)][string[]]$redirectUris,
    [Parameter(Mandatory=$true)][string]$templateAppObjectId,
    [Parameter(Mandatory=$true)][string]$repoRootDir,
    [Parameter(Mandatory=$true)][string]$repoName,
    [Parameter(Mandatory=$true)][string]$repoUrl,
    [Parameter(Mandatory=$true)][string]$accessToken,
    [Parameter()][switch]$addToSourceControl
)

try {

$location = Get-Location

$repoDir = "$repoRootDir\$repoName"
Remove-Item -Path $repoDir -Recurse -Force -ErrorAction SilentlyContinue
git clone $repoUrl $repoDir

Set-Location $repoDir

$templateAppDir = "$repoDir\$templateAppObjectId"

$manifestPath = "$templateAppDir\manifest.json"

$manifestJson = Get-Content -Path $manifestPath -Raw
$appData = ConvertFrom-Json -InputObject $manifestJson
$appData


$appdata.id = $null
$appdata.appid = $null
# $appData.PSObject.properties.Remove('<prop>')
$appData.PSObject.properties.Remove('publisherDomain')

$appData.displayName = $displayName
$appData.web.redirectUris = $redirectUris
$appData

$appData | ConvertTo-Json -Depth 10
$app = Add-AADApplication -appData $appData -accessToken $authResult.access_token

if($addToSourceControl) {
    $appObjectId = $app.id
    $appDir = "$repoDir\$appObjectId"
    New-Item -Path $appDir -ItemType Directory -Force -ErrorAction SilentlyContinue
    $manifestPath = "$appDir\manifest.json"
    $app | ConvertTo-Json -Depth 10 > $manifestPath

    git add $manifestPath
    git commit -m "Added $manifestPath"
    git push
}
Set-Location $location

Write-Output "Application $displayName created successfully. AppId: $($app.appId)"

return $app
}
catch {
    Write-Error "Error creating application $displayName or source control operation. Error: $($_.Exception.Message)" 
}

}
Function Add-Aci {
    param(
        [Parameter(Mandatory=$true)][string]$rgName,
        [Parameter(Mandatory=$true)][string]$acrName,
        [Parameter(Mandatory=$true)][string]$location,
        [Parameter(Mandatory=$true)][string]$containerGroupName,
        [Parameter(Mandatory=$true)][string]$imageName,
        [Parameter(Mandatory=$true)][string]$imageTag,
        [Parameter(Mandatory=$true)][string]$osType,
        [Parameter()][hashtable]$envVars
    )

$registry = Get-AzContainerRegistry -Name $acrName -ResourceGroupName $rgName -ErrorAction SilentlyContinue
$loginServer = $registry.LoginServer
$creds = Get-AzContainerRegistryCredential -Registry $registry
$secPwd = ConvertTo-SecureString $creds.Password -AsPlainText -Force
$psCreds = New-Object System.Management.Automation.PSCredential ($creds.Username, $secPwd)
$localImage = "$($imageName):$($imageTag)"
$remoteImage = "$($loginServer)/$($localImage)"
if($null -ne $envVars) {
    $container = New-AzContainerGroup -RegistryCredential $psCreds -ResourceGroupName $rgName -Location $location -Name $containerGroupName `
        -Image $remoteImage -OsType $osType -EnvironmentVariable $envVars # -DnsNameLabel $dnsLabel -Port $port
}
else {
    $container = New-AzContainerGroup -RegistryCredential $psCreds -ResourceGroupName $rgName -Location $location -Name $containerGroupName `
        -Image $remoteImage -OsType $osType # -DnsNameLabel $dnsLabel -Port $port
}

return $container

}
Function Add-AcrCli
{
param(
    [Parameter(Mandatory=$true)][string]$rgName,
    [Parameter(Mandatory=$true)][string]$location,
    [Parameter(Mandatory=$true)][string]$acrName,
    [ValidateSet("Basic", "Standard", "Premium")]
    [Parameter(Mandatory=$true)][string]$sku
)

$grp = (az group show --name $rgName)
if($null -eq $grp) {
    # create group
    az group create --name $rgName --location $location
}

# create Azure Container Registry
$acr = (az acr create --name $acrName --resource-group $rgName --location $location --sku $sku) | ConvertFrom-Json

return $acr

}
Function Add-AcrSP
{
param(
    [Parameter(Mandatory=$true)][string]$rgName,
    [Parameter(Mandatory=$true)][string]$acrName,
    [ValidateSet("AcrPull", "AcrPush", "Owner")]
    [Parameter(Mandatory=$true)][string]$acrRole
)

# Modify for your environment. The 'registryName' is the name of your Azure
# Container Registry, the 'resourceGroup' is the name of the resource group
# in which your registry resides, and the 'servicePrincipalName' can be any
# unique name within your subscription (you can use the default below).
$servicePrincipalName = "$acrName-SP-$(Get-Random)"

# Configure the secure password for the service principal
Import-Module Az.Resources # Imports the PSADPasswordCredential object
$password = [guid]::NewGuid().Guid
$secpassw = New-Object Microsoft.Azure.Commands.ActiveDirectory.PSADPasswordCredential -Property @{ StartDate=Get-Date; EndDate=Get-Date -Year 2024; Password=$password}

# Get a reference to the container registry; need its fully qualified ID
# when assigning the role to the principal in a subsequent command.
$registry = Get-AzContainerRegistry -ResourceGroupName $rgName -Name $acrName

# Create the service principal
$sp = New-AzADServicePrincipal -DisplayName $servicePrincipalName -PasswordCredential $secpassw

# Sleep a few seconds to allow the service principal to propagate throughout
# Azure Active Directory
Start-Sleep 30

# Assign the role to the service principal. Default permissions are for docker
# pull access. Modify the 'RoleDefinitionName' argument value as desired:
# acrpull:     pull only
# acrpush:     push and pull
# Owner:       push, pull, and assign roles
$role = New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName $acrRole -Scope $registry.Id

# Output the service principal's credentials; use these in your services and
# applications to authenticate to the container registry.
$result = @{
    applicationId = $sp.ApplicationId
    spName = $servicePrincipalName
    password = $password
} 

return $result
}
Function Add-AksAcrLinuxCli
{
param(
    [Parameter(Mandatory=$true)][string]$rgName,
    [Parameter(Mandatory=$true)][string]$location,
    [Parameter(Mandatory=$true)][string]$acrName,
    [Parameter(Mandatory=$true)][string]$aksClusterName,
    [Parameter(Mandatory=$true)][int]$aksNodeCount,
    [Parameter(Mandatory=$true)][string]$aksVmSize
)

$sp = (az ad sp create-for-rbac --skip-assignment) | ConvertFrom-Json

# get the results from above and set the variables
$appId = $sp.appId
$clientSecret = $sp.password

# get the ACR ID
$acrId = az acr show --name $acrName --resource-group $rgName --query "id" -o tsv

$role = 'AcrPull' # 'Reader'

# assign read ACR permissions to SP
az role assignment create --assignee $appId --role $role --scope $acrId

# create AKS cluster
$cluster = (az aks create --name $aksClusterName --resource-group $rgName --node-count $aksNodeCount `
    --generate-ssh-keys --service-principal $appId --client-secret $clientSecret --location $location `
    --node-vm-size $aksVmSize --attach-acr $acrName) | ConvertFrom-Json

return $cluster

}
Function Add-AksLinuxCli
{
param(
    [Parameter(Mandatory=$true)][string]$rgName,
    [Parameter(Mandatory=$true)][string]$location,
    [Parameter(Mandatory=$true)][string]$aksClusterName,
    [Parameter(Mandatory=$true)][int]$aksNodeCount,
    [Parameter(Mandatory=$true)][string]$aksVmSize
)

$sp = (az ad sp create-for-rbac --skip-assignment) | ConvertFrom-Json

# get the results from above and set the variables
$appId = $sp.appId
$clientSecret = $sp.password

# create AKS cluster
$cluster = (az aks create --name $aksClusterName --resource-group $rgName --node-count $aksNodeCount `
    --generate-ssh-keys --service-principal $appId --client-secret $clientSecret --location $location `
    --node-vm-size $aksVmSize) | ConvertFrom-Json

return $cluster

}
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
Function Add-DataFactory {
    param(
        [Parameter(Mandatory=$true)][string]$rgName,
        [Parameter(Mandatory=$true)][string]$location,
        [Parameter(Mandatory=$true)][string]$dataFactoryName
    )

    $rg = Get-AzResourceGroup -Name $rgName -Location $location -ErrorAction SilentlyContinue
    if($null -eq $rg) {
        $rg = New-AzResourceGroup -Name $rgName -Location $location
    }
    $dataFactory = Set-AzDataFactoryV2 -ResourceGroupName $rgName `
        -Location $location -Name $dataFactoryName
    return $dataFactory

}
Function Add-SqlServerFirewallRule {
[CmdletBinding(DefaultParameterSetName = 'None')]
param
(
  [Parameter(Mandatory = $true)][string] $dbServerName,
  [Parameter(Mandatory = $true)][string] $rgName,
  [string] $ipAddress = '',
  [string] $firewallRuleName = "AzureWebAppFirewall"
)

if([string]::IsNullOrEmpty($ipAddress)) {
    $ip = (New-Object net.webclient).downloadstring("http://checkip.dyndns.com") -replace "[^\d\.]" # get IP
}
else {
    $ip = $ipAddress
}
    New-AzSqlServerFirewallRule -ResourceGroupName $rgName -ServerName $dbServerName -FirewallRuleName $firewallRuleName `
        -StartIPAddress $ip -EndIPAddress $ip

}
Function Add-StorageQueue
{
param(
    [Parameter(Mandatory=$true)][string]$rgName,
    [Parameter(Mandatory=$true)][string]$acctName,
    [Parameter(Mandatory=$true)][string]$queueName
)
$acct = Get-AzStorageAccount -StorageAccountName $acctName -ResourceGroupName $rgName
$ctx = $acct.Context

$queue = Get-AzStorageQueue -name $queueName -Context $ctx -ErrorAction SilentlyContinue
if(-not $queue){ 
    $queue = New-AzStorageQueue -name $queueName -Context $ctx
}

}
Function Copy-AzureFile
{
	<#
	.SYNOPSIS
		This function simplifies the process of uploading files to an Azure storage account. In order for this function to work you
		must have already logged into your Azure subscription with Login-AzureAccount. The file uploaded will be called the file
		name as the storage blob.
		
	.PARAMETER filePath
		The local path of the file(s) you'd like to upload to an Azure storage account container.
	
	.PARAMETER containerName
		The name of the Azure storage account container the file will be placed in.
	
	.PARAMETER rgName
		The name of the resource group the storage account is in.
	
	.PARAMETER stgAccName
		The name of the storage account the container that will hold the file is in.
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory,ValueFromPipelineByPropertyName)]
		[ValidateNotNullOrEmpty()]
		[ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
		[string]$filePath,
	
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$containerName,
	
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$rgName,
	
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$stgAccName,

		[Parameter()]
		[switch]$overwrite

	)
	process
	{
		try
		{
			$saParams = @{
				'ResourceGroup' = $rgName
				'Name' = $stgAccName
			}
			
			$scParams = @{
				'Container' = $containerName
			}
			
			$bcParams = @{
				'File' = $filePath
				'Blob' = ($filePath | Split-Path -Leaf)
			}
			
			if($overwrite) {
				Get-AzStorageAccount @saParams | Get-AzStorageContainer @scParams | Set-AzStorageBlobContent @bcParams -Force

			}
			else {
				Get-AzStorageAccount @saParams | Get-AzStorageContainer @scParams | Set-AzStorageBlobContent @bcParams
			}
		}
		catch
		{
			Write-Error $_.Exception.Message
		}
	}
}
Function Copy-FileFromStorageAccount {
    param(
        [Parameter(Mandatory=$true)][string]$acctName,
        [Parameter(Mandatory=$true)][string]$sasToken,
        [Parameter(Mandatory=$true)][string]$containerName,
        [Parameter(Mandatory=$true)][string]$fileName,
        [Parameter(Mandatory=$true)][string]$filePath

    )

$ctx = New-AzStorageContext -StorageAccountName $acctName -SasToken $sasToken
Measure-Command {
    Get-AzStorageBlobContent -Destination $filePath -Container $containerName -Blob $fileName -Context $ctx -Force
}

}
Function Copy-FileToStorageAccount {
    param(
        [Parameter(Mandatory=$true)][string]$acctName,
        [Parameter(Mandatory=$true)][string]$sasToken,
        [Parameter(Mandatory=$true)][string]$containerName,
        [Parameter(Mandatory=$true)][string]$fileName,
        [Parameter(Mandatory=$true)][string]$filePath

    )

$ctx = New-AzStorageContext -StorageAccountName $acctName -SasToken $sasToken
Measure-Command {
    Set-AzStorageBlobContent -File $filePath -Container $containerName -Blob $fileName -Context $ctx -Force
}

}
Function Get-AADAccessToken
{
param(
    [Parameter(Mandatory=$true)][string]$tenant,
    [Parameter(Mandatory=$true)][string]$graphAppId,
    [Parameter(Mandatory=$true)][string]$graphAppSecret
)

$tenantFullName = "$tenant.onmicrosoft.com"
$contentType = 'application/x-www-form-urlencoded'
$scope = "https://graph.microsoft.com/.default"
$url = 'https://login.microsoftonline.com/' + $tenantFullName + '/oauth2/v2.0/token?client_id=' + $graphAppId + '&scope=' + $scope + '&client_secret=' + $graphAppSecret + '&grant_type=access_token'
$url
$body = @{ 
    client_id = $graphAppId;
    grant_type = 'client_credentials';
    client_secret = $graphAppSecret;
    scope = $scope;
}
$result = Invoke-RestMethod -Uri $url -Method POST -ContentType $contentType -Body $body
return $result


}
Function Get-AADApplication
{
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$appObjectId,
    [Parameter(Mandatory=$true)][string]$accessToken
)

$url = "https://graph.microsoft.com/v1.0/applications/$appObjectId"
$url

$headers = @{
    'Authorization' = 'Bearer ' + $accessToken
}

$app = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
# the response is an array with two elements:
# app[0] - the graph Url
# app[1] - the application data
return $app

}
Function Get-AADApplications
{
param(
    [Parameter(Mandatory=$true)][string]$accessToken
)

$url = "https://graph.microsoft.com/v1.0/applications"
$url

$headers = @{
    'Authorization' = 'Bearer ' + $accessToken
}
    
$apps = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
return $apps

}
Function Get-AcrSizeUsage
{
param(
    [Parameter(Mandatory=$true)][string]$rgName,
    [Parameter(Mandatory=$true)][string]$acrName
)

$acr = Get-AzContainerRegistry -ResourceGroupName $rgName -Name $acrName -IncludeDetail
$size = $acr.Usages | Where-Object { $_.name -eq "Size" }

return $size

}
Function Get-AllSubscriptionsVmsMetricTags {
    [CmdletBinding()]
    param(
        [Parameter()][string]$tenantId,
        # use Get-AzMetricDefintion to get possible metrics for a resource, e.g. "Percentage CPU"
        [Parameter(Mandatory=$true)][string]$metricName,
        # start time for the metric query, defaults local current time minus 1 hour
        [Parameter()][DateTime]$startTime,
        # end time for the metric query, defaults local current time
        [Parameter()][DateTime]$endTime
    )
    
    $subscriptions = @()
    if([string]::IsNullOrEmpty(($tenantId))) {
        $subscriptions = Get-AzSubscription
    }
    else {
        $subscriptions = Get-AzSubscription -TenantId $tenantId
    }
    $hasDT = $PSBoundParameters.ContainsKey('startTime') -and $PSBoundParameters.ContainsKey('endTime')

    $mtsallsub = @()
    $subscriptions | ForEach-Object {
        $subscriptionId = $_.SubscriptionId
        if($hasDT) {
            $mts = Get-SubscriptionVmsMetricTags -subscriptionId $subscriptionId -metricName $metricName `
                -startTime $startTime -endTime $endTime
        } else {
            $mts = Get-SubscriptionVmsMetricTags -subscriptionId $subscriptionId -metricName $metricName
        } 
        $mtsallsub += $mts
    }

    return $mtsallsub
    
}
Function Get-StorageAccountSAS {
    param(
        [Parameter(Mandatory=$true)][string]$rgName,
        [Parameter(Mandatory=$true)][string]$acctName,
        [Parameter(Mandatory=$true)][string]$containerName,
        [Parameter(Mandatory=$true)][decimal]$hoursValidity
    )

$storageAccount = Get-AzStorageAccount -ResourceGroupName $rgName -Name $acctName

$ctx = $storageAccount.Context

$startTime = Get-Date
$endTime = $startTime.AddHours($hoursValidity)
$sasToken = New-AzStorageContainerSASToken -Container $containerName -Permission rwdl -StartTime $startTime -ExpiryTime $endTime -Context $ctx

return $sasToken

}
Function Get-SubscriptionVmsMetricTags {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$subscriptionId,
        # use Get-AzMetricDefintion to get possible metrics for a resource, e.g. "Percentage CPU"
        [Parameter(Mandatory=$true)][string]$metricName,
        # start time for the metric query, defaults local current time minus 1 hour
        [Parameter()][DateTime]$startTime,
        # end time for the metric query, defaults local current time
        [Parameter()][DateTime]$endTime
    )
    
    Set-AzContext -Subscription $subscriptionId
    $resources = Get-AzResource -ResourceType Microsoft.Compute/virtualMachines
    $hasDT = $PSBoundParameters.ContainsKey('startTime') -and $PSBoundParameters.ContainsKey('endTime')

    $mtssub = @()
    $resources | ForEach-Object {
        $resourceId = $_.ResourceId
        $rgName = $_.ResourceGroupName
        $vmName = $_.Name
        if ($hasDT) {
            $mts = Get-VmMetricTags -subscriptionId $subscriptionId -rgName $rgName -vmName $vmName -vmId $resourceId `
                -metricName $metricName -startTime $startTime -endTime $endTime
        } else {
            $mts = Get-VmMetricTags -subscriptionId $subscriptionId -rgName $rgName -vmName $vmName -vmId $resourceId `
                -metricName $metricName
        }
        $mtssub += $mts
    }

    return $mtssub
    
}
Function Get-VmMetricTags {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$subscriptionId,
        [Parameter(Mandatory=$true)][string]$rgName,
        [Parameter(Mandatory=$true)][string]$vmName,
        # ResourceId for a VM, use Get-AzVM -ResourceGroup $rgName -Name $vmName
        [Parameter(Mandatory=$true)][string]$vmId,
        # use Get-AzMetricDefintion to get possible metrics for a resource, e.g. "Percentage CPU"
        [Parameter(Mandatory=$true)][string]$metricName,
        # start time for the metric query, defaults local current time minus 1 hour
        [Parameter()][DateTime]$startTime,
        # end time for the metric query, defaults local current time
        [Parameter()][DateTime]$endTime
    )
    
    # get VM CPU metric
    $hasDT = $PSBoundParameters.ContainsKey('startTime') -and $PSBoundParameters.ContainsKey('endTime')
    if ($hasDT) {
        $metric = Get-AzMetric -MetricName $metricName -MetricNamespace Microsoft.Compute/virtualMachines -ResourceId $vmId `
            -StartTime $startTime -EndTime $endTime
    } else {
        $metric = Get-AzMetric -MetricName $metricName -MetricNamespace Microsoft.Compute/virtualMachines -ResourceId $vmId
    }
    # get VM tags
    $tags = Get-AzTag -ResourceId $vmId

    $mt = New-Object PSObject -Property @{
        SubscriptionId = $subscriptionId
        ResourceGroupName = $rgName
        Name = $vmName
        ResourceId = $vmId 
        Maximum = ($metric.Data.Maximum | Measure-Object -Maximum).Maximum
        Minimum = ($metric.Data.Minimum | Measure-Object -Minimum).Minimum
        Average = ($metric.Data.Average | Measure-Object -Average).Average
        Tags = $tags.Properties.TagsProperty | ConvertTo-Json
        # TagsTable = $tags.PropertiesTable
    }

    return $mt    
}
Function Get-VmsMetricTags {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$subscriptionId,
        [Parameter(Mandatory=$true)][string]$rgName,
        # use Get-AzMetricDefintion to get possible metrics for a resource, e.g. "Percentage CPU"
        [Parameter(Mandatory=$true)][string]$metricName,
        # start time for the metric query, defaults local current time minus 1 hour
        [Parameter()][DateTime]$startTime,
        # end time for the metric query, defaults local current time
        [Parameter()][DateTime]$endTime
    )
    
    $vms = Get-AzVM -ResourceGroup $rgName
    $hasDT = $PSBoundParameters.ContainsKey('startTime') -and $PSBoundParameters.ContainsKey('endTime')

    $mts = @()
    $vms | ForEach-Object {
        $vm = $_
        if($hasDT) {
            $mt = Get-VmMetricTags -subscriptionId $subscriptionId 0rgName $rgName -vmName $vm.Name -vmId $vm.Id `
                -metricName $metricName -startTime $startTime -endTime $endTime
        } else {
            $mt = Get-VmMetricTags -subscriptionId $subscriptionId 0rgName $rgName -vmName $vm.Name -vmId $vm.Id `
                -metricName $metricName
        }
        $mts += $mt
    }

    return $mts
    
}
Function Invoke-Aci {
    param(
        [Parameter(Mandatory=$true)][string]$rgName,
        [Parameter(Mandatory=$true)][string]$containerGroupName,
        [Parameter()][switch]$stop
    )

$container = Get-AzContainerGroup -ResourceGroupName $rgName -Name $containerGroupName

if($stop) {
    Invoke-AzResourceAction -ResourceId $container.Id -Action stop -Force
}
else {
    Invoke-AzResourceAction -ResourceId $container.Id -Action start -Force
}
    
}
Function Push-AADApplicationTemplateToGit
{
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$appObjectId,
    [Parameter(Mandatory=$true)][string]$repoRootDir,
    [Parameter(Mandatory=$true)][string]$repoName,
    [Parameter(Mandatory=$true)][string]$repoUrl,
    [Parameter(Mandatory=$true)][string]$accessToken
)

try {

    $location = Get-Location

    $repoDir = "$repoRootDir\$repoName"
    Remove-Item -Path $repoDir -Recurse -Force -ErrorAction SilentlyContinue
    git clone $repoUrl $repoDir
    
    Set-Location $repoDir
    
    $appDir = "$repoDir\$appObjectId"
    New-Item -Path $appDir -ItemType Directory -Force -ErrorAction SilentlyContinue
    
    $manifestPath = "$appDir\manifest.json"
    $app = Get-AADApplication -appObjectId $appObjectId -accessToken $authResult.access_token
    
    # $app is an array with two elements, graph Url and app data 
    $app[1] | ConvertTo-Json -Depth 10 > $manifestPath
    
    git add $manifestPath
    git commit -m "Added $manifestPath"
    git push
    
    Set-Location $location

    Write-Output "Application template $($appObjectId) added successfully to git."
    
}
catch {
    Write-Error "Error adding application $($appObjectId) to source control. Error: $($_.Exception.Message)" 
}
}
Function Push-AcrImage {
    param(
        [Parameter(Mandatory=$true)][string]$rgName,
        [Parameter(Mandatory=$true)][string]$acrName,
        [Parameter(Mandatory=$true)][string]$imageName,
        [Parameter(Mandatory=$true)][string]$imageTag
    )

$registry = Get-AzContainerRegistry -Name $acrName -ResourceGroupName $rgName -ErrorAction SilentlyContinue

$loginServer = $registry.LoginServer

$creds = Get-AzContainerRegistryCredential -Registry $registry
$creds.Password | docker login $registry.LoginServer -u $creds.Username --password-stdin

$localImage = "$($imageName):$($imageTag)"
$remoteImage = "$($loginServer)/$($localImage)"
docker tag $localImage $remoteImage

docker push $remoteImage

}
Function Push-AcrImageCli
{
param(
    [Parameter(Mandatory=$true)][string]$rgName,
    [Parameter(Mandatory=$true)][string]$acrName,
    [Parameter(Mandatory=$true)][string]$localImage,
    [Parameter(Mandatory=$true)][string]$remoteImage
)

#login into ACR (requires docker)
az acr login --name $acrName 


# tag image with loginServer
docker tag $localImage $remoteImage

# check
# docker image list

# push image to ACR
docker push $remoteImage

}
Function Remove-AADApplication
{
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$appObjectId,
    [Parameter(Mandatory=$true)][string]$accessToken
)

$url = "https://graph.microsoft.com/v1.0/applications/$appObjectId"
$url

$headers = @{
    'Authorization' = 'Bearer ' + $accessToken
}

# performs soft delete
$result = Invoke-RestMethod -Uri $url -Headers $headers -Method Delete
return $result

}
Function Remove-SqlServerFirewallRule {
[CmdletBinding(DefaultParameterSetName = 'None')]
param
(
  [Parameter(Mandatory = $true)][string] $dbServerName,
  [Parameter(Mandatory = $true)][string] $rgName,
  [string] $firewallRuleName = "AzureWebAppFirewall"
)

Remove-AzSqlServerFirewallRule -ResourceGroupName $rgName -ServerName $dbServerName -FirewallRuleName $firewallRuleName

}
Function Add-AcrSP
{
param(
    [Parameter(Mandatory=$true)][string]$rgName,
    [Parameter(Mandatory=$true)][string]$acrName,
    [Parameter(Mandatory=$true)][string]$servicePrincipalId,
    [ValidateSet("AcrPull", "AcrPush", "Owner")]
    [Parameter(Mandatory=$true)][string]$acrRole
)
# Modify for your environment. The 'registryName' is the name of your Azure
# Container Registry, the 'resourceGroup' is the name of the resource group
# in which your registry resides, and the 'servicePrincipalId' is the
# service principal's 'ApplicationId' or one of its 'servicePrincipalNames'.

# Get a reference to the container registry; need its fully qualified ID
# when assigning the role to the principal in a subsequent command.
$registry = Get-AzContainerRegistry -ResourceGroupName $$rgName -Name $acrName

# Get the existing service principal; need its 'ObjectId' value
# when assigning the role to the principal in a subsequent command.
$sp = Get-AzADServicePrincipal -ServicePrincipalName $servicePrincipalId

# Assign the role to the service principal, identified using 'ObjectId'. Default permissions are for docker
# pull access. Modify the 'RoleDefinitionName' argument value as desired:
# acrpull:     pull only
# acrpush:     push and pull
# Owner:       push, pull, and assign roles
$role = New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName $acrRole -Scope $registry.Id

return $role

}
# . .\Set-KeyVaultSecrets.ps1

Function Set-AppKeyVaultSecrets
{
    param(
        [Parameter(Mandatory=$true)][string]$rgName,
        [Parameter(Mandatory=$true)][string]$keyVaultName,
        [Parameter()][byte]$length = 24,
        [Parameter()][byte]$nonAlphaChars = 5
    )

$secrets = @()
$s = @{ key = "App-AzureAdB2C-ClientSecret"; value = [System.Web.Security.Membership]::GeneratePassword($length, $nonAlphaChars) }
$secrets += $s

$s = @{ key = "ConnectionStrings-AppConnectionFormat"; value = "Server=tcp:{0},1433;Initial Catalog={1};Persist Security Info=False;User ID={2};Password={3};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" }
$secrets += $s

$s = @{ key = "Meta-AzureAdB2C-ClientSecret"; value = [System.Web.Security.Membership]::GeneratePassword($length, $nonAlphaChars) }
$secrets += $s

$s = @{ key = "Settings-App-CustomAuthZKey"; value = [System.Web.Security.Membership]::GeneratePassword($length, $nonAlphaChars) }
$secrets += $s

$s = @{ key = "Settings-AppDBPassword"; value = [System.Web.Security.Membership]::GeneratePassword($length, $nonAlphaChars) }
$secrets += $s

$s = @{ key = "Settings-Meta-CustomAuthZKey"; value = [System.Web.Security.Membership]::GeneratePassword($length, $nonAlphaChars) }
$secrets += $s

Set-KeyVaultSecrets -rgName $rgName -keyVaultName $keyVaultName -secrets $secrets

}
Function Set-AutoAccountKeyVaultAccess {
    [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$rgName,
    [Parameter(Mandatory=$true)][string]$autoAccountName,
    [Parameter(Mandatory=$true)][string]$kvName
)

# Grant access to the Key Vault to the Automation Run As account.
$connection = Get-AzAutomationConnection -ResourceGroupName $rgName -AutomationAccountName $autoAccountName -Name AzureRunAsConnection
$appID = $connection.FieldDefinitionValues.ApplicationId
Set-AzKeyVaultAccessPolicy -VaultName $kvName -ServicePrincipalName $appID -PermissionsToSecrets Set, Get

}
Function Set-DataFactoryGlobalParameters {
    param
    (
        [parameter(Mandatory = $true)] [String] $globalParametersFilePath,
        [parameter(Mandatory = $true)] [String] $resourceGroupName,
        [parameter(Mandatory = $true)] [String] $dataFactoryName
    )

Import-Module Az.DataFactory

$newGlobalParameters = New-Object 'system.collections.generic.dictionary[string,Microsoft.Azure.Management.DataFactory.Models.GlobalParameterSpecification]'

Write-Host "Getting global parameters JSON from: " $globalParametersFilePath
$globalParametersJson = Get-Content $globalParametersFilePath

Write-Host "Parsing JSON..."
$globalParametersObject = [Newtonsoft.Json.Linq.JObject]::Parse($globalParametersJson)

foreach ($gp in $globalParametersObject.GetEnumerator()) {
    Write-Host "Adding global parameter:" $gp.Key
    $globalParameterValue = $gp.Value.ToObject([Microsoft.Azure.Management.DataFactory.Models.GlobalParameterSpecification])
    $newGlobalParameters.Add($gp.Key, $globalParameterValue)
}

$dataFactory = Get-AzDataFactoryV2 -ResourceGroupName $resourceGroupName -Name $dataFactoryName
$dataFactory.GlobalParameters = $newGlobalParameters

Write-Host "Updating" $newGlobalParameters.Count "global parameters."

Set-AzDataFactoryV2 -InputObject $dataFactory -Force

}
Function Set-KeyVaultSecret
{
param(
	[Parameter(Mandatory=$true)][string]$rgName,
	[Parameter(Mandatory=$true)][string]$keyVaultName,
	[Parameter(Mandatory=$true)][string]$secretName,
	[Parameter(Mandatory=$true)][string]$secretValue
)

$secureValue = ConvertTo-SecureString $secretValue -AsPlainText -Force
$secret = Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $secretName -SecretValue $secureValue
return $secret
# Verify
# (Get-AzKeyVaultSecret -vaultName $keyVaultName -name $secretName).SecretValueText

}
# . .\Set-KeyVaultSecret.ps1
Function Set-KeyVaultSecrets
{
param(
	[Parameter(Mandatory=$true)][string]$rgName,
	[Parameter(Mandatory=$true)][string]$keyVaultName,
	[Parameter(Mandatory=$true)][array]$secrets
)

$secrets | ForEach-Object {
	Set-KeyVaultSecret -rgName $rgName -keyVaultName $keyVaultName -secretName $_.key -secretValue $_.value
}

}
Function Set-WebAppKVAccess
{
param(
    [Parameter(Mandatory=$true)]$rgName,
    [Parameter(Mandatory=$true)]$webAppName,
    [Parameter(Mandatory=$true)]$rgNameKeyVault,
    [Parameter(Mandatory=$true)]$keyVaultName
)

$site = Set-AzWebApp -AssignIdentity $true -Name $webAppName -ResourceGroupName $rgName
$site.Identity

<#
$context = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile.DefaultContext
$graphToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, 
    $context.Environment, $context.Tenant.Id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, 
    "https://graph.microsoft.com").AccessToken
$aadToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, 
    $context.Environment, $context.Tenant.Id.ToString(), $null, 
    [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, "https://graph.windows.net").AccessToken
 
Write-Output "$($context.Account.Id)"

Connect-AzureAD -AadAccessToken $aadToken -AccountId $context.Account.Id -TenantId $context.tenant.id

$principal = Get-AzADServicePrincipal -DisplayName $webAppName
#>
Set-AzKeyVaultAccessPolicy -VaultName $keyVaultName -ResourceGroupName $rgNameKeyVault -ObjectId $site.Identity.PrincipalId -PermissionsToSecrets get,list
}
