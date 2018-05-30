<#PSScriptInfo

.VERSION 1.0

.GUID 9967e0b3-408c-4ce1-8b86-0948b79f835e

.AUTHOR clemans

.COMPANYNAME 

.COPYRIGHT 

.TAGS 

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
 A custom PowerShell cmdlet that attempts to take ownership of the specified path file or folder with the provided set of credentials. 
 By default, the local system administrators group takes ownership and is provided full permissions to the specified filesystems object. 

#> 

#Requires -RunAsAdministrator

Param
(
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [System.IO.DirectoryInfo]
    $Path,
    [Parameter(Mandatory = $false)]
    [ValidateScript( {(Get-WmiObject Win32_UserAccount -Filter "Name='$_'") -or
                      (Get-WmiObject Win32_Group -Filter "Name='$_'")})]
    [System.Security.Principal.NTAccount]$Account = 
    ([System.Security.Principal.SecurityIdentifier]("S-1-5-32-544")).Translate([System.Security.Principal.NTAccount])
)

Function Confirm-Selection($Path) {
    $message  = "Setting full permissions..."
    $question = "Are you sure you replace ownership on `"$($Path)`"?"

        $choices = New-Object Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]
    
        $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&Yes'))
    
        $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&No'))
    
        $decision = $Host.UI.PromptForChoice($message, $question, $choices, 1)
    
    return $decision   
}
            
try {
    if (([System.IO.Directory]::Exists($Path) -eq $True) -or 
        ([System.IO.File]::Exists($Path) -eq $True)) {               #does the specified file or directory exist? 
    
            $confirm = Confirm-Selection($Path.FullName)             #confirm execution: Yes (0) or No (1)
    
            Switch ($confirm) {
                0 {
                    $user = $Account.Value -replace "\w+\\",""       #remove domain (e.g. "BUILTIN\")
                    $object = $($Path.FullName)
                    $iAccess = "/grant"                              #access-control
                    $iRule = ":(OI)(CI)(F)"                          #inheritance, permission set

                    & takeown.exe /F $object /A /R /D Y              #local administrator takes full ownership
                    & icacls.exe $object $iAccess "${user}${iRule}"  #specified account granted variable ACLs
                }

                default { trap {} }                                  #null output if negative confirmation
    }
}

else { 
    if ([bool]$Path.Extension) 
    { 
        [System.IO.FileNotFoundException]::new()                     #file not found
    } else { 
        [System.IO.DirectoryNotFoundException]::new()                #directory not found
    }
} 
}

catch {
         [System.IO.IOException]::new()                              #generic not found
}