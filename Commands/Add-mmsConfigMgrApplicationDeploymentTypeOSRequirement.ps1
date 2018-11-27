function Add-mmsConfigMgrApplicationDeploymentTypeOSRequirement {
    <#
    .SYNOPSIS
    Add an OS requirement to all deployment types for an application.
    .DESCRIPTION
    This is especially useful if you have a lot of applications you want to certify for Windows 10 (for example)
    It will create a new Operating System requirement if one does not exist.
    This will attempt to add the OS requirement to each deployment type it finds.

    .EXAMPLE
    Add-mmsConfigMgrApplicationDeploymentTypeOSRequirement -ApplicationName '7zip' -Requirement 'All Windows 10 (64-bit)'

    .PARAMETER ApplicationName
    This is the name of the configmgr application that has the deployment types that you want to add the OS requirement to. This accepts input from pipeline.
    
    .NOTES
    Add allowed operating systems to the config.json in the root of the module.
    
    This will hopefully be deprecated soon enough.
    https://configurationmanager.uservoice.com/forums/300492-ideas/suggestions/8396517-add-a-powershell-possibility-to-add-requirements-t

    #>

    [CmdletBinding()]
    param (
        [Parameter(
            Position=0,
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)       
        ]
        [string]$ApplicationName
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

        $dynParam1 = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("Requirement", [string], $attributeCollection)
        $paramDictionary = New-Object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
        $paramDictionary.Add("Requirement", $dynParam1)
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
        $operandRequirement = ($ConfigMgrConfig.DeploymentTypeOperatingSystems | Where-Object {
            $PSItem.name -eq $namedRequirement
        }).operand

        $application = Get-CMApplication -Name $ApplicationName
        if($null -eq $application) {
            Write-Warning -Message "Application not found."
            return
        }
        $applicationXml = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::DeserializeFromString($application.SDMPackageXML,$True)

        #$numberOfDeploymentTypes = $applicationXml.DeploymentTypes.count
        $DeploymentTypesXml = $applicationXml.DeploymentTypes

        foreach ($deploymentType in $DeploymentTypesXml)
        {
            $foundOSRequirement = $false;
            foreach($requirement in $deploymentType.Requirements)
            {
                if($requirement.Expression.gettype().name -eq 'OperatingSystemExpression') 
                {
                    $foundOSRequirement = $true
                    $Filter = "CI_UniqueId = '$operandRequirement'"
                    $localizedOSName = (Get-CimInstance -ClassName 'SMS_ConfigurationItem' -Filter $Filter -Namespace "root\sms\Site_$($Script:ConfigMgrSiteCode)").LocalizedDisplayName

                    if($requirement.Name -Notlike "*$localizedOSName*" )
                    {
                        write-verbose "Found an OS Requirement, appending value to it"
                        $requirement.Expression.Operands.Add("$operandRequirement")
                        $requirement.Name = [regex]::replace($requirement.Name, '(?<=Operating system One of {)(.*)(?=})', "`$1, $namedRequirement")
                        $null = $deploymentType.Requirements.Remove($requirement)
                        $requirement.RuleId = "Rule_$([guid]::NewGuid())"
                        $null = $deploymentType.Requirements.Add($requirement)
                        Break
                    }
                    else {
                        Write-Warning -Message "OS Requirement already exists."
                    }
                }
            }
            if(-not $foundOSRequirement) {
                $rule = New-mmsConfigMgrDeploymentTypeOSRequirementRule -OperatingSystem $namedRequirement
                $deploymentType.Requirements.Add($rule)
            }
        }
        $UpdatedXML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::SerializeToString($applicationXml, $True) 
        $application.SDMPackageXML = $UpdatedXML 
        $application.put()  #this uses both WMI and the CM CmdLets.  Fun.
        $null = Set-CMApplication -InputObject $application -PassThru
    }
    end {
        Set-Location -Path $location
    }
}


