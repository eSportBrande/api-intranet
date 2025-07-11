function Send-DiscordMessage {
    param(
        [Parameter(Mandatory=$true)][string]$WebhookUrl,
        [Parameter(Mandatory=$true)][string]$Text
    )
    $body = @{ content = "$Text" } | ConvertTo-Json
    Invoke-RestMethod -Uri $WebhookUrl -Method Post -ContentType 'application/json' -Body $body
}

Export-ModuleMember -Function Send-DiscordMessage