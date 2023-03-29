param(
    [Parameter(Mandatory=$false,ValueFromPipeline=$false)]
    [String] $deployedBy
)

## Functions
function Build-DemoApp {
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$false)]
        [String] $pathToArtifact
    )

    ## Set Warning Message Preference
    $WarningPreference = 'SilentlyContinue'

    ## Lets do some work...
    Try {

    ## Create Publsih Folder
    $buildFolderPath = New-Item -ItemType Directory './buildFolder' -Force
    
    ## Check for dotnet install
    if (!(dotnet --info)) {
        Write-Information ('Required version of DotNet SDK not found. Please Download @ https://aka.ms/dotnet/download')
        throw
    }
    
    # Build the todo App.
    Write-Information ('Begin Building dotnet Demo App and Publish to: ' + $pathToArtifact)
    $buildApp = $(dotnet publish ../demoApp/todo.csproj -o $buildFolderPath.name -c release)
    if ($buildApp) {
        
        ## Compress publish to artifact for WebApp
        if (!(test-path $pathToArtifact)) {
            Compress-Archive -Path ($buildFolderPath.name + '/*') -DestinationPath $pathToArtifact
        } else {
            Remove-Item $pathToArtifact -Force
            Compress-Archive -Path ($buildFolderPath.name + '/*') -DestinationPath $pathToArtifact
        }
        Write-Information ($buildApp)
        return ('Completed!')
    } else {
        Throw ('Build.BuildApp Stage Failed!')
    }


    
    } catch {

        Throw $_.Exception
    
    }
}
function Push-FileToWebApp {
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [Newtonsoft.Json.Linq.JContainer] $webAppObj,
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string] $subscriptionId,
        [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
        [string] $pathToArtifact
    )

    ## Set Warning Message Preference
    $WarningPreference = 'SilentlyContinue'

    ## Lets do some work...
    Try {
           
        forEach ($webApp in $($webAppObj.ToString() | ConvertFrom-Json -AsHashtable)) {
            
            ## Get WebApps from current Subscription. 
            $webAppConfig = (Get-AzWebApp -name $webApp.webAppName)
            Write-Information ('Found WebApp: ' + $webAppConfig.name)
        }
    

        ## Upload to WebApps
        $publishToWebApp = (Publish-AzWebApp -WebApp $webAppConfig -ArchivePath $pathToArtifact -Force)

        if ($publishToWebApp) {
            Write-Information ('demoApp Deployed to :' + $webAppConfig.name)

            return ($publishToWebApp)
        } else {

            Throw ('Upload.PushFileToApp Stage Failed!!')
        }

    } catch {

        Throw $_.Exception
    
    }
}

