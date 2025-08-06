function Send-DiscordMessage {
    param(
        [Parameter(Mandatory=$true)][string]$WebhookUrl,
        [Parameter(Mandatory=$true)][string]$Text,
        [Parameter(Mandatory=$false)][bool]$EnableDebug = $false
    )

    $LogTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    if ($EnableDebug -eq $true) {
        $Text = "$($LogTime): DBG: $Text"
    }
    else {
        $Text = "$($LogTime): $Text"
    }
    $body = @{ content = "$Text" } | ConvertTo-Json
    Invoke-RestMethod -Uri $WebhookUrl -Method Post -ContentType 'application/json' -Body $body
}

Export-ModuleMember -Function Send-DiscordMessage