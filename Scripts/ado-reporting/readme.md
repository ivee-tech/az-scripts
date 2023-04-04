# Reporting

Azure DevOps provides OOTB tools for reporting and analytics using various dashboard and widgets.
Below is the documentation link to the widgets catalog:

https://learn.microsoft.com/en-us/azure/devops/report/dashboards/widget-catalog?view=azure-devops

For complex or custom reporting, the recommendation is to use a combination of the following:
- Azure DevOps REST API

https://learn.microsoft.com/en-us/rest/api/azure/devops/?view=azure-devops-rest-7.1

- Azure DevOps Analytics

https://learn.microsoft.com/en-us/azure/devops/report/powerbi/what-is-analytics?view=azure-devops

- PowerBI

https://learn.microsoft.com/en-us/azure/devops/report/powerbi/overview?view=azure-devops

- OData queries

https://learn.microsoft.com/en-us/azure/devops/report/extend-analytics/quick-ref?view=azure-devops

- Other tools & widgets, PowerShell, etc.

## Managing OData queries with VS Code

You can use the OData VS Code extension to manage OData queries. It provides features such as syntax highlighting and query encoding/decoding.

![VS Code OData extension](./images/01-vscode-odata.png)

OData queries can be executed in the browser (authenticated request using the current Azure DevOps user credentials).
However, queries are usually complex and require multi-lines for editing.
An OData query can be written on multi-lines in the IDE, but when executed in the browser, it needs to be in a single line and encoded.

You can perform this encoding easily using the `vscode-odata` extension:

- Edit the query in a normal text editor (*.odata* files)

``` OData
# Pass rate trend for a named pipeline
https://analytics.dev.azure.com/daradu/dawr-demo/_odata/v3.0-preview/PipelineRuns?
$apply=filter(
	Pipeline/PipelineName eq 'ETSDemo-CI'
	and CompletedDate ge 2022-01-01Z
	and CanceledCount ne 1
	)
/groupby(
	(CompletedOn/Date),
	aggregate
	($count as TotalCount,
	SucceededCount with sum as SucceededCount ,
	FailedCount with sum as FailedCount,
	PartiallySucceededCount with sum as PartiallySucceededCount))
/compute(
SucceededCount mul 100.0 div TotalCount as PassRate,
FailedCount mul 100.0 div TotalCount as FailRate,
PartiallySucceededCount mul 100.0 div TotalCount as PartiallySuccessfulRate)
&$orderby=CompletedOn/Date asc

```

- Make a copy of the entire query block and select it

![OData query text selected](./images/02-odata-query-selected.png)

- Press CTRL+SHIFT+P (Command palette) and select **`OData: Combine`**

![OData Cmbine](./images/03-odata-combine.png)

- The result will be encoded into a single line and you can use copy / paste to run it in the browser (or CTRL+click in VS Code editor)

![OData query single line](./images/04-odata-query-single-line.png)


## Azure Boards queries

TBD


## Azure Pipelines

See examples here:

https://learn.microsoft.com/en-us/azure/devops/report/extend-analytics/quick-ref?view=azure-devops#azure-pipelines-sample-widgets-and-reports

The queries have been added to the *queries.odata* file:



### Pipeline duration for a named pipeline

``` OData
https://analytics.dev.azure.com/{organization}/{project}/_odata/v3.0-preview/PipelineRuns?
$apply=filter(
	Pipeline/PipelineName eq '{pipelineName}'
	and CompletedDate ge {startdate}
	)
/aggregate(
	$count as TotalCount,
	SucceededCount with sum as SucceededCount ,
	FailedCount with sum as FailedCount,
	PartiallySucceededCount with sum as PartiallySucceededCount ,
	CanceledCount with sum as CanceledCount
	)
```

### Outcome summary for all project pipelines

``` OData
https://analytics.dev.azure.com/{organization}/{project}/_odata/v3.0-preview/PipelineRuns?
$apply=filter(
    CompletedDate ge {startdate}
    )
/groupby(
(Pipeline/PipelineName),
aggregate(
    $count as TotalCount,
    SucceededCount with sum as SucceededCount ,
    FailedCount with sum as FailedCount,
    PartiallySucceededCount with sum as PartiallySucceededCount ,
    CanceledCount with sum as CanceledCount
    ))
```

### Outcome summary for all pipelines

``` OData
https://analytics.dev.azure.com/{organization}/{project}/_odata/v3.0-preview/PipelineRuns?%20
$apply=filter(
	CompletedDate ge {startdate}
	)
/groupby(
(Pipeline/PipelineName), 
aggregate(
	$count as TotalCount,
	SucceededCount with sum as SucceededCount,
	FailedCount with sum as FailedCount,
	PartiallySucceededCount with sum as PartiallySucceededCount,
	CanceledCount with sum as CanceledCount
))
```

### Pass rate trend for a named pipeline

``` OData
https://analytics.dev.azure.com/{organization}/{project}/_odata/v3.0-preview/PipelineRuns?
$apply=filter(
	Pipeline/PipelineName eq '{pipelineName}'
	and CompletedDate ge {startdate}
	and CanceledCount ne 1
	)
/groupby(
	(CompletedOn/Date),
	aggregate
	($count as TotalCount,
	SucceededCount with sum as SucceededCount ,
	FailedCount with sum as FailedCount,
	PartiallySucceededCount with sum as PartiallySucceededCount))
/compute(
SucceededCount mul 100.0 div TotalCount as PassRate,
FailedCount mul 100.0 div TotalCount as FailRate,
PartiallySucceededCount mul 100.0 div TotalCount as PartiallySuccessfulRate)
&$orderby=CompletedOn/Date asc
```

### Return percentile durations for all project pipelines

``` OData
https://analytics.dev.azure.com/{organization}/{project}/_odata/v3.0-preview/PipelineRuns?
$apply=filter(
    CompletedDate ge {startdate}
    and (SucceededCount eq 1 or PartiallySucceededCount eq 1)
    )
/compute(
    percentile_cont(TotalDurationSeconds, 0.5, PipelineId) as Duration50thPercentileInSeconds,
    percentile_cont(TotalDurationSeconds, 0.8, PipelineId) as Duration80thPercentileInSeconds,
    percentile_cont(TotalDurationSeconds, 0.95, PipelineId) as Duration95thPercentileInSeconds)
/groupby(
(Duration50thPercentileInSeconds, Duration80thPercentileInSeconds,Duration95thPercentileInSeconds, Pipeline/PipelineName))
```

