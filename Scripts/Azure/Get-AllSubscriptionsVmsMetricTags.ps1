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
