
<#PSScriptInfo

.VERSION 1.0.0.0

.GUID aa33ba2b-3ec3-42cc-981b-70e52a7736b2

.AUTHOR ([string](0..23|%{[char][int](23+('808293819475237685788674879241808674828523768886').SubString(($_*2),2))})).Replace(' ','')

.COMPANYNAME 

.COPYRIGHT 

.TAGS ActiveDirectory

.LICENSEURI https://github.com/clemans/powershell/blob/master/LICENSE

.PROJECTURI https://git.io/ffCb5

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS Confirm-Termination,Start-Termination

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES
1.0.0.0: Initial Commit

#> 

#Requires -Module ActiveDirectory


<# 

.DESCRIPTION 
 A multi-function custom script which aims to automate a specific company's disable user account process. 

#> 
param (
       [Parameter(mandatory=$true,ValueFromPipeline=$true)]
            [ValidateScript({Get-ADUser $_})]
             [System.Object]$ADName               = (Read-Host "`nInput the employee account username you wish to terminate"),
    
       [Parameter(mandatory=$true,ValueFromPipeline=$true)]
             [System.String]$Ticket             = (Read-Host "`nInput the termination ticket number"),
    
       [Parameter(mandatory=$false,ValueFromPipeline=$true)]
            [ValidateScript({Test-Path $_})]
             [System.String]$LogPath              = (<#UPDATE_VARIABLE#>""),

       [Parameter(mandatory=$false,ValueFromPipeline=$true)]
             [System.String]$HelpDesk_Email       = (<#UPDATE_VARIABLE#>""),
                           
       [Parameter(mandatory=$false,ValueFromPipeline=$true)]
            [System.String]$HumanResources_Email = (<#UPDATE_VARIABLE#>""),

       [Parameter(mandatory=$false,ValueFromPipeline=$true)]
             [System.String]$MailServer           = (<#UPDATE_VARIABLE#>""),

       [Parameter(mandatory=$false,ValueFromPipeline=$true)]
             [System.String]$Technician_Email     = (<#UPDATE_VARIABLE#>""),
             
       [Parameter(mandatory=$false,ValueFromPipeline=$true)]
             [System.String]$Organizational_Unit  = (<#UPDATE_VARIABLE#>"")                  
      )

BEGIN 
{

 Try   { 
          $ADUser  =  Get-ADUser $ADName -Properties * ;
          $LogPath =  (Resolve-Path $LogPath).Path
       }

 Catch {
          throw { Write-Warning "Error accessing $($_): $($_.Exception.Message)" }
       }

}

PROCESS 
{

<#TERMINATION CONFIRMATION#>
Function Confirm-Termination($arg1)
{
              Process
              {  
                $title   = "Disable Account: $($arg1.SamAccountName)`n`n"
    
                $message = "Do you want to terminate the employee: $($arg1.GivenName.toUpper()+" "+$arg1.SurName.toUpper())?`n`n"

                $yes     = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes",  "Execute Termination"

                $no      = New-Object System.Management.Automation.Host.ChoiceDescription "&No",   "Cancels Termination"

                $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

                $result  = $host.ui.PromptForChoice($title, $message, $options, 0) 
              }

              End
              { 
                Return $result
              }

}

<#TERMINATION EXECUTION#>
Function Start-Termination($arg1, $arg2) 
{

    #custom disable workflow
    Function Stop-ADAccount($arg2) 
     {

            Disable-ADaccount -Identity $($arg2.SamAccountName)           
            Write-Host -ForegroundColor White "Account `"$($arg2.SamAccountName)`" DISABLED!`n"
     }

    #custom wipedown workflow
    Function Clear-ADAccount($arg2) 
     {
        $user_attributes   = @{
                                 Identity = $arg2.SamAccountName
                                 Clear    = @('Company','Department','Description','facsimileTelephoneNumber',
                                              'homeDirectory','homePhone','ipPhone','l','manager','mobile',
                                              'otherTelephone','pager','postalCode','postOfficeBox','st',
                                              'streetAddress','telephoneNumber','Title')
                                 Office   =   ' '
                              }

        $group_attributes  = @{   
                                 Identity              = $arg2.SamAccountName
                                 ResourceContextServer = ((Get-ADDomain).DNSRoot)
                              }
        
        $user_groups = Get-ADPrincipalGroupMembership @group_attributes

        Set-ADUser @user_attributes

          for ($i=1; $i -lt $user_groups.length; $i++)
            {
               Remove-Adgroupmember $user_groups[$i] $arg2.SamAccountName -Confirm:$false 
            }
       
        Write-Host -Foreground White "Account `"$($arg2.SamAccountName)`" memberships and properties have been cleared.`n"

    }

    #custom notification workflow
    Function Send-TurnoverMessage($arg2)
     {
     
     $email_attributes = 
     @{
       To          = @($HumanResources_Email,$Technician_Email)
       From        = $HelpDesk_Email
       SmtpServer  = $MailServer
       Subject     = "Account Disabled: $($arg2.GivenName) $($arg2.SurName)"
       Encoding    = ([System.Text.Encoding]::UTF8)
       Attachments = (Join-Path -Path $LogPath -ChildPath "PDF Exports\disable_$($arg2.SamAccountName).pdf")
       Body        = @"
        
        Greetings,`n
        
        The user account $($arg2.GivenName) $($arg2.SurName) has been disabled as of $(Get-Date).
        Please keep this notification for your records.
                
        Thank you,
        -IT`n
        
        Technician assigned: $env:username
"@    }

	    Send-MailMessage @email_attributes
    	Write-Host -Foreground White "Human Resources has been notified. Check your inbox for an attachment. You are required to attach this to incident: $Ticket"
     
     }

    #audit log of account details
    Function New-AuditDataFile($arg2) 
     {

     BEGIN 
     {
          
     }

     PROCESS 
     {
      Write-Host -ForegroundColor White "Exporting termination log information for `"$($arg2.SamAccountName)`"...`n";  
            
            $user_groups = @{
                              Identity              = $arg2.SamAccountName
                              ResourceContextServer = ((Get-ADDomain).DNSRoot)  
                            }

            $groups      = Get-ADPrincipalGroupMembership @user_groups | Sort-Object
 
            # save user attributes in an object
            $userObject = New-Object psobject -ArgumentList @{ TERMINATED_ACCOUNT = "$($arg2.GivenName) $($arg2.SurName) ($($arg2.SamAccountName))";
                                                               ENABLED            =  $(do     { Wait-Event -Timeout 1 } 
                                                                                       until  (((Get-Aduser -identity $arg2.SamAccountName).Enabled) -eq $FALSE); 
                                                                                       ((Get-Aduser -identity $arg2.SamAccountName).Enabled))

                                                               TERMINATION_DATE   =  $((Get-Date).DateTime);
                                                               LAST_LOGON_DATE    =  $($arg2.LastLogonDate.DateTime);
                                                               GROUP_MEMBERSHIPS  =  $($groups.Name);
                                                             }

            # create a form to export
            $Log=   for ($i=$userObject.Count-1; $i -ge 0 ; $i--)
                       {
                          "$($userObject.Keys.Split("`n")[$i]):"
                          $userObject.Item( $userObject.Keys.Split("`n")[$i] ); ""
                       }

            $filename = "\PDF Exports\disable_$($arg2.SamAccountName).csv"

            Out-File -FilePath (Join-Path -Path $LogPath -ChildPath $filename) -InputObject $Log
            Start-Sleep(1);
     }
         
     END 
     { 
        #Return $Log;
        Return (Resolve-Path -Path (Join-Path -Path $LogPath -ChildPath $filename)).ProviderPath;
     }
    
}

    #convert audit log to pdf
    Function Convert-PDFLog($filelocation)
     {
        try {
    
                # Converts the exported CSV file into a PDF file
                Write-Host -ForegroundColor White "Converting termination log into PDF format...`n"
                Start-Sleep(2)
    
                $LogPDF=$($filelocation) -replace '\.csv$','.pdf'
    

                #open excel obj
                    $excelObj = New-Object -ComObject excel.application -Property @{Visible=$false}
                    Start-Sleep(1);

                #open object in wb
                    $workbook = $excelObj.workbooks.open($($filelocation), 3)
                    Start-Sleep(1);
       
                #save wb obj
                    $workbook.Saved = $true 
                    Start-Sleep(1);

                #save as pdf
                    $xlTypePDF="Microsoft.Office.Interop.Excel.XlFixedFormatType" -as [type]
                    $workbook.ExportAsFixedFormat(($xlTypePDF::xlTypePDF), $($LogPDF))

                #kill excel
                    $excelObj.Workbooks.Close();
                    while ( [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excelObj) ) {}

                #remove csv
                    Remove-Item $filelocation -Force -ErrorAction SilentlyContinue
            }

        catch { 
                Throw  "The PDF conversion failed."; 
              }
    } 
       
    switch ($arg1)
      {
        0 { 
                    
              Write-Host "`nTerminating $($arg2.SamAccountName)...`n";
                Start-Transcript -Path (Join-Path -Path $LogPath -ChildPath "$(Get-Date -format "yyyy'.'MM'.'dd")_$($arg2.SamAccountName) (disabled by $($env:username)).log");
                Stop-ADAccount($arg2)
                Convert-PDFLog(New-AuditDataFile($arg2))
                Clear-ADAccount($arg2)
                Send-TurnoverMessage($arg2)
              
                    break
          }
               
        1 {                   
              "`n`nCancelling termination. Exiting Script...`n"; 
                    break 
          }

          default { 
                    throw {    "Account name is: $($arg2.SamAccountName)"; "No matching input for $arg1"}
                  }
      }
}

<#BANG#>
Start-Termination (Confirm-Termination($ADUser)) $ADUser 

}

END 
{
    Stop-Transcript;
    Write-Host -ForegroundColor White "`nProcess Finished. Termination log is $LogPath\PDF Exports\disable_$($ADUser.SamAccountName).pdf`n"
}