<#
$apiToken = 'glsa_Hmmc2mJ11SVlLtGuU5NMDLvMz0f8YGia_748276bc'
$credentials = "username:password" # Dont forget the : here
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credentials))
$headersGrafana = @{
    "Authorization" = ("Basic "+$encodedCreds)
    "Content-Type" = "application/json"
}
$urlGrafanaOrganizations = "https://grafana.example.com/api/orgs"

Invoke-RestMethod -Uri $urlGrafanaOrganizations -Method Get -Headers $headersGrafana
#>