function Deploy-FunctionAppCode {
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        $deployInfraOutput
    )

    ## Set Warning Message Preference
    $WarningPreference = 'SilentlyContinue'

    ## Lets do some work...
    Try {
        Write-Verbose('FunctionApp.Upload | Begin Deploying FunctionApp!')
        ## Capture FunctionApp Config
        if ($deployInfraOutput) {
            ## Get Creds from FunctionApp vis AzResourceAction LIST
            $getCreds = Invoke-AzResourceAction -ResourceGroupName $deployInfraOutput.Outputs.demoAppSharedResGroup.Value -ResourceType Microsoft.Web/sites/config ` -ResourceName ($($deployInfraOutput.Outputs.functionAppName.Value) + '/publishingcredentials') -Action list -Force
            $creds = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $($getCreds.Properties.PublishingUserName),$($getCreds.Properties.PublishingPassword))))
        } else {
            Throw ('Build.FunctionApp Stage Failed :: $deployInfraOutput is NULL or invalid.')
        }
        
        ## Create Publsih Folder
        Write-Verbose ('FunctionApp.Upload | Create Artifact Directory')
        $buildFolderPath = New-Item -ItemType Directory './publishArtifact' -Force

        ## Compress publish to artifact for FunctionApp
        Write-Verbose('FunctionApp.Upload | Compressing /functionCode.zip and saving to ' + (($buildFolderPath).FullName + '/functionCode.zip'))
        if (!(test-path $buildFolderPath)) {
            Compress-Archive -Path ('../functions/*') -DestinationPath (($buildFolderPath).FullName + '/functionCode.zip')
        } else {
            Remove-Item (($buildFolderPath).FullName + '/functionCode.zip') -Force
            Compress-Archive -Path ('../functions/*') -DestinationPath (($buildFolderPath).FullName + '/functionCode.zip')
        }

        ## Push ZIP to FunctionApp
        $functionApiUrl = ('https://' + $deployInfraOutput.Outputs.functionAppName.Value + '.scm.azurewebsites.net/api/zip/site/wwwroot')
        Write-Verbose(' FunctionApp.Upload | Uploading FunctionApp Artifact to ' +  $functionApiUrl)
        if ($creds) {

            ## Call API
            $headers = @{Authorization=('Basic ' + $creds)}

            Invoke-RestMethod -Uri $functionApiUrl `
                -Headers $headers `
                -Method PUT `
                -InFile (($buildFolderPath).FullName + '/functionCode.zip') `
                -ContentType "multipart/form-data"
        }
    
    } catch {

        Throw $_.Exception
    
    }
}
function Deploy-Infrastructure {
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$false)]
        [String] $demoDeploymentName,
        [Parameter(Mandatory=$true,ValueFromPipeline=$false)]
        [String] $Region,
        [Parameter(Mandatory=$false,ValueFromPipeline=$false)]
        [String] $deployedBy
    )
  
    ## Set Warning Message Preference
    $WarningPreference = 'SilentlyContinue'
  
  
    ## Variables Section! Paths are Relative to where this Script is called and should not be changed (ie Execute from ./code/scripts/ directory)
    $bicepFilePath = '../../infra/main.bicep'
    $paramsFilePath = '../../infra/main.params.json'
  
    ## Lets do some work...
    Try {
  
      ## Test if Bicep File Exists where we expect it to be
      if (!(Test-Path $bicepFilePath)){
        Throw ('File Not Found [Make sure you are in ./code/scripts/ directory]: ' + $bicepFilePath)
        Write-Error ($_.Exception)
      }
  
      ## Test if Params File Exists where we expect it to be
      if (!(Test-Path $paramsFilePath)){
        Throw ('File Not Found [Make sure you are in ./code/scripts/ directory]: ' + $paramsFilePath)
        Write-Error ($_.Exception)
      }

      $coffeeTimeAscii = @"      
      {
    }   }   {
   {   {  }  }
    }   }{  {
   {  }{  }  }
  ( }{ }{  { )
 .-{   }   }-.
( ( } { } { } )
|`-.._____..-'|
|             ;--.
|   (__)     (__  \
|   (oo)      | )  )
|    \/       |/  /
|             /  /  
|            (  /
\             y'
 `-.._____..-'

"@
      Write-Information ('Begin Deployment: ' + $demoDeploymentName)
      Write-Information ('Time Started: ' + $(Get-Date) +' | [This process can take a bit to complete. Coffee Time!] |')
      Write-Information ($coffeeTimeAscii)
      ## Deploy Infrastructure and Return Object
      $deployment = (New-AzSubscriptionDeployment `
        -Name $demoDeploymentName `
        -location $Region `
        -TemplateFile $bicepFilePath `
        -TemplateParameterFile $paramsFilePath `
        -deployedBy $deployedBy
      )
      if ($deployment) {
        return ($deployment)
        Write-Information ('Time Completed: ' + $(Get-Date) + ' | Told you this would take a bit to finish  ¯\_ (ツ)_/¯ ')
      } else {
        Throw ('InfraDeploy.Deployment Stage Failed!!')
      }
  
    } catch {
  
      Throw $_.Exception
  
    }
}
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


