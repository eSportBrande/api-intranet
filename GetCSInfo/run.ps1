using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Import the custom module
Import-Module "$(Split-Path $PSScriptRoot -Parent)/Modules/CSModule/CSModule.psm1" -Force
Import-Module "$(Split-Path $PSScriptRoot -Parent)/Modules/PterodactylModule/PterodactylModule.psm1" -Force

# Write to the Azure Functions log stream.
$objList = @()

# Pterodactyl API configuration
$pterodactylApiUrl = "$($env:pterodactylApiUrl)"
$apiKey = "$($env:pterodactylApikey)"
$CSPublicIPPrefix = "$($env:CSPublicIPPrefix)"

# Get the server data from the Pterodactyl API using our module
Write-Host "Fetching server data from Pterodactyl API..."
$ServerData = Get-PterodactylServers -PterodactylApiUrl $pterodactylApiUrl -ApiKey $apiKey -ServerNamePrefix "CS2-"
Write-Host "Server data fetched successfully."

Write-Output "$ServerData"
foreach ($server in $ServerData) {
    # Get detailed server information using our module function
    $serverDetails = Get-CSServerDetails -Server $server -PublicIPPrefix $CSPublicIPPrefix -CSGamePassword $env:CSGamePassword
    $objList += $serverDetails
}

# Sort the servers: CS2-WAR first, CS2-NADE second, then everything else
$sortedObjList = $objList | Sort-Object -Property @{
    Expression = {
        switch -Regex ($_.ServerName) {
            'CS2-WAR' { 0 }
            'eBot ::' { 1 }
            'CS2-NADE' { 2 }
            default { 3 }
        }
    }
}

$jsonObj = $sortedObjList | ConvertTo-Json

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $jsonObj
})