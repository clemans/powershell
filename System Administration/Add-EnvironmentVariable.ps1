<#PSScriptInfo

.VERSION 1.0

.GUID 920e20e2-bcbb-4011-a70c-fb257a64cd50

.AUTHOR clemans

.LICENSEURI 

.PROJECTURI 

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES

#>

<# 

.DESCRIPTION 
 A custom PowerShell cmdlet that takes the input of folder paths and appends them to the existing $ENV:PATH

#> 

Param(
        [Parameter(mandatory=$true)]
        [System.IO.FileInfo]
        [ValidateNotNullOrEmpty()]
        $Value
     )

if (-not ([System.IO.Directory]::Exists($Value)))
{
    throw "The directory does not exist: `"$_`"";
}

else
{
    function Get-UniqueVariables($arg)
    {
        $args = $arg -split ';' | Select -Unique
        return $args
    }

    $Key        = "HKLM:SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
    $OldValues  = Get-ItemProperty -Path $Key
    $JoinValues = Join-Path -Path $OldValues.Path -ChildPath ";$Value"
    $NewValues  = Get-UniqueVariables($NewValues)

    $splattributes = @{
                        Path   = $Key
                        Name   = 'Path'
                        Value  = $NewValues
                      }

    Set-ItemProperty @splattributes -Verbose -Confirm:$TRUE -WhatIf
}
