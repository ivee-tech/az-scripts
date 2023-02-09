# $resourceGroupName = 'dawr'
# $topicName = 'devops-topic-001'
# $sub = 'devops-topic-001-sub-acc-devops-eventgridtrigger1'

# $endpoint = (Get-AzEventGridTopic -ResourceGroupName $resourceGroupName -Name $topicName).Endpoint
# $keys = Get-AzEventGridTopicKey -ResourceGroupName $resourceGroupName -Name $topicName

$endpoint = 'https://devops-topic-001.australiaeast-1.eventgrid.azure.net/api/events'
$key1 = '***' # $keys.Key1
$evs = @()

$models = @( '812GTS', 'SF90 Stradale', 'SF90 Spider', 'F8 Tributo', 'F8 Spider', 'Roma', 'Portofino M', 'Monza SP1', 'Monza SP2' )

$n = Get-Random -Minimum 1 -Maximum 10
Write-Host "Number of events: $n"
@(1..$n) | ForEach-Object {
    $eventID = Get-Random 99999
    #Date format should be SortableDateTimePattern (ISO 8601)
    $eventDate = Get-Date -Format s
    $index = Get-Random -Minimum 0 -Maximum ($models.Count - 1)
    $ev = @{
        id          = $eventID
        eventType   = "recordInserted"
        subject     = "myapp/vehicles/cars"
        eventTime   = $eventDate   
        data        = @{
            make  = "Ferrari"
            model = $models[$index]
        }
        dataVersion = "1.0"
    }
    $evs += $ev
}

$body = ConvertTo-Json -InputObject $evs
Write-Host $body
try {
    Invoke-WebRequest -Uri $endpoint -Method POST -Body $body -Headers @{"aeg-sas-key" = $key1 }
}
catch {
    Write-Host "Error: $_"
}

<#
docker build -t evgrid-test:latest .
docker run evgrid-test:latest
docker-compose up --scale evgrid-test=10
docker-compose down
#>