<# __MAIN__ #>
Try {
    
    ## Load Params File
    if (Test-Path '../../infra/main.params.json') {
        $paramsFiles = @((Get-Content ../../infra/main.params.json)|convertFrom-Json)
    } else {
        Throw ('Path to Params Not Found! Plese verify that you are in the ./code/scripts directory')
    }

    ## Create Artifact Path
    $artifactFolderPath = New-Item -ItemType Directory './publishArtifact' -Force
    $pathToArtifact = ($artifactFolderPath.name + '/artifact.zip')
    Write-Information ('Current Working Directory: ' + $(Get-Location))

    ### Create Url for demoApp
    $url = ('https://' + $paramsFiles.Parameters.demoAppName.value + '.' + $paramsFiles.Parameters.dnsObject.value.name)

    ### Update WebTest XML files before running Bicep as there is a dependency on these files existing in the main.bicep
    $PWD
    if (Test-Path ../webTest/webTestPrimaryRegion.xml) {
        ## Configure Primary webTest
        [XML]$webTestPrimarySrc = (Get-Content -Path(Resolve-Path ../webTest/webTestTemplate.xml).path)
        $webTestPrimarySrc.WebTest.Name = ($paramsFiles.Parameters.demoAppName.value + '-' + $paramsFiles.Parameters.primaryRegion.value)
        $webTestPrimarySrc.WebTest.Id = (New-Guid)
        $webTestPrimarySrc.WebTest.Items.Request.Guid = (New-Guid)
        $webTestPrimarySrc.WebTest.Items.Request.Url = ($url)
        $webTestPrimarySrc.Save($primaryTestPath)
        Write-Information ('Main.WebTestXMLCreatePrimary Successful! webTestPrimaryRegion.xml Created.')
    } else {
        Write-Information ('Main.WebTestXMLCreatePrimary Failed! webTestPrimaryRegion.xml is missing.')
    } 
    if (Test-Path ../webTest/webTestSecondaryRegion.xml) {
        ## Configure Secondary webTest
        [XML]$webTestSecondarySrc = (Get-Content -Path (Resolve-Path ../webTest/webTestTemplate.xml).path)
        $webTestSecondarySrc.WebTest.Name = ($paramsFiles.Parameters.demoAppName.value + '-' + $paramsFiles.Parameters.primaryRegion.value)
        $webTestSecondarySrc.WebTest.Id = (New-Guid)
        $webTestSecondarySrc.WebTest.Items.Request.Guid = (New-Guid)
        $webTestSecondarySrc.WebTest.Items.Request.Url = ($url)
        $webTestSecondarySrc.Save($secondaryTestPath)
        Write-Information ('Main.WebTestXMLCreateSecondary Successful! webTestSecondaryRegion.xml Created.')
    } else {
        Write-Information ('Main.WebTestXMLCreateSecondary Failed! webTestSecondaryRegion.xml is missing.')
    } 

    # Validate Existing AzContext and Subscription
    $userContext = (Get-AzContext)
    if (!($userContext)){
        $userContext = (Set-AzContext -SubscriptionId $paramsFiles.parameters.subscriptionId.value)
        Write-Information ('Not Logged In... to Azure and Setting SubscriptionId: ' + $paramsFiles.parameters.subscriptionId.value)
        Write-Information ('')
    } elseif ($($userContext).Subscription.id -ne $paramsFiles.parameters.subscriptionId.value) {
        $userContext = (Set-AzContext -SubscriptionId $paramsFiles.parameters.subscriptionId.value)
        Write-Information  ('Logged In with UserId: ' + (Get-AzContext).Account + ' | Setting SubscriptionId: ' + $paramsFiles.parameters.subscriptionId.value)
        Write-Information ('')
    } else {
        Write-Information  ('Logged In with UserId: ' + (Get-AzContext).Account + ' SubsciptionId Confirmed: ' + $paramsFiles.parameters.subscriptionId.value)
        Write-Information ('')
    }

    ## Deploy Infrastructure and write-output to Screen
    $deployInfraOutput = (Deploy-Infrastructure -demoDeploymentName $paramsFiles.parameters.demoDeploymentName.value -Region $paramsFiles.parameters.primaryRegion.value -deployedBy $deployedBy -InformationAction Continue)
    if ($deployInfraOutput.ProvisioningState -eq 'Succeeded') {
        Write-Verbose ($deployInfraOutput | ConvertTo-Json -Depth 10)
        Write-Information ('Infrastructure Deployment Completed: ' + $deployInfraOutput.Timestamp)
    } else {
        throw ('Main.InfraDeployment Stage Failed!!')
    }
    
    ## Configure Grafana App Reg and put ClientId/Secret into Keyvault
    if (!(Get-AzADServicePrincipal -DisplayName ($paramsFiles.parameters.demoAppName.value + '-sp'))) {
        $appKeyVaultObject = (Enable-GrafanaAPIAccess -keyvaultName $deployInfraOutput.Outputs.keyvaultName.value -userContext $userContext -paramsFiles $paramsFiles)
        if ($appKeyVaultObject.displayName -like ($paramsFiles.parameters.demoAppName.value + '-sp')) {
            Write-Information ('New Grafana App Reg Created and Assigned [Grafana Admin] Role: ' + $appKeyVaultObject.displayName)
        } else {
            Throw ('Main.grafanaAPI Stage Failed!! | Unable to validate')
        }  

         ## Configure Grafana Dashboards via Grafana API
        #$setGrafanaDashboard = (Set-GrafanaDashboards -appKeyVaultObject $appKeyVaultObject -userContext $userContext -grafanaEndpoint $deployInfraOutput.Outputs.grafanaEndpoint.Value)
    } else {
        Write-Information ('Granfa API app registration already Existed: ' + ($paramsFiles.parameters.demoAppName.value + '-sp') + ' ...skipping' )
    }

    ## Perform Build Steps Here!!
    $build = (Build-DemoApp -pathToArtifact $pathToArtifact -InformationAction Continue)
    if ($build = 'Completed!') {
        Write-Verbose ('Build Successful: ' + $build[2])
        Write-Information ('Build Stage Completed')
    } else {
        Throw ('Main.Build Stage Failed!!')
    }
    
    
    # Convert WebAppObjs from Deployment and pass into uploadFileToWebApp Function..
    $webAppObjects = ($deployInfraOutput.Outputs.webAppInfo.value)
    foreach ($webAppObj in $webAppObjects) {
        if($webAppObj) {
            $uploadReturn = (Push-FileToWebApp -webAppObj $webAppObj -SubscriptionId $paramsFiles.parameters.subscriptionId.value -pathToArtifact $pathToArtifact -InformationAction Continue)
        } else { 
            Throw ('Main.UploadFiles Stage Failed!! | WebAppObj is NULL')
        }
    }

    # Call Deploy-FunctionAppCode to upload our FunctionApp!
    Write-Information ('Begin Deploying FunctionApp Code.')
    if ($deployInfraOutput) {
        [void](Deploy-FunctionAppCode -deployInfraOutput $deployInfraOutput)
    } else {
        Throw ('Main.UploadFunctionApp Stage Failed!! | $deployInfraOutput is NULL')
    }

    if ($uploadReturn) {
        Write-Information ('')
        return ('All Done! You can view the App at: https://' + $url + ' | Grafana Login: ' + $deployInfraOutput.outputs.grafanaEndpoint.value)
    } else {
        Throw ('Main.UploadFiles Stage Failed!!')
    }


} catch {

    Throw $_.Exception

}