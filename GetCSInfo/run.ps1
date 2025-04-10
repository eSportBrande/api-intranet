using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
$objList = @()

# Pterodactyl API configuration
$pterodactylApiUrl = "$($env:pterodactylApiUrl)"
$apiKey = "$($env:pterodactylApikey)"
$CSPublicIPPrefix = "$($env:CSPublicIPPrefix)"

# Set up the headers with authentication
$headers = @{
    "Authorization" = "Bearer $apiKey"
    "Accept" = "application/json"
    "Content-Type" = "application/json"
}

# Query the Pterodactyl API for servers
try {
    $response = Invoke-RestMethod -Uri "$pterodactylApiUrl/client/" -Method GET -Headers $headers
    $servers = $response.data
    
    # Initialize empty array for IPs   
    $ServerData = @()
    # Extract server information and build the IP list
    $excludedServers = @("CS2-TEST-01")
    foreach ($server in $($servers.attributes | Where-Object {$_.name -match "CS2-" -and $_.name -notin $excludedServers})) {
        $serverObj = New-Object psobject
        $serverObj | Add-Member -MemberType NoteProperty -Name "ServerName" -Value "$($server.name)"
        $serverObj | Add-Member -MemberType NoteProperty -Name "ServerID" -Value "$($server.identifier)"
    
        # Only process active servers
        # Get the server allocation details
        $allocation = $server.relationships.allocations.data[0].attributes
        $IP = $allocation.ip
        $serverObj | Add-Member -MemberType NoteProperty -Name "IP" -Value "$($IP)"
        $Port = $allocation.port
        $serverObj | Add-Member -MemberType NoteProperty -Name "Port" -Value "$($Port)"
    
        if ($server.relationships.allocations.data[0].attributes.notes -match "Public") {
            # Notes might be "Public-PORTNUMBER" getting the portnumber
            $PublicPort = $server.relationships.allocations.data[0].attributes.notes -replace "Public-", ""
            $serverObj | Add-Member -MemberType NoteProperty -Name "Public" -Value $true
            $serverObj | Add-Member -MemberType NoteProperty -Name "PublicPort" -Value "$($PublicPort)"
        }
        else {
            $serverObj | Add-Member -MemberType NoteProperty -Name "Public" -Value $false
            $serverObj | Add-Member -MemberType NoteProperty -Name "PublicPort" -Value $null
        }
    
        $ServerData += $serverObj
    }
    
    # If no servers found, provide fallback
    if ($ServerData.Count -eq 0) {
        Write-Host "No active servers found in Pterodactyl. Using fallback servers."
        $ServerData = @(
            @(
                [PSCustomObject]@{
                    ServerName = "WAR-01"
                    ServerID = "fallback1"
                    IP = "$($CSPublicIPPrefix)"
                    Port = "27015"
                    Public = $true
                    PublicPort = "27015"
                },
                [PSCustomObject]@{
                    ServerName = "WAR-02"
                    ServerID = "fallback2"
                    IP = "$($CSPublicIPPrefix)"
                    Port = "27016"
                    Public = $true
                    PublicPort = "27016"
                }
            )
        )
    }
}

catch {
    Write-Host "Failed to connect to Pterodactyl API: $_"
    # Fallback to static server list
    $IPS = @("$($CSPublicIPPrefix):27015", "$($CSPublicIPPrefix):27016")
}


