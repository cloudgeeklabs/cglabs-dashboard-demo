# GitHub Setup #

<br />

This PoC will deploy via GitHub Actions using the included Workflows. However there are some "pre-staging" that you must perform manually to allow these to function correction. First you'll need to create an App Registration that has "Contributor" rights scoped to the target subscription. You'll also want to export your Azure FunctionApp 'Publish Profile'. You'll want to then setup both of these as "Repository" variables. 

Supporting Documentation:
[Continuous Delivery FunctionApps](https://learn.microsoft.com/en-us/azure/azure-functions/functions-how-to-github-actions?tabs=dotnet)

<br />
<hr />
<br >

## Creating the App Registration (ServicePrincipal) ##

<br />

We'll need to create the required App Registation needed for GitHub to perform the various Azure Activities needed. This App Registration will need to have OWNER Access to your Azure Subscription where you plan to deploy the DemoApp as it will need to deploy the Azure Resources along with configure various RBAC permissions on the various resources. 

<br />

```powershell
## Build out Expected Variables (This can be prestaged) | Update these around your needs!
$appName = "cglabs-dashboard-app"
$subId= "12345678-1234-abcd-1234-12345678abcd"

## Set SubscriptionId
Set-AzContext $Subscription.Id

$svcPrincipal = New-AzADServicePrincipal -DisplayName $SPName
$spObject = [PSCustomObject]@{
    clientId = $Principal.ApplicationId
    clientSecret = ($Principal.Secret | ConvertFrom-SecureString -AsPlainText)
    subscriptionId = $Subscription.Id
    tenantId = $Subscription.TenantId
}
$spObject | ConvertTo-Json

## or use AZ CLI
 az ad sp create-for-rbac --name 'GitHubActionApp' --role 'contributor' --sdk-authclear

## Sample Output for $spObject
{
"clientId": "12345678-1234-abcd-1234-12345678abcd",
"clientSecret": "abcdefghijklmnopqrstuwvxyz1234567890=",
"subscriptionId": "12345678-1234-abcd-1234-12345678abcd",
"tenantId": "12345678-1234-abcd-1234-12345678abcd"
"activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
"resourceManagerEndpointUrl": "https://management.azure.com/",
"activeDirectoryGraphResourceId": "https://graph.windows.net/",
"sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
"galleryEndpointUrl": "https://gallery.azure.com/",
"managementEndpointUrl": "https://management.core.windows.net/"
}
```
<br />

## Variable\Secrets Setup ##

Setup Variables: 
1. Click on the Repo Name and Select Settings
2. On the Left menu (Under Security) - Expand Secrets and Variables - then Actions.
3. Click the "New Respository Secret" button at the top of the page.
   1. NAME: AZURE_APPSETTINGS - copy the contents of the PublishSettings File verbatium to this varialbe. This is what the Azure FunctionApp will use to deploy it's code/configs. 
   2. NAME: AZURE_CREDS - This will contain the App Registriation info that Github will use to authenticate to Azure and deploy resources and or configurations at the Resources Level. 
4. Next we need to setup the required Variables - Select variables tab and "New Repository Variable"
   1. DASHBOARD_FUNCTIONAPP_NAME = "Name of your Dashboard Function App"
   2. DASHBOARD_RESOURCEGROUP_NAME = "Name of ResourceGroup Dashboard Resources will be deployed"
   3. DASHBOARD_REGION = "Azure Region the resources will be deployed to"

<br />

## Workflows ##
- Workflows: Workflows are defined by a YAML file checked in to your repo and will run when triggered by a specific event. Workflows are defined in the .github/workflows directory in a repository, and a repository can have multiple workflows, each of which can perform a different set of tasks. For example, you can have one workflow to build and test pull requests, another workflow to deploy your application every time a release is created, and still another workflow that adds a label every time someone opens a new issue.
- Runner: A runner is a server that runs your workflows when they're triggered. Each runner can run a single job at a time.
- Events: An event is a specific activity in a repository that triggers a workflow run. (Such as Pull Request or Push)
- Jobs: A job is a set of steps in a workflow that execute on the same runner. You can configure a job's dependencies with other jobs; by default, jobs have no dependencies and run in parallel with each other. Jobs execute on different runners. 
- Actions: You can configure a job's dependencies with other jobs; by default, jobs have no dependencies and run in parallel with each other.

<br />
<hr />