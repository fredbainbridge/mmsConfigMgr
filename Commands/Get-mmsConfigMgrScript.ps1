function Get-mmsConfigMgrScript {
    <#
    .SYNOPSIS
    Get a script from ConfigMgr.
    
    .DESCRIPTION
    Get back a Script object from the ConfigMgr Script node.
    
    .EXAMPLE
    Get-mmsConfigMgrScript -ScriptName "Shutdown Script"
    
    .NOTES
    Script name might not be unique.
    Inputs should be sanitized before use.
    #>

    [OutputType([System.Data.DataTable])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [String]$ScriptName
    )
    begin {
        Initialize-mmsConfigMgrEnvironment
    }
    process {
        $Query = "SELECT * FROM vSMS_Scripts WHERE ScriptName = '$ScriptName'"
        Invoke-mmsSqlCommand -Connection $Script:ConfigMgrDatabaseConnection -Query $Query -ReturnResults
    }
    end {

    }
}