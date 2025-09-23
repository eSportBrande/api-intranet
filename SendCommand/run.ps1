using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Import the custom module
Import-Module "$(Split-Path $PSScriptRoot -Parent)/Modules/PterodactylModule/PterodactylModule.psm1" -Force

# Read and parse the POST body as JSON
Write-Host "Request Body: $($Request.Body)"

Write-Host "Validating user input..."
# Server ID must be provided and must be valid: Example Server ID´s 0f81bb6f, 21bc66b7, 46288edb. Here we detect if the Server ID is malicious or not with regex.
if ($Request.Body.identifier -notmatch '^[a-zA-Z0-9]{8,16}$') {
    Write-Host "Invalid or missing identifier in request body."
    $Body = @{
        status = "error"
        message = "Invalid or missing identifier in request body. / Ugyldig eller manglende identifikator i anmodningskroppen."
    }
    
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = $Body
    })
    
    # Exit the function early
    return
}

# Action must be provided and must be valid: Example actions are StartBuildBattle, SetDayTime, SetNightTime, WeatherClear, ping, teleport
$AllowedActions = @(
    "StartBuildBattle",
    "StopBuildBattle",
    "SetDayTime", 
    "SetNightTime", 
    "WeatherClear", 
    "ping", 
    "teleport",
    "give",
    "KillAllMobs"
)
$RequestAction = $Request.Body.action.Trim()
if ($AllowedActions -notcontains $RequestAction) {
    Write-Host "Invalid or missing action in request body."
    $Body = @{
        status = "error"
        message = "Invalid or missing action in request body. / Ugyldig eller manglende handling i anmodningskroppen."
    }
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = $Body
    })
    return
}


$apiKey = "$($env:pterodactylApikey)"
$pterodactylApiUrl = "$($env:pterodactylApiUrl)"

if ($RequestAction -eq "StartBuildBattle") {
    if (-not $Request.Body.theme) {
        Write-Host "No theme selected, using default Build Battle command"
        $BuildBattleTheme = $false
    }
    elseif ($Request.Body.theme -is [string] -and $Request.Body.theme -match '^[a-zA-Z0-9]+$') {
        $BuildBattleTheme = $Request.Body.theme
    }
    else {
        $Body = @{
            status = "error"
            message = "Invalid theme. Only single alphanumeric words are allowed. / Ugyldigt tema. Kun enkelte alfanumeriske ord er tilladt."
        }
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::BadRequest
            Body = $Body
        })
        return
    }

    if (-not $Request.Body.type) {
        Write-Host "No type selected, using default Build Battle command. Which means Solo mode, and voting process."
        $BuildBattleType = "solo"
    }
    else {
        if ($Request.Body.type -notin @('solo', 'team')) {
            $Body = @{
                status = "error"
                message = "Invalid type. Allowed values are: solo, gtb, team. / Ugyldig type. Tilladte værdier er: solo, gtb, team."
            }
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::BadRequest
                Body = $Body
            })
            return
        }
        else {
            $BuildBattleType = $Request.Body.type
        }
    }

# Making final command for Build Battle like this:
# bba forceplay BB-Candyland <type> <theme>

    if ($BuildBattleTheme -eq $false) {
        Write-Host "No theme selected, using default Build Battle command without theme."
        if ($BuildBattleType -eq "team") {
            Write-Host "Using team mode for Build Battle."
            $FullCommand = "bba forceplay ESB-Team"
        }
        else {
            Write-Host "Using solo mode for Build Battle."
            $FullCommand = "bba forceplay ESB-Solo"
        }
    }
    elseif ($BuildBattleTheme -is [string]) {
        Write-Host "Using theme: $($BuildBattleTheme) for Build Battle."
        if ($BuildBattleType -eq "team") {
            Write-Host "Using team mode for Build Battle."
            $FullCommand = "bba forceplay ESB-Team $($BuildBattleTheme)"
        }
        else {
            Write-Host "Using solo mode for Build Battle."
            $FullCommand = "bba forceplay ESB-Solo $($BuildBattleTheme)"
        }
    }
    else {
        Write-Host "Invalid theme or type provided for Build Battle."
        $Body = @{
            status = "error"
            message = "Invalid theme or type provided for Build Battle. / Ugyldigt tema eller type angivet for Build Battle."
        }
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::BadRequest
            Body = $Body
        })
        return
    }
    $MappedCommand = $FullCommand
    Write-Host "Mapped command for Build Battle: $($MappedCommand)"
}

