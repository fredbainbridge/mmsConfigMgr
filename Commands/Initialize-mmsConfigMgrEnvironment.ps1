function Initialize-mmsConfigMgrEnvironment {
    <#
    .SYNOPSIS
    Set script level variables for working with specific ConfigMgr environments.
    
    .DESCRIPTION
    Database, databasename, servername, database connection object.
    
    .EXAMPLE
    An example
    
    .NOTES
    General notes
    #>

    [OutputType([System.Nullable])]
    [CmdletBinding()]
    param(
        
    )
    if( -not (  
            $Script:ConfigMgrDatabaseServer -and
            $Script:ConfigMgrDatabaseName -and
            $Script:ConfigMgrDatabaseConnection -and
            $Script:ConfigMgrSiteCode -and
            $Script:ConfigMgrSMSProvider
        )
    )
    {
        $config = Get-Content -Path "$PSScriptRoot\..\config.json" -Raw
        $ConfigMgrConfig = ConvertFrom-Json -InputObject $config 
        $Script:ConfigMgrDatabaseServer = $ConfigMgrConfig.DatabaseServer
        $Script:ConfigMgrDatabaseName = $ConfigMgrConfig.DatabaseName
        $Script:ConfigMgrDatabaseConnection = New-mmsSqlConnection -ServerName $ConfigMgrConfig.DatabaseServer -DatabaseName $ConfigMgrConfig.DatabaseName
        $Script:ConfigMgrSiteCode = $ConfigMgrConfig.SiteCode
        $Script:ConfigMgrSMSProvider = $ConfigMgrConfig.SMSProvider
        $Script:ConfigMgrCmdletsPath = "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"
        
        if(Test-Path -Path "$Script:ConfigMgrCmdletsPath") {
            $Script:ConfigMgrCmdletsAvailable = $true
        }
        else {
            $Script:ConfigMgrCmdletsAvailable = $false
            $Script:ConfigMgrCmdletsPath = $null
        }
    }
}