
<#PSScriptInfo

.VERSION 1.0

.GUID cc549a52-5b55-44b7-9fec-a59ced55a91b

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
 A custom PowerShell function that attempts to find a user's ADComputer when searching their name. This only works
 if your domain environment label ADComputer descriptions with a user's name. (e.g. "IT-John Doe (Laptop)") 

 #Example 1: C:\> up "john doe"
 #Example 2: C:\> Get-PCs -ADName 'Doe'
 #Example 3: C:\> up

#>

[CmdletBinding()]
[Alias("up")]	 
Param
(
    [string[]]$ADName = @(((Get-ADuser -Identity $env:username).SurName)) #default param is script user's surname
)

BEGIN
{
#Confirm module is available
    if (!(Get-Module -ListAvailable -Name ActiveDirectory)) 
    { 
        'The Microsoft Management Console (MMC) "Active Directory Users and Computers"`
            must be installed in order to use this cmdlet.'; 
        Continue;
    } 
}

PROCESS
{
#Runtime succeeds
try {
     
      #Appends input to assist with the $pc filter query   
	  $queryName = [String]::Concat('*',$ADName,'*');
			
        if ($ADComputers = Get-ADComputer -Filter {Description -like $queryName} -Properties Description | 
            ForEach-Object {$_.DNSHostName}) 
           {
            #PC ID number
            $i = 1;

			foreach ($PC in $ADComputers) { 
                #Find PC in ADUC
                $ADComputer = Get-ADComputer -Identity $PC.Split('.')[0] -Properties IPv4address,Description;
                
                #Check connectivity status, set variable
                $status = @{$true = 'UP'; $false = 'DOWN'}[{Test-Connection -Computername $PC -Count 1}]
                
                #Check uptime status, set variable
                $uptime = @{$true = $((Get-Uptime -ComputerName $PC).Uptime); $false ='N/A' }[$status -eq 'UP']

                $pcHashTable = [ordered]@{
                                ID            = $($i)
                                ComputerName  = $($ADComputer.Name)
                                Status        = $($status)
                                Description   = $($ADComputer.Description)
                                IPv4Address   = $($ADComputer.IPv4Address)
                                Uptime        = $($uptime)
                            }

                #Custom AD PC object
                New-Object -TypeName PSObject -Property $pcHashTable

                #Iterate PC ID number
                $i++ ;
	 		}
        } 
        else {  
            throw  
        }
    }

    #Runtime out is null or fails
    catch { 
        [System.DirectoryServices.ActiveDirectory.ActiveDirectoryObjectExistsException]("No PC(s) found with description: `"$($ADName)`"")
            }
}