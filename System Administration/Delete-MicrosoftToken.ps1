
<#PSScriptInfo

.VERSION 1.0.0.0

.GUID 860ae803-f3d4-4132-8d83-549f2f597034

.AUTHOR ([string](0..23|%{[char][int](23+('808293819475237685788674879241808674828523768886').SubString(($_*2),2))})).Replace(' ','')

.COMPANYNAME 

.COPYRIGHT 

.TAGS 

.LICENSEURI 

.PROJECTURI https://git.io/fhIqH

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES


#>

<# 

.DESCRIPTION 
 A basic function that by default iterates through the local host's user profiles and archives the Microsoft Office 365 user license tokens. 
 A user logoff/logon may be required in order for a new token to generate. For more information on shared computer activation for Office 365 ProPlus, go here: 
 https://docs.microsoft.com/en-us/deployoffice/overview-of-shared-computer-activation-for-office-365-proplus 

#> 

Param()

function Delete-MicrosoftToken()
{

param([Parameter( Position=1,Mandatory=$false )][array]$UsernameProfiles = $(foreach ($uprof in (Get-childitem -path C:\Users | Where-Object {$_.Mode -eq 'd-----'})) { $uprof.Name}))

    foreach ($userprofile in $UsernameProfiles)
    {

        $FilePath    = [System.String]::concat('C:\Users\',$userprofile,'\AppData\Local\Microsoft\Office\16.0\Licensing\')
        $Destination = [System.String]::concat($FilePath,'.archive')
 

        if ( Test-Path $FilePath ) 
        {
                if (-not (Test-Path $Destination))
                {
                   New-Item $Destination -ItemType Directory -Force
                }

                try { 
                        [array]$tokens = Get-ChildItem $FilePath -Exclude $Destination.Split('\')[-1]

                        if ($tokens -ne $null)
                        {                        
                           Move-Item -path $tokens.FullName -Destination $Destination -Force
   
                        } else { Continue }

                } catch { "catch 1" } 
        } 

        else { continue }
    } 
}
