@{
    RootModule        = 'MCModule.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'b003670f-40bc-444e-b541-ffcaaa69edfb'
    Author            = 'Nikolaj Petersen'
    CompanyName       = 'eSport Brande'
    Description       = 'Module for eSport Brande to fetch Minecraft server details, including player count and version.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'Get-MCServerDetails'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}