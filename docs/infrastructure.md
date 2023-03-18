# Resources Deployed for PoC #

<br />

Resources deployed via Bicep Files

Deployment of 3 Resource Groups
|Example Name                     | ResourceType            | Notes                                               |
|:--------------------------------|:------------------------|:----------------------------------------------------|
|cglabs-eastus-dashapp-shared     | ResourceGroup           | Shared Services ResGroup                            |
|cglabs-eastus-dashapp-primary    | ResourceGroup           | Primary Application Resources (Primary Region)      |
|cglabs-westus-dashapp-secondary  | ResourceGroup           | Secondary Application Resources (Secondary Region)  |

<br />

cglabs-eastus-dashapp-shared 
|Example Name                | ResourceType            | Notes                                               |
|:---------------------------|:------------------------|:----------------------------------------------------|
|cglabslogsstorage           | StorageAccount v2       | This will be used for storing Billing Logs          |
|cglabs-dashdemo-law         | LogAnalytics Workspace  | This will be the default LAW for all resources      |
|cglabs-dashdemo-grafana     | Azure Managed Grafana   | This one should be obvious                          |
|cglabs-dashdemo-cosmodb     | Azure CosmoDB           | This will be the backend datasource for WebApp      |
|cglabs-dashdemo-tm          | TrafficManager          | Acts as L4 Global LoadBalancer for BackEnd App      |
|cglabs-dashdemo-func        | FunctionApp             | Generates Fake Activity on App (simulate real-world)|

<br />

cglabs-eastus-dashapp-primary
|Example Name                  | ResourceType            | Notes                                               |
|:-----------------------------|:------------------------|:----------------------------------------------------|
|cglabs-eastus-dashdemo-asp    | App Server Plan         | Underlying Infrastructure for App Services          |
|cglabs-eastus-dashdemo-web    | App Services            | Hosts our API/WebApp                                |
|cglabs-eastus-dashdemo-ai     | ApplicationInsights     | Captures telemtry on WebApp for Logging             |
|cglabs-eastus-dashdemo-webtest| AI WebTest              | Test Availability of Application for Logging        |

<br />

cglabs-westus-dashapp-secondary
|Example Name                  | ResourceType            | Notes                                               |
|:-----------------------------|:------------------------|:----------------------------------------------------|
|cglabs-westus-dashdemo-asp    | App Server Plan         | Underlying Infrastructure for App Services          |
|cglabs-westus-dashdemo-web    | App Services            | Hosts our API/WebApp                                |
|cglabs-westus-dashdemo-ai     | ApplicationInsights     | Captures telemtry on WebApp for Logging             |
|cglabs-westus-dashdemo-webtest| AI WebTest              | Test Availability of Application for Logging        |

<br />
<hr />

## DemoApp Diagram ##

<!-- markdownlint-disable MD033 -->
<div style="padding:20px;text-align:center;">
<img src="./topology.svg" />
</div>

## Step 1: Update Parameters

In order to run the script, you will need to modify the `main.params.json` file and supply values for the parameters contained therein. Below is a list of the parameters, what they are for, and any particular notes to be aware of.

| Parameter | Description | Notes |
| :-        | :-          | :-           |
| `primaryRegion` | Primary region of the application | Must be fully qualified (e.g., "East US 2"). |
| `secondaryRegion` | Secondary region of the application | Again, must be fully qualified. |
| `cosmosdbFailoverRegion` | A failover region for cosmos db | Again, must be fully qualified. |
| `domainPrimaryDomain` | TLD domain name (e.g., contoso.com) | This must be an unregistered domain name. Check with GoDaddy or another service to make sure the domain is available before attempting to run this. |


Once you've updated the parameters file and saved it, you are ready to deploy the infrastructure to Azure.

## Step 2: Deploy Bicep

> **NOTES:**  
>
> 1. Given occasional race conditions with ARM, you may need to run this script more than once for everything to pass.  
> 2. Microsoft sponsored account may not allow App Service Domains, or there is a limit. You may need to request a limit increase.
> 3. Cosmos DB may limit your failover region due to resource constraints. If Azure throws an error, update your failover domain and rerun the scripts.

1. In the Azure portal, create a resource group to hold you application.
2. Open a prompt and login to your Azure subscription using `az login`.
3. Make sure you've selected the correct subscription (use `az account set --subscription <subscriptionId>` replacing _\<subscriptionId\>_ with your subscription's Id, if necessary)
4. Now, run the following command, while replacing _\<resourceGroup\>_ with the name of the resource group you created in step 1.

   ```bash
   az deployment group create 
     --resource-group <resourceGroup>
     --template-file main.bicep 
     --parameters main.params.json 
     --query properties.outputs
   ```

The script may take 5-10 minutes to complete, depending on how long it takes to deploy Cosmos DB. Upon completion, the script will output JSON with the configured resources and their information.

> **IMPORTANT: You will need to save this information for future steps. Either open a new command prompt or shell window, or copy and paste the JSON to a temporary document for referencing later.**

### Variable References

The output will contain a number of variables in the following format:

```json
{
  "variableName": {
    "type": "String",
    "value": "variableValue"
  }
}
```

Unless specified, throughout the remainder of the deployment instructions (in the other sections), you will see these variables referenced as `<variableName>`. Where you see `<variableName>`, you will need to replace it with its `variableValue`.

For example, some of the variables returned will include the following (yours will be different):

```json
{
  "resourceGroup": {
    "type": "String",
    "value": "grafana-demo"
  },
  "primaryAppSiteName": {
    "type": "String",
    "value": "grafana-demo-primary"
  }
}
```
