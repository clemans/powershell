
<#PSScriptInfo

.VERSION 1.0.0.0

.GUID 3b73cd6f-04bb-4b3a-9a50-79e915a83bb5

.AUTHOR ([string](0..23|%{[char][int](23+('808293819475237685788674879241808674828523768886').substring(($_*2),2))})).Replace(' ','')

.COMPANYNAME 

.COPYRIGHT 

.TAGS ActiveDirectory

.LICENSEURI https://github.com/clemans/powershell/blob/master/LICENSE

.PROJECTURI https://git.io/vhus9

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES
1.0.0.0: Initial Commit

#>

#Requires -Module ActiveDirectory
#Requires -Module SQLPS

<# 

.DESCRIPTION 
 Attempts to return an Active Directory user object using string input such as a DisplayName string. 

#> 

param (
[Parameter( Mandatory=$true,
            Position=0,
            ValueFromPipeline=$false)]
    [ValidateSet("EmployeeName", "EmployeeID", "sAMAccountName")]
    [String[]]
    $SearchBy,

[Parameter( Mandatory=$true,
            Position=2,
            ValueFromPipeline=$true)]
    [String]
    $SearchString
    )
PROCESS 
{
    switch ($SearchBy)
    {
        # Search for ADObject using EmployeeID attribute
        EmployeeID {
                try {
                    $ADObject = Get-ADUser -Filter {EmployeeID -eq $SearchString} -Properties *;
                }
                catch {
                    $ADObject = $null;
                }
        }
        # Search for ADObject using GivenName & SurName attributes
        EmployeeName {

        #Split input to count number of words in a name
        [array]$User = $SearchString -split ', ' -Split " ";
        switch ($User.Count)
        { 
            # $User = LastName, FirstName
            2 { 
                $initial   = $null;
                $suffix    = $null;
                $surname   = $User[0];
                $givenname = $User[1];
                
                Break
                }
            
            # $User = LastName Jr./Sr., FirstName
            3 { 
                if ($User[1] -match "..\.")
                {
                $initial   = $null; 
                $surname   = $User[0];
                $suffix    = $User[1];
                $givenname = $User[2];
                }
            # $User = LastName, FirstName I.
                else
                {
                $suffix    = $null;
                $surname   = $User[0];
                $givenname = $User[1];
                $initial   = $User[2];	
                }
    
                Break 
                }
            # $User = LastName Jr./Sr., FirstName I.
            4 { 
                $surname   = $User[0];
                $suffix    = $User[1];
                $givenname = $User[2];
                $initial   = $User[3];
                
                Break
                }
            # Algorithm failed, null output
            default
                {
                $surname   = $null;
                $suffix    = $null;
                $givenname = $null;
                $initial   = $null;
                }
    
        }
    
        try
        {
    
            $ADObject = Get-ADUser -Filter {(GivenName -eq $givenname) -and 
                                            (SurName -eq $surname)     -and 
                                            (Enabled -eq $True)
                                            } -Properties *;
        }
    
        catch { return [System.Exception]::new($_) }
    
        try 
        {
            switch ($ADObject.GetType().BaseType)
            {
                ([array])
                {
                    $samAccountName = [string]::Concat($givenname[0],$surname)
                    $ADObject       = $ADObject | Where-Object {$_.SamAccountName -eq $samAccountName}
                    Break;
                }
    
                ([Microsoft.ActiveDirectory.Management.ADAccount])
                {
                    Break;
                }
    
                default
                {   
                    $ADObject = $null;
                    throw;
                }  
            }
        }
    
        catch
        {       #Query first 3 letters of givenName
                if ($null -eq $ADObject) 
                    {
                            $given    = "$($givenname[0..2] -join '')*";
                            $ADObject = Get-Aduser -Filter {(GivenName -like $given)   -and 
                                                            (SurName   -eq    $surname) -and 
                                                            (Enabled   -eq    $True)}   -Properties *;
                    }                       
                #Build sAMAccountName and attempt query
                if ($null -eq $ADObject) 
                    {
                            $samAccountName = [string]::Concat($givenname[0],$surname);
                            $ADObject       = Get-ADUser -Filter {SamAccountName -eq $samAccountName} -Properties *;
                    }
    
                #Query with only surname and declare if only 1 object
                if ($null -eq $ADObject) 
                    {
                            if ( (([array](Get-ADUser -Filter {Surname -eq $surname})).Count) -eq 1 )
                            {
                                $ADObject = Get-ADUser -Filter {SurName -eq $surname} -Properties *
                            }
                    }
                        
                if ($null -eq $ADObject) #Null value, break loop
                    { 
                            $ADObject=$null;
                    }
            }
        }

        # Search for ADObject using sAMaccountName attribute
        sAMAccountName {
                        try {
                            Get-ADUser -Identity $SearchString -Properties * 
                        } 
                        catch {
                            [System.DirectoryServices.ActiveDirectory.ActiveDirectoryObjectExistsException]::new("`n$_`n");
                        }
                        }
        #Lazy default
        default {"derp"}
    }
}
END     
{
    return $ADObject;
}