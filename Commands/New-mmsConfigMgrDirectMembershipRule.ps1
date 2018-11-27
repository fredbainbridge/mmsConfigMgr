function New-mmsConfigMgrDirectMembershipRule {
    <#
    .SYNOPSIS
    Create a direct membership rule.
    
    .DESCRIPTION
    Using a collectionID and resource ID.
    
    .EXAMPLE
    New-mmsConfigMgrDirectMembershipRule -ResourceID 12312344 -Collection abc12312
    
    .NOTES
    This does a collection evaluation.
    #>
    [OutputType([System.Nullable])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [UINT32]$ResourceID,

        [Parameter(Mandatory = $true)]
        [string]$CollectionID
    )
    begin {
        Initialize-mmsConfigMgrEnvironment
    }
    process {
        $Query = "Select Name0 from v_r_system where ResourceID = $ResourceID"
        $results = Invoke-mmsSqlCommand -Connection $Script:ConfigMgrDatabaseConnection -Query $Query -ReturnResults
        if($null -eq $results) {
            write-warning "ResourceID not found in ConfigMgr."
            return
        }

        $CIMSession = New-CimSession -ComputerName $Script:ConfigMgrSMSProvider -ErrorAction Stop
        $CIMParams = @{
            "NameSpace" = "root\SMS\site_CHQ";
            "ClassName" = "SMS_Collection"
        }
        try {
            [CimInstance]$CollectionCimQueryResults = Get-CimInstance -CimSession $CIMSession @CIMParams -Filter "CollectionID = 'CHQ00014' and CollectionType='2'"
        }
        catch {
            Write-Warning "Unable to connect to the SMS Provider."
            return
        }
        
        $NewRule = New-CimInstance -Namespace "root\SMS\site_$($Script:ConfigMgrSiteCode)" -ClassName SMS_CollectionRuleDirect -Property @{
            RuleName = "$ResourceID Direct Rule";
            ResourceClassName = "SMS_R_System";
            ResourceID = [UINT32]$ResourceID;
        } -ClientOnly
        $CimResults = Invoke-CimMethod -InputObject $CollectionCimQueryResults -CimSession $CIMSession -MethodName AddMembershipRule -Arguments @{collectionRule = [CimInstance]$NewRule}
    }
    end {
        if($CIMSession) {
            Remove-CimSession -CimSession $CIMSession
        }
        $CimResults.OperationID
    }
}