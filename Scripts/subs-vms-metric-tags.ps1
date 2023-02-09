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


# login into your account
Login-AzAccount

# get VM metric & tags

$metricName = 'Percentage CPU'
$startTime = (Get-Date).AddDays(-2)
$endTime = (Get-Date).AddDays(-1)

<#
# get metric & tags for a specific VM, specific subscription
$subscriptionId = '***'
$rgName = '***'
$vmName = '***'
$vm = Get-AzVM -ResourceGroupName $rgName -Name $vmName 
# $tags = Get-AzTag -ResourceId $vm.Id

$mts = Get-VmMetricTags -subscriptionId $subscriptionId -rgName $rgName -vmName $vmName -vmId $vm.Id -metricName $metricName `
    -startTime $startTime -endTime $endTime
$mts
#>


<#
# get all VMs metric & tags for a RG, specific subscription
$subscriptionId = '***'
$rgName = '***'
$mts = Get-VmsMetricTags -subscriptionId $subscriptionId -rgName $rgName -metricName $metricName
$mts
#>
<#
# get all VMs metric & tags for a specific subscription
$subscriptionId = '***'
$mts = Get-SubscriptionVmsMetricTags -subscriptionId $subscriptionId -metricName $metricName
$mts
#>

$mts = Get-AllSubscriptionsVmsMetricTags -metricName $metricName `
    -startTime $startTime -endTime $endTime
<#
# if first element contains the context, run the next block to remove it
$mts[0]
$mts[1]
if($mts[0].Environment -eq 'AzureCloud') {
    $null, $mts = $mts
}
#>

$fileName = 'C:\Data\Azure\vms-metric-tags.2.csv'
$mts | Export-Csv $fileName -NoTypeInformation 

