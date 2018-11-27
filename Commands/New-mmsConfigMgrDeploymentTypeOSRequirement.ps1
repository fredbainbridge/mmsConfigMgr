function New-mmsConfigMgrDeploymentTypeOSRequirementRule {
    <#
    .SYNOPSIS
    Create a Operating System "OneOf" global condition rule.

    .DESCRIPTION
    This only creates operating system rules for deployment types.

    .EXAMPLE
    New-mmsConfigMgrDeploymentTypeOSRequirementRule -OperatingSystem "All Windows 10 (64-bit)"

    .NOTES
    This could be generalized easy enough to be "New-mmsConfigMgrGlobalConditionRule"
    Most of this code originated from https://hiway65nblog.blogspot.com/2016/02/updating-sccm-application-os.html
    I mainly just made it use CIM instead of WMI.
    
    #>
    [OutputType("Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.Rule")]
    [CmdletBinding()]
    param(

    )
    dynamicparam {
        $attributes = New-Object System.Management.Automation.ParameterAttribute
        $attributes.ParameterSetName = "__AllParameterSets"
        $attributes.Mandatory = $true
        $attributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
        $attributeCollection.Add($attributes)
        $config = Get-Content -Path "$PSScriptRoot\..\config.json" -Raw
        $ConfigMgrConfig = ConvertFrom-Json -InputObject $config
        $values =   $ConfigMgrConfig.DeploymentTypeOperatingSystems.Name
        $ValidateSet = New-Object System.Management.Automation.ValidateSetAttribute($values)
        $attributeCollection.Add($ValidateSet)

        $dynParam1 = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("OperatingSystem", [string], $attributeCollection)
        $paramDictionary = New-Object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
        $paramDictionary.Add("OperatingSystem", $dynParam1)
        return $paramDictionary 
    }
    begin {
        if(-not (Import-mmsConfigMgrMicrosoftModule)) {
            Write-Warning 'This function requires the Microsoft ConfigMgr cmdlets.'
            return
        }
        $location = Get-Location #To be used at the end to reset your location.
        Set-Location -Path "$($Script:ConfigMgrSiteCode)`:"
    }
    process {
        $namedRequirement = $dynParam1.Value
        $value = ($ConfigMgrConfig.DeploymentTypeOperatingSystems | Where-Object {
            $PSItem.name -eq $namedRequirement
        }).operand

        $Operator = 'OneOf' 
        $Scope = "GLOBAL"
        $LogicalName = "Device_OperatingSystem"
        $ExpressionDataType = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.DataType]::GetDataTypeFromTypeName("OperatingSystem")
        
        $arg = @(
            $Scope,
            $LogicalName,
            $ExpressionDataType,
            "$($LogicalName)_Setting_LogicalName",
            ([Microsoft.ConfigurationManagement.DesiredConfigurationManagement.ConfigurationItemSettingSourceType]::CIM)
        )
        $reqSetting = New-Object "Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.GlobalSettingReference" -ArgumentList $arg
          
        $arg = @(
            $value,
            $ExpressionDataType
        )
        $reqValue = New-Object "Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.ConstantValue" -ArgumentList $arg  
          
        $operands = New-Object "Microsoft.ConfigurationManagement.DesiredConfigurationManagement.CustomCollection``1[[Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.ExpressionBase]]"
        $null = $operands.Add($reqSetting)
        $null = $operands.Add($reqValue)
          
        $Expoperator = Invoke-Expression [Microsoft.ConfigurationManagement.DesiredConfigurationManagement.ExpressionOperators.ExpressionOperator]::$operator

        $operands = New-Object "Microsoft.ConfigurationManagement.DesiredConfigurationManagement.CustomCollection``1[[Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.RuleExpression]]"
        $operands.Add($value)
    
        $arg = @(
            $Expoperator,
            $operands
        )
        $expression = New-Object "Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.OperatingSystemExpression" -ArgumentList $arg
        
          
        $anno = New-Object "Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.Annotation"
        $Filter = "CI_UniqueId = '$value'"
        $localizedOSNames = (Get-CimInstance -ClassName 'SMS_ConfigurationItem' -Filter $Filter -Namespace "root\sms\Site_$($Script:ConfigMgrSiteCode)").LocalizedDisplayName

        $localizedDisplayName = "{" + $localizedOSNames + "}"
        $annodisplay = "Operating system One of $localizedDisplayName"

        $arg = @(
            "DisplayName",
            $annodisplay,
            $null
        )
        $anno.DisplayName = New-Object "Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.LocalizableString" -ArgumentList $arg
          
        $arg = @(
            ("Rule_" + [Guid]::NewGuid().ToString()),
            [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.NoncomplianceSeverity]::None,
            $anno,
            $expression
        )
        $rule = New-Object "Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.Rule" -ArgumentList $arg
        return $rule
    }
    end {
        Set-Location -Path $location
    }
}