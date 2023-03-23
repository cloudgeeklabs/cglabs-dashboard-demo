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

        return ($buildApp)
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

Function Deploy-Infrastructure {
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

<# __MAIN__ #>
Try {
    
    $params = (@(Get-Content ../../infra/main.params.json)|convertFrom-Json)

    ## Create Artifact Path
    $artifactFolderPath = New-Item -ItemType Directory './publishArtifact' -Force
    $pathToArtifact = ($artifactFolderPath.name + '/artifact.zip')

    ## Validate Existing AzContext and Subscription
    if (!(Get-AzContext)){
        [void](Login-AzAccount -SubscriptionId $params.parameters.subscriptionId.value)
        Write-Information ('Not Logged In... to Azure and Setting SubscriptionId: ' + $params.parameters.subscriptionId.value)
        Write-Information ('')
    } elseif ($(Get-AzContext).Subscription.id -ne $params.parameters.subscriptionId.value) {
        [void](Set-AzContext -SubscriptionId $params.parameters.subscriptionId.value)
        Write-Information  ('Logged In with UserId: ' + (Get-AzContext).Account + ' | Setting SubscriptionId: ' + $params.parameters.subscriptionId.value)
        Write-Information ('')
    } else {
        Write-Information  ('Logged In with UserId: ' + (Get-AzContext).Account + ' SubsciptionId Confirmed: ' + $params.parameters.subscriptionId.value)
        Write-Information ('')
    }

    ## Deploy Infrastructure and write-output to Screen
    $deployInfraOutput = (Deploy-Infrastructure -$demoDeploymentName $params.parameters.demoDeploymentName.value -Region $params.parameters.primaryRegion.value -deployedBy $deployedBy -InformationAction Continue)
    if ($deployInfraOutput.ProvisioningState -eq 'Succeeded') {
        Write-Verbose ($deployInfraOutput | ConvertTo-Json -Depth 10)
        Write-Information ('Infrastructure Deployment Completed: ' + $deployInfraOutput.Timestamp)
    } else {
        throw ('Main.InfraDeployment Stage Failed!!')
    }
    

    ## Perform Build Steps Here!!
    $build = (Build-DemoApp -pathToArtifact $pathToArtifact -InformationAction Continue)
    if ($build) {
        Write-Verbose ('Build Successful: ' + $build[2])
        Write-Information ('Build Stage Completed')
    } else {
        Throw ('Main.Build Stage Failed!!')
    }
    
    
    # Convert WebAppObjs from Deployment and pass into uploadFileToWebApp Function..
    $webAppObjects = ($deployInfraOutput.Outputs.webAppInfo.value)
    foreach ($webAppObj in $webAppObjects) {
        if($webAppObj) {
            $uploadReturn = (Push-FileToWebApp -webAppObj $webAppObj -SubscriptionId $params.parameters.subscriptionId.value -pathToArtifact $pathToArtifact -InformationAction Continue)
        } else { Throw ('WebAppObj is NULL')}
    }

    if ($uploadReturn) {
        Write-Information ('')
        return ('All Done! You can view the App at: https://' + $deployInfraOutput.outputs.domainFQDN.value + ' | Grafana Login: ' + $deployInfraOutput.outputs.grafanaEndpoint.value)
    } else {
        Throw ('Main.UploadFiles Stage Failed!!')
    }


} catch {

    Throw $_.Exception

}