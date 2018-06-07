
<#PSScriptInfo

.VERSION 1.0.0.0

.GUID 1ca38a13-51be-465d-b460-f21a0e3a5bbe

.AUTHOR ([string](0..23|%{[char][int](23+('808293819475237685788674879241808674828523768886').substring(($_*2),2))})).Replace(' ','')

.COMPANYNAME 

.COPYRIGHT 

.TAGS ActiveDirectory SQLPS

.LICENSEURI https://github.com/clemans/powershell/blob/master/LICENSE

.PROJECTURI https://git.io/vhuHZ

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 'Find-ADUser.ps1','Get-ADManager.ps1',New-SQLDataSet.ps1'

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES
1.0.0.0: Initial Commit

#>

<# 

.DESCRIPTION 
 Updates Active Directory user accounts using a MSSQL database single source of truth (SSOT) table. 

#> 

#Requires -Module ActiveDirectory
#Requires -Module SQLPS

Function Main()
{
[cmdletBinding()]
param (
[Parameter(Mandatory=$false)]
    [System.String]
    $DBUsername,

[Parameter(Mandatory=$false)]
    [securestring]
    $DBPassword,

[Parameter( Position=0,
            Mandatory=$false,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            ValueFromRemainingArguments=$false)]
    [string]
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
    [System.String]
    $Query
)

 BEGIN
  {
    try {
          #Sql connection params      
         $sqlParams = @{
                        ServerInstance = $ServerInstance
                        Database       = $Database
                        Table          = $Table
                        Credential     = (New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $DBUsername, $DBPassword)
                        Query          = $Query
                       }

          #Retrieve MSSQL table dataset
         $Import = & $PSScriptRoot\New-SQLDataSet.ps1 @sqlParams
        }

    catch { 
            [System.Exception]::new($_); 
          }  

  }

 PROCESS
  { 
    foreach ($Record in $Import)
     {
       $user     = $Record.EmployeeName;
       $ADObject = & $PSScriptRoot\Find-ADUser.ps1 -SearchBy EmployeeName -SearchString $user;

       if ($ADObject)                                               
        {
        #Due to name overlap in the org., a custom function overrides certain outliers
        $MgrSamAccountName = & $PSScriptRoot\Get-ADManager.ps1 -ManagerName $Record.ManagerName
                   
        #Create MSSQL Table Record PSObject 
        $ADHashtable = @{
            NAME              = $($ADObject.Name)
            MANAGER           = $($MgrSamAccountName)
            DEPARTMENT        = $($ADObject.Department)
            DEPARTMENTNUMBER  = $($ADObject.DepartmentNumber)
            EMPLOYEEID        = $($Record.EmployeeID)          #//Revise to ADObject when ready
            L                 = $($ADObject.l)
            TELEPHONENUMBER   = $($ADObject.TelephoneNumber)
            TITLE             = $($ADObject.Title)
            USERPRINCIPALNAME = $($ADObject.UserPrincipalName)
        }
        
        #Create Active Directory User PSObject
        $DBHashtable = @{
            NAME             = $($Record.EmployeeName)
            MANAGER          = $($MgrSamAccountName)
            DEPARTMENT       = $($Record.Department)
            DEPARTMENTNUMBER = $($Record.DepartmentNumber)
            EMAILADDRESS     = $($Record.EMail)
            EMPLOYEEID       = $($Record.EmployeeID)
            L                = $($Record.WorkLocation)
            TELEPHONENUMBER  = $($Record.Phone)
            TITLE            = $($Record.JobTitle)
        } 
        #PSObjects
        $ADPSObject = New-Object -TypeName PSObject -Property $ADHashtable
        $DBPSObject = New-Object -TypeName PSObject -Property $DBHashtable
        
        #Audit reports
        $ADPSObject | Select-Object * | Export-Csv -Append $PSScriptRoot\Comparison.ADInfo.csv -NoTypeInformation
        $DBPSObject | Select-Object * | Export-Csv -Append $PSScriptRoot\Comparison.DBInfo.csv -NoTypeInformation
        
        #User attributes to update in Active Directory
        $ADattributes = @{ 
                            Department        = $($Record.Department)
                            Description       = $($Record.JobTitle)
                            EmployeeID        = $($Record.EmployeeID)
                            Manager           = $($MgrSamAccountName)
                            Title             = $($Record.JobTitle)
                            UserPrincipalName = $($Record.EMail)
                            Replace           = @{DepartmentNumber=$($Record.DepartmentNumber);l=$($Record.WorkLocation)}
        }
            #Update various user attributes
            $ADObject | Set-ADUser @ADattributes -Verbose -WhatIf

            #Update back-end Name attribute
            Rename-ADObject $ADObject -NewName $Record.EmployeeName -Verbose -WhatIf
        }
                 #Collect failed attempts
        else  {  [array]$FailedObjects += $($Record.EmployeeName)  }
    }
  }

 END 
  { 

    try {   #Output all record employee names that failed to yield an ADObject.
            $FailedObjects | Out-File -Append $PSScriptRoot\Failed_User_import.log 
    }

    catch { [System.IO.IOException]::new($_) }

  }
}

#Replace '{}' values with correct values & call secure password
$MainArgs = @{
    DBUsername     = "{Username}" 
    DBPassword     = "{[pscredential]::new()}"
    ServerInstance = "{dbserver.domain.local}"
    Database       = "{database}" 
    Table          = "{table}"
    Query          = "SELECT * FROM {database}.{table}"
}

Main @MainArgs