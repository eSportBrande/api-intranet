using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Import the custom module
Import-Module "$(Split-Path $PSScriptRoot -Parent)/Modules/PterodactylModule/PterodactylModule.psm1" -Force

# Read and parse the POST body as JSON
Write-Host "Request Body: $($Request.Body)"

$apiKey = "$($env:pterodactylApikey)"
$pterodactylApiUrl = "$($env:pterodactylApiUrl)"

$ActionMapping = @{
    "StartBuildBattle" = "sudo * /bb join BB-Candyland"
    "SetDayTime" = "time set day"
    "SetNightTime" = "time set night"
    "WeatherClear" = "weather clear"
    "ping" = "say hello from API"
}

# Check if the requested action exists in the mapping
if (-not $ActionMapping.ContainsKey($Request.Body.action)) {
    $Body = @{
        status = "error"
        message = "Invalid action requested. Action not found in allowed actions. / Ugyldig handling anmodet. Handling ikke fundet i tilladte handlinger."
    }
    
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = $Body
    })
    
    # Exit the function early
    return
}

else {
    Write-Host "Action found in mapping: $($Request.Body.action)"
}

# Get the mapped command for the requested action
$mappedCommand = $ActionMapping[$Request.Body.action]

$Check = Get-PterodactylServerId -PterodactylApiUrl $pterodactylApiUrl -ApiKey $apiKey -ServerID $Request.Body.identifier

if ($null -ne $Check.attributes) {
    Write-Host "Server ID Exists"
    $Send = Send-PterodactylCommand -PterodactylApiUrl $pterodactylApiUrl -ApiKey $apiKey -ServerID $Request.Body.identifier -Command $mappedCommand

    if ($Send -eq 204) {
        $Body = @{
            status = "success"
            message = "Minecraft responded succesfully on request / Minecraft svarede succesfuldt på requestet."
        }
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body = $Body
        })
        return
    }
    else {
        $Body = @{
            status = "error"
            message = "Ouch! Something went wrong while sending the command to the Minecraft server. / Ouch! Noget gik galt, mens kommandoen blev sendt til Minecraft-serveren."
        }
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::InternalServerError
            Body = $Body
        })
        return
    }
}

else {
    Write-Host "Server ID does not exist"
    $Body = @{
        status = "error"
        message = "Server ID does not exist. / Server ID findes ikke."
    }
    
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::NotFound
        Body = $Body
    })
    
    return
}