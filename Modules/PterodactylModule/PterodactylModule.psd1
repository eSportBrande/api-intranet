@{
    RootModule        = 'PterodactylModule.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '3bc77b40-23d9-4184-91bd-800f82ab6500'
    Author            = 'Nikolaj Petersen'
    CompanyName       = 'eSport Brande'
    Description       = 'Module for eSport Brande to fetch servers from Pterodactyl API to use in other functions to fetch specific server details.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'Get-PterodactylServers'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}