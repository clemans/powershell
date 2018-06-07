
<#PSScriptInfo

.VERSION 1.0.0.0

.GUID b7165f76-054e-43b5-8dd3-3498bcfb6602

.AUTHOR ([string](0..23|%{[char][int](23+('808293819475237685788674879241808674828523768886').substring(($_*2),2))})).Replace(' ','')

.COMPANYNAME 

.COPYRIGHT 

.TAGS ActiveDirectory

.LICENSEURI https://github.com/clemans/powershell/blob/master/LICENSE

.PROJECTURI https://git.io/vhunJ

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES
1.0.0.0: Initial Commit

#>

#Requires -Module ActiveDirectory

<# 

.DESCRIPTION 
 Due to name overlap in the org., a custom function overrides certain outliers.
Attempts to return an Active Directory user object using string input such as a DisplayName string. 

#> 

[cmdletBinding()]
param (	
[Parameter( Position=0,
	Mandatory=$false,
	ValueFromPipelineByPropertyName=$true,
	ValueFromRemainingArguments=$false )]
[System.String]
$ManagerName
)

PROCESS
{	switch ($ManagerName)
	{
		'{Outlier Name #1}' 
		{
		   $MgrSamAccountName = "jdoe" 
		   Break
		}
		'{Outlier Name #2}' 
		{
           $MgrSamAccountName = "jpdoe"
		   Break
		}
		default
		{
		   $MgrSamAccountName = (& $PSScriptRoot\Find-ADUser.ps1 -SearchBy EmployeeName -SearchString $($ManagerName)).sAMAccountName
		}
	}

}

END
{
	Return $MgrSamAccountName
}