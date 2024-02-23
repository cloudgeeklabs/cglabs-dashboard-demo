# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()
# The 'IsPastDue' property is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}


<# __main__ code below this point #>
Try {

    ## Collect functionAppUrl from AppSettings
    $functionAppUrl = (Get-ChildItem env:APPSETTING_DEMOAPPURL).value

    ## Create Random number of iterations of Call
    $total = (Get-Random -Maximum 100 -Minimum 20)
    $i = 0

    Write-Information ('Total Interations: ' + $total)
    $ErrorActionPreference = 'SilentlyContinue'
    do {
        # Build Random List of Endpoints to Call
        $randomList = @(
            ($functionAppUrl + '/Item/Create')
            ($functionAppUrl + '/Item')
            ($functionAppUrl + '/Item/Details/93ea9152-5dc0-4b76-bb9d-d432605b5756?category=Dashboard%20Work')
            ($functionAppUrl + '/Item/Details/0d5239b8-1c33-4771-b85a-19cd11f9362a?category=Improvements')
            ($functionAppUrl)
            ($functionAppUrl + '/' + (New-Guid)) 
        )
        $webRequest = '' ## Clear out $webRequest for each iteration!
        $Url = (Get-Random -InputObject $randomList)
        $webRequest = (Invoke-WebRequest -Uri $Url) 
        $i++
        if ($webRequest) {
            Write-Information ('URL: ' + $Url + ' | StatusCode: ' +  $webRequest.StatusCode)
        } else {
            Write-Information ('URL: ' + $Url + ' | StatusCode: 404 [FAILED]')
        }

    } while ($i -lt $total)

} catch [System.SystemException] {
        
    ## Used to Capture Generic Exceptions and Throw to Error Output ##
    Write-Error -Message $_.Exception  
    throw $_.Exception

}