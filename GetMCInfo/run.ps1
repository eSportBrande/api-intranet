using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Import the custom module
Import-Module "$(Split-Path $PSScriptRoot -Parent)/Modules/MCModule/MCModule.psm1" -Force
Import-Module "$(Split-Path $PSScriptRoot -Parent)/Modules/PterodactylModule/PterodactylModule.psm1" -Force

# Write to the Azure Functions log stream.
$objList = @()

# Pterodactyl API configuration
$pterodactylApiUrl = "$($env:pterodactylApiUrl)"
$apiKey = "$($env:pterodactylApikey)"
$CSPublicIPPrefix = "$($env:MCPublicIPPrefix)"
$ExcludedServers = "$($env:MCExcludedServers)"
$ExcludedServers = $ExcludedServers -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }

# Get the server data from the Pterodactyl API using our module
Write-Host "Fetching server data from Pterodactyl API..."
$ServerData = Get-PterodactylServers -PterodactylApiUrl $pterodactylApiUrl -ApiKey $apiKey -ServerNamePrefix "MC-" -ExcludedServers $ExcludedServers
Write-Host "Server data fetched successfully."

Write-Output "$ServerData"
foreach ($server in $ServerData) {
    # Get detailed server information using our module function
    Write-Host $server.Port
    $serverDetails = Get-MCServerDetails -server $server -PublicIPPrefix $CSPublicIPPrefix
    $objList += $serverDetails
}

$jsonObj = $objList | ConvertTo-Json -Depth 100

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $jsonObj
})