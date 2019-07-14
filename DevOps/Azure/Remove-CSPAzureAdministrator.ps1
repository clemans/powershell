
Function Remove-CSPAzureAdministrator()
{
<#PSScriptInfo

.VERSION 1.0.0.0

.GUID fb654483-0d00-4fab-8b87-03fce5584550

.AUTHOR ([string](0..23|%{[char][int](23+('808293819475237685788674879241808674828523768886').substring(($_*2),2))})).Replace(' ','')

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

#Requires -Module Az.Accounts
#Requires -Module Az.Resources
#Requires -Module AzureADPreview

<# 

.DESCRIPTION 
 An Azure function that automates the removal of external guest accounts and role assignments for Azure (IaaS) subscriptions. 

#>

    Param(
    [Parameter(Mandatory=$true)]
        [System.String]
        $EmailAddress = $(Read-Host -Prompt "Input the EmailAddress of the user you wish to remove access to all Azure subscriptions")

    )

        $azCredentials   = (Get-Credential -Message "Input Azure Credentials")

        #Connect to Azure Directory
            Connect-AzAccount -Credential $azCredentials

        #Get all Azure Tenants
            $azTenants = Get-AzTenant

        foreach ($tenant in $azTenants)
        {
            #Select the Azure Directory
                Select-AzSubscription -SubscriptionObject $(Get-AzSubscription -TenantId $tenant.Id)

            #Connect to the tenant
                Connect-AzureAD -TenantId $tenant.Id -Credential $azCredentials

            Get-AzureADUser -Filter "Mail eq '$($EmailAddress)'" | Remove-AzureADUser
        }
    }