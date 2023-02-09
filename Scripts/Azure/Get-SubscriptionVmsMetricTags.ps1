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