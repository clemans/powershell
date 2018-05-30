<# 
.REQUIREMENTS
  Microsoft.Exchange
#>

<#
.DESCRIPTION
  A custom PowerShell cmdlet that takes the input of the configuration name, uri, and credentials and 
  establishes a Microsoft Exchange command-line connector.
#>

<#
.PARAMETER 
 -ConfigurationName <String>
    Specifies the session configuration that is used for the new PSSession .

 -ConnectionUri <Uri>
    Specifies a URI that defines the connection endpoint for the session. The URI must be fully qualified.

 -Authentication <AuthenticationMechanism>
    Specifies the mechanism that is used to authenticate the user's credentials.

 -Credential <PSCredential>
    Specifies a user account that has permission to perform this action.
    
 -Name <String>
    Specifies a friendly name for the PSSession
#>

<#
.NOTES
  Version:        1.0   
  Author:         clemans
  Creation Date:  09/19/2017
  Purpose/Change: Used for automation tasks involving exchange messaging
#>

<#
.EXAMPLES
    ConnectTo-Exchange -ConfigurationName 'Microsoft.Exchange' -ConnectionUri 'http://exchange.contoso.local/PowerShell/'
#>

ConnectTo-Exchange
{
    [CmdletBinding()] 
    Param
    (
        [Parameter(Mandatory=$False)]
            [System.String]$ConfigurationName,
        [Parameter(Mandatory=$False)]
            [System.Uri]$ConnectionUri,
        [Parameter(Mandatory=$False)]
            $Authentication = [System.Management.Automation.Runspaces.AuthenticationMechanism]::Kerberos,
        [Parameter(Mandatory=$False)]
            [pscredential]$Credential = (Get-Credential),
        [Parameter(Mandatory=$False)]
            [System.String]$Name = "<Exchange Session>|<$($env:USERNAME)>|<$((Get-Date).ToShortDateString()) $((Get-Date).ToShortTimeString())>"
    )

    $argTable = @{
                ConfigurationName = $ConfigurationName
                ConnectionUri =     $ConnectionUri.AbsoluteUri
                Authentication =    $Authentication
                Credential =        $Credential
                Name =              $Name
             }

    $Session = New-PSsession @argTable

    Import-Module (Import-PSSession $Session) -Global
}