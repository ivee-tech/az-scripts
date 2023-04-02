Function Set-TestPlanSuite {
    param(
      [ValidateNotNullOrEmpty()]
      [Parameter(Mandatory = $true)][int]$planId,
      [Parameter(Mandatory = $true)][int]$suiteId,
      [Parameter()][string]$suiteName,
      [Parameter()][string]$requirementId,
      [Parameter()][string]$queryString,
      [Parameter(Mandatory=$true)][AzureDevOpsContext]$context
      )
  
    $contentType = 'application/json'
  
    $v = $context.apiVersion + '-preview.1'
    $destTestSuiteUrl = $context.projectBaseUrl + '/testplan/plans/' + $planId + '/suites/' + $suiteId + '?api-version=' + $v
    $destTestSuiteUrl
  
    $smartSingleQuotes = '[\u2019\u2018]'
    $smartDoubleQuotes = '[\u201C\u201D]'
  
    $name = $suiteName -replace $smartSingleQuotes, "'" -replace $smartDoubleQuotes, '"'
  
    $destSuiteData = @{
    }

    if(![string]::IsNullOrEmpty($name)) {
      $destSuiteData.name = $name
    }
    # {
      # parentSuite = @{
      #   id   = $parentSuiteId;
      #   name = $parentName
      # }
    # }
  
    if ($PSBoundParameters.ContainsKey('requirementId') -and $null -ne $requirementId) {
      $destSuiteData.requirementId = $requirementId
    }
  
    if ($PSBoundParameters.ContainsKey('queryString')) {
      $destSuiteData.queryString = $queryString
    }
  
    $data = $destSuiteData | ConvertTo-Json -Depth 10
    if ($context.isOnline) {
      $destTestSuite = Invoke-RestMethod -Headers @{Authorization = "Basic $($context.base64AuthInfo)" } -Uri $destTestSuiteUrl -Method Patch -Body $data -ContentType $contentType
    }
    else {
      $destTestSuite = Invoke-RestMethod -Uri $destTestSuiteUrl -UseDefaultCredentials -Method Patch -Body $data -ContentType $contentType
    }
  
    return $destTestSuite
  
  }