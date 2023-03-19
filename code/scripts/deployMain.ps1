$WarningPreference = 'SilentlyContinue'

## Set AzContext to targetted Subscription and set grafanaId
$azContext = $(Set-AzContext -SubscriptionId '197f4130-ef26-4439-a354-eb5a2a2d7f85')
$grafanaId = ($azContext.Account.ExtendedProperties.HomeAccountId.Split('.')[0])

## Deploy Infrastructure
$deployment = New-AzSubscriptionDeployment `
  -Name 'dashboardDemo' `
  -location 'eastus' `
  -TemplateFile '../../infra/main.bicep'
  -TemplateParameterFile '../../infra/main.params.json' `
  -deployedBy $(whoami) `
  -grafanaAADId $grafanaId
