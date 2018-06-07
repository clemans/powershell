
<#PSScriptInfo

.VERSION 1.0.0.0

.GUID 01240521-6758-402c-b240-d162fae05920

.AUTHOR ([string](0..23|%{[char][int](23+('808293819475237685788674879241808674828523768886').substring(($_*2),2))})).Replace(' ','')

.COMPANYNAME 

.COPYRIGHT 

.TAGS ActiveDirectory SQLPS

.LICENSEURI https://github.com/clemans/powershell/blob/master/LICENSE

.PROJECTURI https://git.io/vhE8G

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES
1.0.0.0: Initial Commit
    * Many thanks to: https://github.com/RamblingCookieMonster/PowerShell for New-SQlConnection.ps1
    * Many thanks to: https://gist.github.com/codebrane/2965778 for bb91users.p1

#>

#Requires -Module ActiveDirectory
#Requires -Module SQLPS

<# 

.DESCRIPTION 
 Creates a new SQL connection, queries a MSSQL database, and outputs the table. 

#> 

[cmdletbinding()]
[OutputType([System.Data.SqlClient.SQLConnection])]
param(
    [Parameter( Position=0,
                Mandatory=$false,
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true,
                ValueFromRemainingArguments=$false,
                HelpMessage='SQL Server Instance required...' )]
    [Alias( 'Instance', 'Instances', 'ComputerName', 'Server', 'Servers' )]
    [ValidateNotNullOrEmpty()]
    [string[]]
    $ServerInstance,

    [Parameter( Position=1,
                Mandatory=$false,
                ValueFromPipelineByPropertyName=$true,
                ValueFromRemainingArguments=$false)]
    [string]
    $Database,

    [Parameter( Position=2,
                Mandatory=$false,
                ValueFromPipelineByPropertyName=$true,
                ValueFromRemainingArguments=$false )]
    [System.String]
    $Table,

    [Parameter( Position=3,
                Mandatory=$false,
                ValueFromPipelineByPropertyName=$true,
                ValueFromRemainingArguments=$false )]
    [System.Management.Automation.PSCredential]
    $Credential = (Get-Credential),

    [Parameter( Position=4,
                Mandatory=$false,
                ValueFromRemainingArguments=$false)]
    [switch]
    $Encrypt,

    [Parameter( Position=5,
                Mandatory=$false,
                ValueFromPipelineByPropertyName=$true,
                ValueFromRemainingArguments=$false )]
    [Int32]
    $ConnectionTimeout=15,

    [Parameter( Position=6,
                Mandatory=$false,
                ValueFromPipelineByPropertyName=$true,
                ValueFromRemainingArguments=$false )]
    [bool]
    $Open = $True,

    [Parameter( Position=7,
                Mandatory=$false,
                ValueFromPipelineByPropertyName=$true,
                ValueFromRemainingArguments=$false )]
    [System.String]
    $Query
    )

PROCESS
{
    foreach($SQLInstance in $ServerInstance)
    {
        Write-Verbose "Querying ServerInstance '$SQLInstance'"

        if ($Credential)
        {
            $ConnectionString = "Server={0};Database={1};User ID={2};Password={3};Trusted_Connection=False;Connect Timeout={4};Encrypt={5}" `
                                -f $SQLInstance,$Database,$Credential.UserName,$Credential.GetNetworkCredential().Password,$ConnectionTimeout,$Encrypt
        }
        else
        {
            $ConnectionString = "Server={0};Database={1};Integrated Security=True;Connect Timeout={2};Encrypt={3}" `
                                -f $SQLInstance,$Database,$ConnectionTimeout,$Encrypt
        }

        $SqlConnection = New-Object System.Data.SqlClient.SQLConnection
        $SqlConnection.ConnectionString = $ConnectionString

        #Following EventHandler is used for PRINT and RAISERROR T-SQL statements. Executed when -Verbose parameter specified by caller
        if ($PSBoundParameters.Verbose)
        {
            $SqlConnection.FireInfoMessageEventOnUserErrors=$true
            $handler = [System.Data.SqlClient.SqlInfoMessageEventHandler] { Write-Verbose "$($_)" }
            $SqlConnection.add_InfoMessage($handler)
        }

        if($Open)
        {
            Try
            {
                $SqlConnection.Open()
                $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
                $SqlCmd.CommandText = $Query
                $SqlCmd.Connection = $SqlConnection
                $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
                $SqlAdapter.SelectCommand = $SqlCmd
                $DataSet = New-Object System.Data.DataSet
                $SqlAdapter.Fill($DataSet) | Out-Null
                $SqlConnection.Close()
            }
            Catch
            {
                Write-Error $_
                continue
            }          
        }
        
        Return $DataSet.Tables[0].Rows;
    }
}