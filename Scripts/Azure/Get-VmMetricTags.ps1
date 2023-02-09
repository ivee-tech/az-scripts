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
