@{
    RootModule        = 'Discord.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '47f9607a-33ec-410d-bd8f-91a27d30df27'
    Author            = 'Nikolaj Petersen'
    CompanyName       = 'eSport Brande'
    Description       = 'Module for sending messages to Discord channels using webhooks.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'Send-DiscordWebhookChat'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}