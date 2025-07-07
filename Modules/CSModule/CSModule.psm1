
function Get-CSServerDetails {
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Server,
        [string]$PublicIPPrefix,
        [string]$CSGamePassword
    )
    
    $obj = New-Object psobject
    
    Write-Host "Testing connection to $($server.IP):$($server.Port)"
    $Connect = Test-Connection -IPv4 $($server.IP) -TcpPort $($server.Port)
    Write-Host "Connection result: $($Connect) for $($server.IP):$($server.Port)"
    
    if ($connect) {
        Write-Host "Running query for $($server.IP):$($server.Port)"
        $Query = SourceQuery -Address $($server.IP) -Engine 'Source' -Port "$($server.Port)" -Type 'info'
        $Name = $($Query.Name).Replace("'", "").Replace("eSB - ","")
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

    # Determine server type and config
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
        $Password = "$($CSGamePassword)"
    }
    else {
        $GuideUrl = $null
        $ServerType = "NOTSET"
        $PasswordProtected = $false
        $Password = ""
    }

    # Set up IP and connection strings
    if ($server.Public -eq $true) {
        $PublicIP = "$($PublicIPPrefix):$($server.PublicPort)"
    }
    else {
        $PublicIP = "N/A"
    }
    
    if ($PasswordProtected -eq $true -and $server.Public -eq $true) {
        $LocalConnect = "connect $($server.IP):$($server.Port);password $($Password)"
        $PublicConnect = "connect $($PublicIP);password $($Password)"
    }
    elseif ($PasswordProtected -eq $false -and $server.Public -eq $true) {
        $LocalConnect = "connect $($server.IP):$($server.Port)"
        $PublicConnect = "connect $($PublicIP)"
    }
    else {
        $PublicConnect = "N/A"
        $LocalConnect = "connect $($server.IP):$($server.Port)"
    }

    # Build the server object
    $obj | Add-Member -MemberType NoteProperty -Name "OriginalServerName" -Value "$($server.ServerName)"
    $obj | Add-Member -MemberType NoteProperty -Name "ServerName" -Value "$($Name)"
    $obj | Add-Member -MemberType NoteProperty -Name "ServerID" -Value "$($server.ServerID)"
    $obj | Add-Member -MemberType NoteProperty -Name "Map" -Value "$($Query.Map)"
    $obj | Add-Member -MemberType NoteProperty -Name "Online" -Value $Online
    $obj | Add-Member -MemberType NoteProperty -Name "Players" -Value "$($Query.Players) / $($Query.Max_players)"
    $obj | Add-Member -MemberType NoteProperty -Name "Version" -Value "$($Query.Version)"
    $obj | Add-Member -MemberType NoteProperty -Name "IP" -Value "$($server.IP):$($server.Port)"
    $obj | Add-Member -MemberType NoteProperty -Name "Guide" -Value "$($GuideUrl)"
    $obj | Add-Member -MemberType NoteProperty -Name "ServerType" -Value "$($ServerType)"
    $obj | Add-Member -MemberType NoteProperty -Name "Public" -Value $($server.Public)
    $obj | Add-Member -MemberType NoteProperty -Name "LocalConnect" -Value "$($LocalConnect)"
    $obj | Add-Member -MemberType NoteProperty -Name "PublicConnect" -Value "$($PublicConnect)"
    $obj | Add-Member -MemberType NoteProperty -Name "PasswordProtected" -Value $($PasswordProtected)
    $obj | Add-Member -MemberType NoteProperty -Name "Password" -Value "$($Password)"
    
    return $obj
}

function Get-CSTVServerDetails {
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Server,
        [string]$PublicIPPrefix,
        [string]$CSGamePassword
    )
    
    $obj = New-Object psobject
    
    if ($server.CSTV -eq $true) {
        Write-Host "Testing connection to $($server.IP):$($server.CSTVPort)"
        $Connect = Test-Connection -IPv4 $($server.IP) -TcpPort $($server.CSTVPort)
        Write-Host "Connection result: $($Connect) for $($server.IP):$($server.CSTVPort)"
    
        if ($connect) {
            Write-Host "Running query for $($server.IP):$($server.CSTVPort)"
            $Query = SourceQuery -Address $($server.IP) -Engine 'Source' -Port "$($server.CSTVPort)" -Type 'info'
            $Name = $($Query.Name).Replace("'", "").Replace("eSB - ","")
            if ($Query) {
                $Online = "Online"
            }
            else {
                Write-Host "Query failed for $($server.IP):$($server.CSTVPort)"
                $Online = "Offline"
            }
        }
        else {
            $Online = "Offline"
            $Name = $server.ServerName
        }

        # Determine server type and config
        if ($Server.ServerName -match "CS2-WAR") {
            $PasswordProtected = $true
            $Password = "$($CSGamePassword)"
        }
        else {
            $PasswordProtected = $false
            $Password = ""
        }
        
        if ($PasswordProtected -eq $true ) {
            $LocalConnect = "connect $($server.IP):$($server.CSTVPort);password $($Password)"
        }
        elseif ($PasswordProtected -eq $false -and $server.Public -eq $true) {
            $LocalConnect = "connect $($server.IP):$($server.CSTVPort)"
        }

        # Build the server object
        $obj | Add-Member -MemberType NoteProperty -Name "ServerName" -Value "$($Name)"
        $obj | Add-Member -MemberType NoteProperty -Name "Online" -Value $Online
        $obj | Add-Member -MemberType NoteProperty -Name "IP" -Value "$($server.IP):$($server.CSTVPort)"
        $obj | Add-Member -MemberType NoteProperty -Name "LocalConnect" -Value "$($LocalConnect)"
        $obj | Add-Member -MemberType NoteProperty -Name "PasswordProtected" -Value $($PasswordProtected)
        $obj | Add-Member -MemberType NoteProperty -Name "Password" -Value "$($Password)"
        
        return $obj
    }
}

Export-ModuleMember -Function Get-CSServerDetails, Get-CSTVServerDetails