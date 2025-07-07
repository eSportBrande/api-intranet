using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Import the custom module
Import-Module "$(Split-Path $PSScriptRoot -Parent)/Modules/PterodactylModule/PterodactylModule.psm1" -Force

# Read and parse the POST body as JSON
Write-Host "Request Body: $($Request.Body)"

$apiKey = "$($env:pterodactylApikey)"
$pterodactylApiUrl = "$($env:pterodactylApiUrl)"

$Check = Get-PterodactylServerId -PterodactylApiUrl $pterodactylApiUrl -ApiKey $apiKey -ServerID $Request.Body.identifier

if ($null -ne $Check.attributes) {
    Write-Host "Server ID Exists"
    $Send = Send-PterodactylCommand -PterodactylApiUrl $pterodactylApiUrl -ApiKey $apiKey -ServerID $Request.Body.identifier -Command $Request.Body.action

    if ($Send -eq 204) {
        $Body = @{
            status = "success"
            message = "Command sent successfully."
        }
    }
    else {
        $Body = @{
            status = "error"
            message = "Failed to send command."
        }
    }
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    #Body = $jsonObj
    Body = $Body
})