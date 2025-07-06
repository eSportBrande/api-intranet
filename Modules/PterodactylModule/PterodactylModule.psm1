function Get-PterodactylServers {
    param (
        [string]$PterodactylApiUrl,
        [string]$ApiKey,
        [string[]]$ExcludedServers = @("CS2-TEST-01"),
        [string]$ServerNamePrefix
    )

    # Set up the headers with authentication
    $headers = @{
        "Authorization" = "Bearer $apiKey"
        "Accept" = "application/json"
        "Content-Type" = "application/json"
    }

    # Query the Pterodactyl API for servers
    try {
        $response = Invoke-RestMethod -Uri "$PterodactylApiUrl/client/" -Method GET -Headers $headers
        $servers = $response.data
        
        # Initialize empty array for server data
        $ServerData = @()
        $ScheduleData = @() # Always initialize as array

        # Extract server information and build the list
        foreach ($server in $($servers.attributes | Where-Object {$_.name -match "$($ServerNamePrefix)" -and $_.name -notin $ExcludedServers})) {
            $serverObj = New-Object psobject
            $serverObj | Add-Member -MemberType NoteProperty -Name "ServerName" -Value "$($server.name)"
            $serverObj | Add-Member -MemberType NoteProperty -Name "ServerID" -Value "$($server.identifier)"
        
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

            if ($server.relationships.allocations.data[1].attributes.notes -match "CSTV") {
                # Notes might be "CSTV-PORTNUMBER" getting the portnumber
                $CSTVPort = $server.relationships.allocations.data[1].attributes.notes -replace "CSTV-", ""
                $serverObj | Add-Member -MemberType NoteProperty -Name "CSTV" -Value $true
                $serverObj | Add-Member -MemberType NoteProperty -Name "CSTVPort" -Value "$($CSTVPort)"
            }
        
            $schedulesUrl = "$PterodactylApiUrl/client/servers/$($server.identifier)/schedules"
            $schedulesResponse = Invoke-RestMethod -Uri $schedulesUrl -Method GET -Headers $headers

            foreach ($schedule in $schedulesResponse.data) {
                if ($schedule.attributes.name -eq "PowerOn" -or $schedule.attributes.name -eq "PowerOff") {
                    Write-Host $schedule.attributes.name
                    $ScheduleObj = New-Object psobject
                    $ScheduleObj | Add-Member -MemberType NoteProperty -Name "ScheduleName" -Value $schedule.attributes.name
                    $ScheduleObj | Add-Member -MemberType NoteProperty -Name "last_run_at" -Value $schedule.attributes.last_run_at
                    $ScheduleObj | Add-Member -MemberType NoteProperty -Name "next_run_at" -Value $schedule.attributes.next_run_at
                    $ScheduleData += $ScheduleObj
                    Write-Host $ScheduleData
                }
            }

            $serverObj | Add-Member -MemberType NoteProperty -Name "Schedule" -Value $ScheduleData
            $ServerData += $serverObj
        }
    }
    catch {
        Write-Host "Failed to connect to Pterodactyl API: $_"
        # Fallback to static server list
    }
    return $ServerData
}

# Export the functions
Export-ModuleMember -Function Get-PterodactylServers