elseif ($RequestAction -eq "teleport") {
    if (-not $Request.Body.From -or -not $Request.Body.To) {
        Write-Host "No players specified for teleport action."
        $Body = @{
            status = "error"
            message = "No players specified for teleport action. / Ingen spillere angivet til teleport-handling."
        }
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::BadRequest
            Body = $Body
        })
        return
    }
    if (($Request.Body.From -is [string]) -and ($Request.Body.To -is [string]) -and ($Request.Body.From -match '^[a-zA-Z0-9]+$') -and ($Request.Body.To -match '^[a-zA-Z0-9]+$')) {
        Write-Host "Valid players specified for teleport action."
        $From = $Request.Body.From
        $To = $Request.Body.To
        # Construct the teleport command
        $MappedCommand = "tp $($From) $($To)"
        Write-Host "Mapped command for teleport action: $($MappedCommand)"
    }
    else {
        Write-Host "Invalid player names provided for teleport action."
        $Body = @{
            status = "error"
            message = "Invalid player names provided for teleport action. / Ugyldige spillernavne angivet til teleport-handling."
        }
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::BadRequest
            Body = $Body
        })
        return
    }
}

elseif ($RequestAction -eq "give") {
    if (-not $Request.Body.Item -or -not $Request.Body.To) {
        Write-Host "No players or item specified for give action"
        $Body = @{
            status = "error"
            message = "No players or item specified for give action. / Ingen spillere eller genstand angivet til give-handling."
        }
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::BadRequest
            Body = $Body
        })
        return
    }
    if (($Request.Body.Item -is [string]) -and ($Request.Body.To -is [string]) -and ($Request.Body.Item -match '^[a-zA-Z0-9]+$') -and ($Request.Body.To -match '^[a-zA-Z0-9]+$')) {
        Write-Host "Valid player name and item specified for give action."
        $To = $Request.Body.To
        $Item = $Request.Body.Item
        # Construct the give command
        $MappedCommand = "give $($To) $($Item)"
        Write-Host "Mapped command for give action: $($MappedCommand)"
    }
    else {
        Write-Host "Invalid player name or item provided for give action."
        $Body = @{
            status = "error"
            message = "Invalid player name or item provided for give action. / Ugyldige spillernavne eller genstand angivet til give-handling."
        }
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::BadRequest
            Body = $Body
        })
        return
    }
}

else {
    # Lets map the command for other actions
    $ActionMapping = @{
        "SetDayTime" = "time set day"
        "StopBuildBattle" = "sudo * /buildbattle leave"
        "SetNightTime" = "time set night"
        "WeatherClear" = "weather clear"
        "ping" = "say hello from API"
        "KillAllMobs" = "kill @e[type=!player]"
    }
    
    # Check if the requested action exists in the mapping
    if (-not $ActionMapping.ContainsKey($RequestAction)) {
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
        Write-Host "Action found in mapping: $($RequestAction)"
    }
    
    # Get the mapped command for the requested action
    $MappedCommand = $ActionMapping[$RequestAction]
}

Write-Host "Checking if server ID exists in Pterodactyl."
$Check = Get-PterodactylServerId -PterodactylApiUrl $pterodactylApiUrl -ApiKey $apiKey -ServerID $Request.Body.identifier

if ($null -ne $Check.attributes) {
    Write-Host "Server ID Exists sending command to server: $($Request.Body.identifier)"
    Send-DiscordMessage -WebhookUrl $env:DiscordCommandWebhook -Text "Sending command to server: $($Request.Body.identifier) with command: $($MappedCommand)"
    $Send = Send-PterodactylCommand -PterodactylApiUrl $pterodactylApiUrl -ApiKey $apiKey -ServerID $Request.Body.identifier -Command $MappedCommand

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