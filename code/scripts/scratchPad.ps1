function Enable-GrafanaAPIAccess {
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$false)]
        [String] $keyvaultName,
        [Parameter(Mandatory=$true,ValueFromPipeline=$false)]
        [Microsoft.Azure.Commands.Profile.Models.Core.PSAzureContext] $userContext,
        [Parameter(Mandatory=$true,ValueFromPipeline=$false)]
        [System.Array] $paramsFiles
    )   

    try {

        Write-Host $paramsFiles
        if ($paramsFiles) {
            $appName = ($paramsFiles.parameters.demoAppName.value + '-sp')
        } else {
            Throw ('grafanaAPI.Deployment State Failed!! | Params Object not Loaded')
        }
        
        ## Create new App Reg with Secret
        if (!($grafanaApp = (Get-AzADServicePrincipal -DisplayName $appName))) {
            $grafanaApp = (New-AzADServicePrincipal -DisplayName $appName)   
        }

        ## Add Role Assignment for Grafana API Access (Grafana Admin)
        if ($grafanaApp) {
            [void](New-AzRoleAssignment `
                -ApplicationId ($grafanaApp.AppId) `
                -RoleDefinitionName ('Grafana Admin') `
                -PrincipalType 'ServicePrincipal' `
                -Scope ('/subscriptions/' + ($userContext.Subscription.Id))
            )
        } else {
            Throw ('grafanaAPI.Deployment State Failed!! | Unable to lcoate $grafanaApp')
        }
        
        ## Create appObject to store in KeyVault.
        if ($grafanaApp) {
            $appKeyVaultObject = @{
                clientId = ($grafanaApp.AppId)
                clientSecret = ($grafanaApp.PasswordCredentials.SecretText)
                subscriptionId = $userContext.Subscription.Id
                tenantId = $userContext.Tenant.Id
            }
            $secretValueObj = (($appKeyVaultObject | ConvertTo-Json).ToString())
        } else {
            Throw ('grafanaAPI.Deployment State Failed!! | Unable to lcoate $grafanaApp')
        }

        ## Set Secret in Keyvault
        if (Get-AzKeyVault -Name $keyvaultName){
            $secretvalue = ConvertTo-SecureString $secretValueObj -AsPlainText -Force
            [void](Set-AzKeyVaultSecret -VaultName $keyvaultName -Name ($appName) -SecretValue $secretvalue)
        } else {
            Throw ('grafanaAPI.Deployment State Failed!! | Unable to find Keyvault: ' + $keyvaultName)
        }
        
        ## Return AppInfo
        if ($appKeyVaultObject) {
            return ($appKeyVaultObject)
        } else {
            Throw ('grafanaAPI.Deployment State Failed!! | Unable to locate $appKeyVaultObject for')
        }
        
    } catch {
        Throw $_.Exception
    }
}
function Set-GrafanaDashboard {
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$false)]
        $appKeyVaultObject,
        [Parameter(Mandatory=$true,ValueFromPipeline=$false)]
        $userContext,
        [Parameter(Mandatory=$true,ValueFromPipeline=$false)]
        $grafanaEndpoint,
        [Parameter(Mandatory=$true,ValueFromPipeline=$false)]
        $dashboard
    ) 

    ## Generate the Auth Token Payload ##
    Try {

        $body = @{}
        $body.Add('grant_type', 'client_credentials')
        $body.Add('client_id', $appKeyVaultObject.clientId)
        $body.Add('client_secret', $appKeyVaultObject.clientSecret)
        $body.Add('resource', 'ce34e7e5-485f-4d76-964f-b3d2b16d1e4f')

        ## Politely Request the Bearer Token ##
        $bearerToken = Invoke-RestMethod `
            -Method 'Post' `
            -Uri ('https://login.microsoftonline.com/' + $userContext.Tenant.Id + '/oauth2/token') `
            -Body $body `
            -ContentType 'application/x-www-form-urlencoded'

        ## Generate header with bearerToken
        $Headers = @{}
        $Headers.Add("Authorization","$($bearerToken.token_type) "+ " " + "$($bearerToken.access_token)")

        # call Resource Health API and return results
        $grafanaApiResponse = Invoke-RestMethod `
            -Method "Post" `
            -Uri ($grafanaEndpoint + '/api/dashboards/db') `
            -ContentType 'application/json' `
            -Headers $Headers `
            -Body $dashboardJson

        return ($grafanaApiResponse)

    } catch {
        throw $_.Exception
    }
}
function Set-GrafanaDashboards {
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$false)]
        $appKeyVaultObject,
        [Parameter(Mandatory=$true,ValueFromPipeline=$false)]
        $userContext,
        [Parameter(Mandatory=$true,ValueFromPipeline=$false)]
        $deployInfraOutput
    ) 

    ## Dedicated Vars
    $grafanaDSuid = 'azure-monitor-oob'

    ## Get Dashboard Files
    $dashboards = (Get-ChildItem -Path '../grafanaDashboards/')



    ## functionCall to get BearerToken
    function getBearerToken ($appKeyVaultObject,$userContext) {

        Try{
            $body = @{}
            $body.Add('grant_type', 'client_credentials')
            $body.Add('client_id', $appKeyVaultObject.clientId)
            $body.Add('client_secret', $appKeyVaultObject.clientSecret)
            $body.Add('resource', 'ce34e7e5-485f-4d76-964f-b3d2b16d1e4f')

            ## Politely Request the Bearer Token ##
            $bearerToken = Invoke-RestMethod `
                -Method 'Post' `
                -Uri ('https://login.microsoftonline.com/' + $userContext.Tenant.Id + '/oauth2/token') `
                -Body $body `
                -ContentType 'application/x-www-form-urlencoded'

            return ($bearerToken)
        } catch {
            throw $_.Exception
        }
    }
    ## functionCall to get Grafana Datasource Id for Azure Monitor (this is unique in each deployment)


    
    # Get Bearer Token!
    $bearerToken = (getBearerToken -appKeyVaultObject $appKeyVaultObject -userContext $userContext)

    
    

    Try {

    } catch {
        throw $_.Exception
    }
}