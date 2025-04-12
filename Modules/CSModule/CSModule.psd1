@{
    RootModule        = 'CSModule.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '47f9607a-33ec-410d-bd8f-91a27d30df27'
    Author            = 'Nikolaj Petersen'
    CompanyName       = 'eSport Brande'
    Description       = 'Module for eSport Brande to fetch Counter-Strike server details, including player count and version. Requires SourceQuery from PowerShell NuGet.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'Get-CSServerDetails'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}