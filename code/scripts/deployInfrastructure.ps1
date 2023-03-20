param(
  [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
  [String] $SubscriptionId,
  [Parameter(Mandatory=$true,ValueFromPipeline=$false)]
  [String] $DeploymentName,
  [Parameter(Mandatory=$true,ValueFromPipeline=$false)]
  [String] $Region
)

## Set Warning Message Preference
$WarningPreference = 'SilentlyContinue'


## Variables Section! Paths are Relative to where this Script is called and should not be changed (ie Execute from ./code/scripts/ directory)
$bicepFilePath = '../../infra/main.bicep'
$paramsFilePath = '../../infra/main.params.json'

## Lets do some work...
Try {

  ## Validate Existing AzContext and Subscription
  if (!(Get-AzContext)){

    [void](Login-AzAccount -SubscriptionId $SubscriptionId)
    Write-Host ('Not Logged In... to Azure and Setting SubscriptionId: ' + $SubscriptionId)

  } elseif ($(Get-AzContext).Subscription.id -ne $SubscriptionId) {

    [void](Set-AzContext -SubscriptionId $SubscriptionId)
    Write-Host ('Logged In with UserId: ' + (Get-AzContext).Account + ' | Setting SubscriptionId: ' + $SubscriptionId)

  } else {

    Write-Host ('Logged In with UserId: ' + (Get-AzContext).Account + 'SubsciptionId Confirmed: ' + $SubscriptionId)
  
  }
  
  ## Test if Bicep File Exists where we expect it to be
  if (!(Test-Path $bicepFilePath)){
    Throw ('File Not Found [Make sure you are in ./code/scripts/ directory]: ' + $bicepFilePath)
    Write-Error ($_exception)
  }

  ## Test if Params File Exists where we expect it to be
  if (!(Test-Path $paramsFilePath)){
    Throw ('File Not Found [Make sure you are in ./code/scripts/ directory]: ' + $paramsFilePath)
    Write-Error ($_exception)
  }

  ## Deploy Infrastructure
  $deployment = (New-AzSubscriptionDeployment `
    -Name $DeploymentName `
    -location $Region `
    -TemplateFile $bicepFilePath `
    -TemplateParameterFile $paramsFilePath `
    -deployedBy $(whoami)
  )
  
  ## Output Deployment Data
  Write-Host ($deployment |ConvertTo-Json)
  return ($deployment |ConvertTo-Json)

} catch {

  $_.Exception
  
}