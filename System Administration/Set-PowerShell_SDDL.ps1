<#

SDDL: O:NSG:BAD:P(A;;GA;;;S-1-5-21-279383254-338302740-732247886-19506)S:P(AU;FA;GA;;;WD)(AU;SA;GXGW;;;WD)

ConvertFrom-SDDLString 'O:NSG:BAD:P(A;;GA;;;S-1-5-21-279383254-338302740-732247886-19506)S:P(AU;FA;GA;;;WD)(AU;SA;GXGW;;;WD)'

Owner            : NT AUTHORITY\NETWORK SERVICE
Group            : BUILTIN\Administrators
DiscretionaryAcl : {: AccessAllowed (GenericAll)}
SystemAcl        : {Everyone: SystemAudit FailedAccess (GenericAll), Everyone: SystemAudit SuccessfulAccess (GenericExecute, GenericWrite)}
RawDescriptor    : System.Security.AccessControl.CommonSecurityDescriptor

#>

[System.String]$sddl = "O:NSG:BAD:P(A;;GA;;;S-1-5-21-279383254-338302740-732247886-19506)S:P(AU;FA;GA;;;WD)(AU;SA;GXGW;;;WD)"

Set-PSSessionConfiguration -Name Microsoft.PowerShell -SecurityDescriptorSDDL $sddl -Force