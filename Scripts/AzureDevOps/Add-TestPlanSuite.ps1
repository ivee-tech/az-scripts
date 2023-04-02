Function Add-TestPlanSuite {
    param(
      [ValidateNotNullOrEmpty()]
      [Parameter(Mandatory = $true)][int]$planId,
      [Parameter(Mandatory = $true)][int]$parentSuiteId,
      [Parameter(Mandatory = $true)][string]$parentSuiteName,
      [Parameter(Mandatory = $true)][string]$suiteName,
      [Parameter(Mandatory = $true)][string]
      [ValidateSet("staticTestSuite", "requirementTestSuite", "dynamicTestSuite")]
      $suiteType,
      [Parameter()][string]$requirementId,
      [Parameter()][string]$queryString,
      [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
      )
  
    $contentType = 'application/json'
  
    $v = $context.apiVersion + '-preview.1'
    $destTestSuiteUrl = $context.projectBaseUrl + '/testplan/plans/' + $planId + '/suites/' + $parentSuiteId + '?api-version=' + $v
    $destTestSuiteUrl
  
    $smartSingleQuotes = '[\u2019\u2018]'
    $smartDoubleQuotes = '[\u201C\u201D]'
  
    $name = $suiteName -replace $smartSingleQuotes, "'" -replace $smartDoubleQuotes, '"'
    $parentName = $parentSuiteName -replace $smartSingleQuotes, "'" -replace $smartDoubleQuotes, '"'
  
    $destSuiteData = @{
      suiteType   = $suiteType;
      name        = $name;
      parentSuite = @{
        id   = $parentSuiteId;
        name = $parentName
      }
    }
  
    if ($PSBoundParameters.ContainsKey('requirementId') -and $null -ne $requirementId) {
      $destSuiteData.requirementId = $requirementId
    }
  
    if ($PSBoundParameters.ContainsKey('queryString')) {
      $destSuiteData.queryString = $queryString
    }
  
    $data = $destSuiteData | ConvertTo-Json -Depth 100
    if ($context.isOnline) {
      $destTestSuite = Invoke-RestMethod -Headers @{Authorization = "Basic $($context.base64AuthInfo)" } -Uri $destTestSuiteUrl -Method POST -Body $data -ContentType $contentType
    }
    else {
      $destTestSuite = Invoke-RestMethod -Uri $destTestSuiteUrl -UseDefaultCredentials -Method POST -Body $data -ContentType $contentType
    }
  
    return $destTestSuite
  
  }