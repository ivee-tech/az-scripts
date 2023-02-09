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