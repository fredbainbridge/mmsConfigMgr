function Invoke-mmsConfigMgrScript {
    <#
    .SYNOPSIS
    Starts a ConfigMgr script. 
    
    .DESCRIPTION
    This starts an existing COnfigMgr script against a manageable resourceID. 
    
    .EXAMPLE
    Invoke-mmsConfigMgrScript -ScriptName $ScriptName -ResourceID 123123 -LimitingCollectionID 'SMS00001'
    
    .NOTES
    This will only work on a manageable device.
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ScriptName,

        [Parameter(Mandatory=$true)]
        [string]$LimitingCollectionID,

        [Parameter(Mandatory=$true)]
        [int]$ResourceID
    )
    begin {
        Initialize-mmsConfigMgrEnvironment
    }
    process {
        $CIMSession = New-CimSession -ComputerName $Script:ConfigMgrSMSProvider -ErrorAction Stop
        $CIMParams = @{
            "NameSpace" = "root\SMS\site_$($Script:ConfigMgrSiteCode)";
            "ClassName" = "SMS_Scripts"
        }
        try {
            $CimQueryResults = Get-CimInstance -CimSession $CIMSession @CIMParams -Filter "ScriptName = '$($ScriptName)' and ApprovalState = '3'" -ErrorAction Stop
        }
        catch {
            Write-Warning "Unable to connect to the SMS Provider."
            return
        }
        if(($null -ne $CimQueryResults) -and (@($CimQueryResults).Count -eq 1)){
            $ParamXML = "<ScriptContent ScriptGuid='{0}'>
                            <ScriptVersion>{1}</ScriptVersion>
                            <ScriptType>{2}</ScriptType>
                            <ScriptHash ScriptHashAlg='SHA256'>{3}</ScriptHash>
                            <ScriptParameters></ScriptParameters>
                            <ParameterGroupHash ParameterHashAlg='SHA256'>{4}</ParameterGroupHash>
                        </ScriptContent>" -f (
                $CimQueryResults.ScriptGuid,
                $CimQueryResults.ScriptVersion,
                $CimQueryResults.ScriptType,
                $CimQueryResults.ScriptHash,
                $CimQueryResults.ParameterGroupHash
            )
            $ParamXML = $ParamXML.trim()
            $ParamXML = $ParamXML.Replace("`r`n","")
            $ParamXML = $ParamXML.Replace("  ","")
            $Param = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($ParamXML))
            $ScriptArgs = @{}
            $ScriptArgs.Add('Param', $Param)
            $ScriptArgs.Add('Type', [uint32]135) #Client Operation ID
            $ScriptArgs.Add('TargetCollectionID', $LimitingCollectionID)
            [uint32[]]$ResourceIDs = [uint32]$ResourceID;
            $ScriptArgs.Add('TargetResourceIDs', $ResourceIDs)
            
            $CimSplat = @{
                'CimSession' = $CIMSession;
                'Namespace' = "root\SMS\site_$($Script:ConfigMgrSiteCode)";
                'ClassName' = 'SMS_ClientOperation';
                'MethodName' = 'InitiateClientOperationEx';
                'Arguments' = $ScriptArgs;
            }
            try {
                $CimResults = Invoke-CimMethod @CimSplat
            }
            catch {
                Write-Warning -Message "Unable to run script $ScriptName on $ResourceID."
            }
        }
        else {
            Write-Warning -Message "Unable to find $ScriptName"
        }
    }
    end {
        if($CIMSession) {
            Remove-CimSession -CimSession $CIMSession
        }
        $CimResults.OperationID
    }
}