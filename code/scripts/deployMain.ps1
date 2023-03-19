$WarningPreference = 'SilentlyContinue'

## Set AzContext to targetted Subscription and set grafanaId
[void](Set-AzContext -SubscriptionId '197f4130-ef26-4439-a354-eb5a2a2d7f85')

## Deploy Infrastructure
$deployment = New-AzSubscriptionDeployment `
  -Name 'dashboardDemo' `
  -location 'eastus' `
  -TemplateFile '../../infra/main.bicep'
  -TemplateParameterFile '../../infra/main.params.json' `
  -deployedBy $(whoami) `
