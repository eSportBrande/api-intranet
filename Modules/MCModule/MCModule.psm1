function Get-MinecraftServerStatus {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ServerIP,
        [int]$Port = 25565,
        [int]$Timeout = 5000
    )

    try {
        # Create a new TCP client
        $client = New-Object System.Net.Sockets.TcpClient
        $client.ReceiveTimeout = $Timeout
        $client.SendTimeout = $Timeout

        # Connect to the server
        $connectTask = $client.ConnectAsync($ServerIP, $Port)
        if (-not ($connectTask.Wait($Timeout))) {
            Write-Error "Connection timed out"
            return $null
        }

        if ($client.Connected) {
            $stream = $client.GetStream()

            # Send a handshake packet (protocol version -1 for status query)
            $handshake = @(
                0x00, # Packet ID
                0xFF, 0xFF, 0xFF, 0xFF, 0x0F, # Protocol version -1 (VarInt)
                [byte]$ServerIP.Length # Host length
            ) + [System.Text.Encoding]::ASCII.GetBytes($ServerIP) + @(
                [byte]($Port -shr 8), [byte]($Port -band 0xFF), # Port as unsigned short (big-endian)
                0x01 # Next state (1 for status)
            )

            # Prefix with length
            $handshakeWithLength = @([byte]$handshake.Length) + $handshake
            $stream.Write($handshakeWithLength, 0, $handshakeWithLength.Length)

            # Send status request
            $stream.Write(@(0x01, 0x00), 0, 2) # Length 1, Packet ID 0

            # Read response
            $buffer = New-Object byte[] 4096
            $bytesRead = $stream.Read($buffer, 0, $buffer.Length)

            if ($bytesRead -gt 0) {
                # Skip packet length and packet ID
                $index = 0
                
                # Skip the packet length (VarInt)
                while (($buffer[$index] -band 0x80) -ne 0) { $index++ }
                $index++
                
                # Skip the packet ID (VarInt) - always 0 for response
                while (($buffer[$index] -band 0x80) -ne 0) { $index++ }
                $index++
                
                # Skip the JSON length (VarInt)
                $jsonLengthStart = $index
                while (($buffer[$index] -band 0x80) -ne 0) { $index++ }
                $index++
                
                # Extract the JSON string
                $jsonString = [System.Text.Encoding]::UTF8.GetString($buffer, $index, $bytesRead - $index)
                
                # Try to parse the JSON
                try {
                    $serverInfo = $jsonString | ConvertFrom-Json
                    
                    # Create a simplified result object with just what we need
                    $result = New-Object PSObject -Property @{
                        Version = $serverInfo.version.name
                        Protocol = $serverInfo.version.protocol
                        Players = @{
                            Online = $serverInfo.players.online
                            Max = $serverInfo.players.max
                            List = @()
                        }
                        Description = if ($serverInfo.description.text) { $serverInfo.description.text } else { $serverInfo.description }
                    }
                    
                    # Add player list if available
                    if ($serverInfo.players.sample) {
                        $result.Players.List = $serverInfo.players.sample.name
                    }
                    
                    return $result
                }
                catch {
                    Write-Error "Failed to parse server response: $_"
                    return $null
                }
            }
            else {
                Write-Error "No data received from server"
                return $null
            }
        }
    }
    catch {
        Write-Error "Error querying server: $_"
        return $null
    }
    finally {
        # Clean up
        if ($stream) { $stream.Close() }
        if ($client) { $client.Close() }
    }
}
function Get-MCServerDetails {
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]$server,
        [string]$PublicIPPrefix
    )

    $obj = New-Object psobject

    Write-Host "Testing connection to $($server.IP):$($server.Port)"
    $Connect = Test-Connection -IPv4 $($server.IP) -TcpPort $($server.Port)
    Write-Host "Connection result: $($Connect) for $($server.IP):$($server.Port)"

    if ($connect) {
        Write-Host "Running query for $($server.IP):$($server.Port)"
        $Query = Get-MinecraftServerStatus -ServerIP $($server.IP) -Port $($server.Port)
        if ($Query) {
            $Online = "Online"
        }
        else {
            Write-Host "Query failed for $($server.IP):$($server.Port)"
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

    if ($server.Public -eq $true) {
        $PublicIP = "$($PublicIPPrefix):$($server.PublicPort)"
        $PublicPort  = "$($server.PublicPort)"
    }
    else {
        $PublicIP = "N/A"
        $PublicPort = "N/A"
    }

    $obj | Add-Member -MemberType NoteProperty -Name "ServerName" -Value "$($server.ServerName)"
    $obj | Add-Member -MemberType NoteProperty -Name "Online" -Value "$($Online)"
    $obj | Add-Member -MemberType NoteProperty -Name "Players" -Value "$($Query.Players.Online) / $($Query.Players.Max)"
    $obj | Add-Member -MemberType NoteProperty -Name "IP" -Value "$($server.IP):$($server.Port)"
    #$obj | Add-Member -MemberType NoteProperty -Name "Map" -Value "Not Implemented"
    $obj | Add-Member -MemberType NoteProperty -Name "Version" -Value "$($Query.Version)"
    $obj | Add-Member -MemberType NoteProperty -Name "Public" -Value "$($server.Public)"
    $obj | Add-Member -MemberType NoteProperty -Name "PublicPort" -Value "$($PublicPort)"
    $obj | Add-Member -MemberType NoteProperty -Name "PublicIP" -Value "$($PublicIP)"

    return $obj
}

Export-ModuleMember -Function Get-MinecraftServerStatus, Get-MCServerDetails

