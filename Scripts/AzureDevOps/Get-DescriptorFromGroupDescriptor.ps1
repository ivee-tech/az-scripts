Function Get-DescriptorFromGroupDescriptor()
{
    Param(
        [Parameter(Mandatory = $true)][string]$groupDescriptor
    )

    $b64 = $groupDescriptor.Split('.')[1]
    $rem = [math]::ieeeremainder( $b64.Length, 4 ) 
    
    $str = ""
    $ln1 = 0
    $descriptor = ""

    if($rem -ne 0)
    {
        $ln1 = (4 - [math]::Abs($rem))
        if ($ln1 -gt 2)
        {
            $ln1 = 2
        }
        $str = ("=" * $ln1)
        $b64 +=  $str
    }
    try {
        Write-Host $b64
        $descriptor = ([System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($b64))).Trim()
    }
    catch {
          $ErrorMessage = $_.Exception.Message
          $FailedItem = $_.Exception.ItemName
          Write-Host "Security Error : " + $ErrorMessage + " Item : " + $FailedItem
    }
    return $descriptor
}