Write-Output "$ServerData"
foreach ($server in $ServerData) {
    $obj = New-Object psobject
    $Name = $($Query.Name)

    Write-Output "Testing connection to $($server.IP):$($server.Port)"
    $Connect = Test-Connection -IPv4 $($server.IP) -TcpPort $($server.Port)
    Write-Output "Connection result: $($Connect) for $($server.IP):$($server.Port)"
    if ($connect) {
        Write-Output "Running query for $($server.IP):$($server.Port)"
        $Query = SourceQuery -Address $($server.IP) -Engine 'Source' -Port "$($server.Port)" -Type 'info'
        $Name = $($Query.Name).Replace("'", "").Replace("eSB - ","")
        if ($Query) {
            $Online = "Online"
        }
        else {
            Write-Output "Query failed for $($server.IP):$($server.Port)"
            $Online = "Offline"
        }
    }

    else {
        $Online = "Offline"
        $Name = $server.ServerName
        $Query = New-Object PSObject -Property @{
            Map = "Offline"
            Players = "Offline"
            Max_players = "Offline"
            Version = "Offline"
        }
    }

    if ($Server.ServerName -match "CS2-RETAKE") {
        $GuideUrl = "$($env:GUIDE_RETAKE)"
        $ServerType = "Retake"
        $PasswordProtected = $false
        $Password = ""
    }
    elseif ($Server.ServerName -match "CS2-NADE") {
        $GuideUrl = "$($env:GUIDE_NADE)"
        $ServerType = "Nade"
        $PasswordProtected = $false
        $Password = ""
    }
    elseif ($Server.ServerName -match "CS2-PREFIRE") {
        $GuideUrl = "$($env:GUIDE_PREFIRE)"
        $ServerType = "Prefire"
        $PasswordProtected = $false
        $Password = ""
    }
    elseif ($Server.ServerName -match "CS2-WAR") {
        $GuideUrl = "$($env:GUIDE_WAR)"
        $ServerType = "War"
        $PasswordProtected = $true
        $Password = "$($env:CSGamePassword)"
    }
    else {
        $GuideUrl = $null
        $ServerType = "NOTSET"
        $PasswordProtected = $false
        $Password = ""
    }

    if ($server.Public -eq $true) {
        $PublicIP = "$($CSPublicIPPrefix):$($server.PublicPort)"
    }
    else {
        $PublicIP = "N/A"
    }
    
    if ($PasswordProtected -eq $true -and $server.Public -eq $true) {
        $LocalConnect = "connect $($server.IP):$($server.Port);password $($Password)"
        $PublicConnect = "connect $($PublicIP);password $($Password)"
    }
    if ($PasswordProtected -eq $false -and $server.Public -eq $true) {
        $LocalConnect = "connect $($server.IP):$($server.Port)"
        $PublicConnect = "connect $($PublicIP)"
    }
    if ($server.Public -eq $false) {
        $PublicConnect = "N/A"
    }

    $obj | Add-Member -MemberType NoteProperty -Name "ServerName" -Value "$($Name)"
    $obj | Add-Member -MemberType NoteProperty -Name "Map" -Value "$($Query.Map)"
    $obj | Add-Member -MemberType NoteProperty -Name "Online" -Value $Online
    $obj | Add-Member -MemberType NoteProperty -Name "Players" -Value "$($Query.Players) / $($Query.Max_players)"
    $obj | Add-Member -MemberType NoteProperty -Name "Version" -Value "$($Query.Version)"
    $obj | Add-Member -MemberType NoteProperty -Name "IP" -Value "$($server.IP):$($server.Port)"
    $obj | Add-Member -MemberType NoteProperty -Name "Guide" -Value "$($GuideUrl)"
    $obj | Add-Member -MemberType NoteProperty -Name "ServerType" -Value "$($ServerType)"
    $obj | Add-Member -MemberType NoteProperty -Name "Public" -Value $($server.Public)
    $obj | Add-Member -MemberType NoteProperty -Name "PublicPort" -Value "$($server.PublicPort)"
    $obj | Add-Member -MemberType NoteProperty -Name "PublicIP" -Value "$($PublicIP)"
    $obj | Add-Member -MemberType NoteProperty -Name "LocalConnect" -Value "$($LocalConnect)"
    $obj | Add-Member -MemberType NoteProperty -Name "PublicConnect" -Value "$($PublicConnect)"
    $obj | Add-Member -MemberType NoteProperty -Name "PasswordProtected" -Value $($PasswordProtected)
    $obj | Add-Member -MemberType NoteProperty -Name "Password" -Value "$($Password)"
    $objList += $obj
}

$jsonObj = $objList | ConvertTo-Json

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $jsonObj
})