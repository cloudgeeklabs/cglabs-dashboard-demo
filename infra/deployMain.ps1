$WarningPreference = 'SilentlyContinue'

## Set AzContext to targetted Subscription and set grafanaId
$azContext = $(Set-AzContext -SubscriptionId '197f4130-ef26-4439-a354-eb5a2a2d7f85')
$grafanaId = ($azContext.Account.ExtendedProperties.HomeAccountId.Split('.')[0])

## Deploy Infrastructure
$output = New-AzSubscriptionDeployment `
  -Name 'dashboardDemo' `
  -location 'eastus' `
  -TemplateFile './main.bicep' `
  -TemplateParameterFile './main.params.json' `
  -deployedBy $(whoami) `
  -grafanaAADId $grafanaId