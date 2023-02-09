function Test-Assertion 
{ 
<# 
.Synopsis 
A PowerShell assert function. 
.Description 
A PowerShell assert function. 
 
An assert function is used to display errors when some condition is not true. The error message will typically contain the file, line number, and the line of code that caused the failing assertion. 
 
This function throws an error in these conditions: 
* assertion is $false 
* assertion is $null 
* assertion is not of type System.Boolean 
* Test-Assertion is used in a pipeline and multiple values are piped 
* Test-Assertion is used in a pipeline and no values are piped 
.Example 
Test-Assertion (0 -le (get-random -minimum 0 -maximum 10)) 
Tests that 0 is less than or equal to the value returned from the get-random function call. 
.Example 
Test-Assertion (0 -le (get-random -minimum 0 -maximum 10)) -Verbose -Debug 
Use the -Verbose and -Debug switches in Test-Assertion to help investigate failing assertions. 
 
-Verbose displays information about passing assertions 
-Debug gives you a chance to debug a failing assertion 
.Example 
0 -le (get-random -minimum 0 -maximum 10) | Test-Assertion -Verbose -Debug 
Use Test-Assertion in a pipeline. 
 
Note: 
If Test-Assertion is used in a pipeline, Test-Assertion will fail if more than one value is piped or if no values are piped. 
.Inputs 
System.Boolean 
System.Object 
.Outputs 
None 
#> 
    [CmdletBinding()] 
    Param( 
        #The value to assert. 
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0)] 
        [AllowNull()] 
        [AllowEmptyCollection()] 
        [System.Object] 
        $InputObject 
    ) 
 
    Begin 
    { 
        $info = '{0}, file {1}, line {2}' -f @( 
            $MyInvocation.Line.Trim(), 
            $MyInvocation.ScriptName, 
            $MyInvocation.ScriptLineNumber 
        ) 
        $inputCount = 0 
        $inputFromPipeline = -not $PSBoundParameters.ContainsKey('InputObject') 
    } 
 
    Process 
    { 
        $inputCount++ 
        if ($inputCount -gt 1) { 
            $message = "Assertion failed (more than one object piped to Test-Assertion): $info" 
            Write-Debug -Message $message 
            throw $message 
        } 
        if ($null -eq $InputObject) { 
            $message = "Assertion failed (`$InputObject is `$null): $info" 
            Write-Debug -Message $message 
            throw  $message 
        } 
        if ($InputObject -isnot [System.Boolean]) { 
            $type = $InputObject.GetType().FullName 
            $value = if ($InputObject -is [System.String]) {"'$InputObject'"} else {"{$InputObject}"} 
            $message = "Assertion failed (`$InputObject is of type $type with value $value): $info" 
            Write-Debug -Message $message 
            throw $message 
        } 
        if (-not $InputObject) { 
            $message = "Assertion failed (`$InputObject is `$false): $info" 
            Write-Debug -Message $message 
            throw $message 
        } 
        Write-Verbose -Message "Assertion passed: $info" 
    } 
 
    End 
    { 
        if ($inputFromPipeline -and $inputCount -lt 1) { 
            $message = "Assertion failed (no objects piped to Test-Assertion): $info" 
            Write-Debug -Message $message 
            throw $message 
        } 
    } 
} 