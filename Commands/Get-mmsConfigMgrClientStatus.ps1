function Get-mmsConfigMgrClientStatus {
    <#
    .SYNOPSIS
    Get the status of a configmgr client.
    
    .DESCRIPTION
    This tests is a device is manageable by the fast channel or not.
    
    .EXAMPLE
    Get-mmsConfigMgrClientStatus -ResourceID 123123
    
    .NOTES
    General notes
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Management.Infrastructure.CimMethodResult])]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ResourceID
    )
    begin {
        Initialize-mmsConfigMgrEnvironment
    }
    process {
        $CIMSession = New-CimSession -ComputerName $Script:ConfigMgrSMSProvider -ErrorAction Stop
        $CIMParams = @{
            "NameSpace" = "root\SMS\site_$($Script:ConfigMgrSiteCode)";
            "ClassName" = "SMS_CN_ClientStatus"
        }
        try {
            $CimQueryResults = Get-CimInstance -CimSession $CIMSession @CIMParams -Filter "ResourceID = '$($ResourceID)'" -ErrorAction Stop
        }
        catch {
            Write-Warning "Unable to connect to the SMS Provider."
        }
        if(($null -ne $CimQueryResults) -and ($CimQueryResults.Count -eq 1)) {
            switch ($CimQueryResults.OnlineStatus) {
                0 { $Status = "Offline" }
                1 { $Status = "Online" }
            }
        }
    }
    end {
        if($CIMSession) {
            Remove-CimSession -CimSession $CIMSession
        }
        $Status
    }
}