function Import-mmsConfigMgrMicrosoftModule {
    <#
    .SYNOPSIS
    THis imports the Microsoft ConfigMgr module.
    
    .DESCRIPTION
    This looks for hthe module where the console is installed. 
    
    .EXAMPLE
    Import-mmsConfigMgrMicrosoftModule
    
    .EXAMPLE
    Import-mmsConfigMgrMicrosoftModule -ModulePath  'c:\pathtomodule\'

    .NOTES
    This is a private command for the module.

    #>
    [OutputType([bool])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string]$ModulePath
    )
    begin {
        Initialize-mmsConfigMgrEnvironment
    }
    process {
        if($Script:ConfigMgrCmdletsAvailable) {
            if($ModulePath) {
                Import-Module -Name $ModulePath
            }
            else {
                Import-Module -Name $Script:ConfigMgrCmdletsPath
            }
            if ((Get-PSDrive $Script:ConfigMgrSiteCode -ErrorAction SilentlyContinue | Measure-Object).Count -ne 1) {
                New-PSDrive -Name $Script:ConfigMgrSiteCode -PSProvider "AdminUI.PS.Provider\CMSite" -Root $Script:ConfigMgrSmsProvidor
            }
        }
        else {
            Write-Warning "ConfigMgr Cmdlets are not present. "
        }
    }
    end {
        $module = Get-Module -name "ConfigurationManager"
        if($module) {
            return $true
        }
        else {
            return $false
        }
    }
}