<#
$credentials = "username:password" # Dont forget the : here
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credentials))
$headersGrafana = @{
    "Authorization" = ("Basic "+$encodedCreds)
    "Content-Type" = "application/json"
}
$urlGrafanaOrganizations = "https://grafana.example.com/api/orgs"

Invoke-RestMethod -Uri $urlGrafanaOrganizations -Method Get -Headers $headersGrafana
#>

function New-GrafanaAPIAccess {
    param(
      [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
      [String] $grafanaEndpoint,
      [Parameter(Mandatory=$true,ValueFromPipeline=$false)]
      [String] $DeploymentName,
      [Parameter(Mandatory=$true,ValueFromPipeline=$false)]
      [String] $Region
    )

    $paramsFiles = @((Get-Content ../../infra/main.params.json)|convertFrom-Json)

    $deploymentOutputs = (Get-AzDeployment -Name $DeploymentName).output

    ## Create App Registration

    ## Create Secret

    ## Place Secret into KeyVault
}