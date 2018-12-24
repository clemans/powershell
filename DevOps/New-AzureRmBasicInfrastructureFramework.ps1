<#PSScriptInfo

.VERSION 1.0.0.2

.GUID db939afc-8af7-4a31-9205-2afcc4140605

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
Initial commit

#>

#Requires -Module AzureRm.Compute
#Requires -Module AzureRm.Network
#Requires -Module AzureRm.Profile
#Requires -Module AzureRm.Resources
#Requires -Module AzureRm.Storage

<# 

.DESCRIPTION 
 An AzureRm script that automates the baseline implementation of an Azure infrastructure as a service (IaaS). 

#> 
Param()

#TECHNICIAN INPUT
    [array]$prompts = @{
                         publicDomain     = Read-Host "Input customer's public domain name (Example: domain.com)"
                         privateDomain    = Read-Host "Input customer's private domain name (Example: internal.domain.local)"
                         mgmtPublicIp     = if(($result = Read-Host "Input management public IP address (Press enter to accept default [12.11.10.9]") -eq ''){[ipaddress]"12.11.10.9"}else{$result}
                         custPublicIp     = [ipaddress](Read-Host "Input customer's public IP address (Example: 11.10.9.8)")
                         privateIp        = Read-Host "Input customer's private IP address network (Example: 172.16.1.0/24)"
                         s2sName          = Read-Host "Input the location name you wish to create a site-to-site IPsec VPN connection (e.g. Compton)"
                         sharedKey        = Read-Host "Input a shared key for the site-to-site connection (avoid special characters)"
                         rLocation        = if(((Get-AzureRmLocation).Location) -contains ($result = Read-Host "Enter the location for your Azure resources (For valid locations, cancel & type: Get-AzureRmLocation)")){$result} else{throw "Invalid location. For a list of valid locations, type: Get-AzureRmLocation"; Continue}
                         inputCredentials = @{ Username = 'stem'; Password = Read-Host "Type the password for local user .\stem" -AsSecureString}
                         numVms           = [int](Read-Host "How many VMs do you wish to create? (integers only)" -ea Stop)
                       }

            for ($i=0; $i -lt $prompts.Keys.Count; $i++) {

                New-Variable -Name $prompts.Keys[$i] -Value $prompts.Values[$i] -Force
            }
try 
{
        #Get Resource Sizes
        for ($i=1; $i -le $numVms; $i++)
        {
            $instanceSize = Read-Host "What instance size for VM #($($i))"
          
          #Validates Instance Size
          if ( ((Get-AzureRmVMSize -Location $rLocation).Name -contains $instanceSize))
            {
                $instanceName = Read-Host "Type the hostname for VM #($($i))"
                [array]$VMConfigs += New-Object psobject -ArgumentList @{$instanceName = $instanceSize;}
            }  

          else {return "Invalid Azure size. To get a list of Azure sizes, type: Get-AzureRmVmSize"}
        }
}         catch {return "Invalid Azure size. To get a list of Azure sizes, type: Get-AzureRmVmSize"}
  
#AZURE OBJECT NAME VARIABLES
    [string]$pPrefix   = ((($publicDomain.Split('.'))[-2])[0..13] -join '').ToLower()
    [string]$nPrefix   = ((($privateDomain.Split('.'))[-2])[0..13] -join '').ToLower()
    [array]$nVariables = @("rgName","nsgName","vnetName","lgwName","pipName","configName","vngName")
    [array]$nSuffixes  = @("-rg",   "-nsg",   "-vnet",   "-lgw",    "-pip",      "-config",   "-vngw")

    for ($i=0 ; $i -lt $nVariables.count; $i++)
    {
        $value = [System.String]::Concat($nPrefix,$nSuffixes[$i]) 
        New-Variable -Name $nVariables[$i] -Value $value -Force
    }

Sleep(1)
#CONNECT TO AZURE
    Connect-AzureRmAccount -ErrorAction Stop

####################EXECUTION####################

Sleep(1)
#CREATE RESOURCE GROUP
    $rg = New-AzureRmResourceGroup -Name $rgName -Location $rLocation -Tag @{Environment="Development"} -ErrorAction Stop

Sleep(1)
#CREATE NETWORK SECURITY RULE (RDP)
    New-AzureRmNetworkSecurityRuleConfig -Name rdp-rule -Description "Allow RDP" `
                                         -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
                                         -SourceAddressPrefix $mgmtPublicIp -SourcePortRange * `
                                         -DestinationAddressPrefix * -DestinationPortRange 3389 `
                                         -OutVariable +nsgRules -ErrorAction Stop
Sleep(1)
#CREATE NETWORK SECURITY RULE (IpSec)    
    New-AzureRmNetworkSecurityRuleConfig -Name s2s-rule -Description "Allow IPsec" `
                                         -Access Allow -Protocol * -Direction Inbound -Priority 101 `
                                         -SourceAddressPrefix $privateIp -SourcePortRange * `
                                         -DestinationAddressPrefix * -DestinationPortRange * `
                                         -OutVariable +nsgRules -ErrorAction Stop
#CREATE NETWORK SECURITY GROUP
    $nsg = New-AzureRmNetworkSecurityGroup -ResourceGroup $rg.ResourceGroupName -Location $rg.Location -Name $nsgName -SecurityRules $nsgRules -ErrorAction Stop

#CREATE NETWORK SPACE: VIRTUAL NETWORK, SUBNETGATEWAY, FRONT-END SUBNET, & BACK-END SUBNET
    [string]$randomSubnet = $(Get-Random -Minimum 50 -Maximum 250)
    [string]$networkRange = [System.String]::Concat("10.",$randomSubnet,".0.0/16")
    [array]$subnetNames   = @('GatewaySubnet','backend-sub','frontend-sub')
    [array]$cidrs         = @('/27','/24','/24')

    for ($i=0; $i -lt $subnetNames.Count; $i++)
    {
        New-Variable -Name $subnetNames[$i] -Value $([System.String]::Concat('10.',$([int]$randomSubnet),'.',$([int]$randomSubnet+$i),'.0',$cidrs[$i])) -Force -ErrorAction Stop
                if ($subnetNames[$i] -ne 'GatewaySubnet') 
                { New-AzureRmVirtualNetworkSubnetConfig -Name $subnetNames[$i] -AddressPrefix $((Get-Variable $subnetNames[$i]).Value) -NetworkSecurityGroup $nsg -OutVariable +Subnets -ErrorAction Stop }
                else { New-AzureRmVirtualNetworkSubnetConfig -Name $subnetNames[$i] -AddressPrefix $((Get-Variable $subnetNames[$i]).Value) -OutVariable +Subnets -ErrorAction Stop }
    }

Sleep(3)
#CREATE VIRTUAL NETWORK
    $vNet = New-AzureRmVirtualNetwork -Name $vNetName -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location -AddressPrefix $networkRange -Subnet $Subnets -ErrorAction Stop

Sleep(3)
#CREATE LOCAL NETWORK GATEWAY
    $lgwPip = $custPublicIp
    $lgw = New-AzureRmLocalNetworkGateway -Name $lgwName -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location -GatewayIpAddress $lgwPip  -AddressPrefix $privateIp -ErrorAction Stop

Sleep(3)
#CREATE NETWORK GATEWAY PUBLIC IP ADDRESS
    $ngwpipName = [System.String]::Concat($vngName,'-pip')
    $ngwpip = New-AzureRMPublicIpAddress -Name $ngwpipName -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location -AllocationMethod Dynamic

Sleep(3)
#CREATE VIRTUAL NETWORK GATEWAY CONFIGURATION
    $subnetConfig = Get-AzureRmVirtualNetworkSubnetConfig -Name 'GatewaySubnet' -VirtualNetwork $vnet -ErrorAction Stop
    
    foreach ($subnetId in $subnetConfig.Id)
    {
        New-AzureRMVirtualNetworkGatewayIpConfig -Name $configName -SubnetId $subnetId -PublicIpAddressId $ngwpip.Id -OutVariable +vngwIpConfig -ErrorAction Stop
    }

Sleep(3)
#CREATE VIRTUAL NETWORK GATEWAY
    New-AzureRmVirtualNetworkGateway -Name $vngName -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location -IpConfigurations $vngwIpConfig -GatewayType Vpn -VpnType RouteBased -GatewaySku Standard -ErrorAction Stop

Sleep(1)
#CREATE STORAGE ACCOUNT
    $azureStorage = New-AzureRmStorageAccount -ResourceGroupName $rg.ResourceGroupName -Name "$pPrefix`storage01" -Location  $rg.Location -SkuName "Standard_LRS" -Kind "Storage" -ErrorAction Stop

Sleep(1)
#CREATE STORAGE ACCOUNT KEYS
    $Keys = Get-AzureRmStorageAccountKey -ResourceGroupName $rg.ResourceGroupName -Name $azureStorage.StorageAccountName -ErrorAction Stop

Sleep(1)
#CREATE STORAGE CONTEXT
    $StorageContext =  New-AzureStorageContext -StorageAccountName $azureStorage.StorageAccountName -StorageAccountKey $Keys[0].Value

Sleep(1)
#CREATE STORAGE CONTAINER
    New-AzureStorageContainer -Context $StorageContext.Context.Context -Name uploads -ErrorAction Stop

Sleep(1)
#CREATE NEW VIRTUAL MACHINE
$Credentials= New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $inputCredentials.Username, $(ConvertTo-SecureString $inputCredentials.Password -AsPlainText -Force)

foreach ($vm in $VMConfigs)
{
    
    $vmParams = [ordered]@{
                   Credential          = $Credentials
                   ResourceGroupName   = $rg.ResourceGroupName
                   Name                = $vm.Keys
                   Location            = $rg.Location
                   VirtualNetworkName  = $vNet.Name
                   SubnetName          = $subnetNames[1]
                   SecurityGroupName   = $nsg.Name
                   PublicIpAddressName = "$($vm.Keys)-pip"
                   Size                = $vm.Values    
    
    } 
    
   New-AzureRmVM @vmParams 
}

#CREATE SITE-TO-SITE POLICY
    $IpSecPolicy = New-AzureRmIpsecPolicy -IkeEncryption AES256 -IkeIntegrity SHA384  -IpsecEncryption AES256 -IpsecIntegrity SHA256 -DhGroup DHGroup24 -PfsGroup None -SALifeTimeSeconds 14400 -SADataSizeKilobytes 102400000

#CREATE SITE-TO-SITE CONNECTION

#do { 
#      $provisioningState = $(Get-AzureRmVirtualNetworkGateway -ResourceGroupName $rg.ResourceGroupName).ProvisioningState
#      for ($i=50; $i -le 100; $i++){ Write-Progress -Activity Checking -Status 'Provisioning State' -PercentComplete $i;}; $provisioningState
#   }
#
#while ($provisioningState -ne 'Succeeded')

    $vngwS2SName = [System.String]::Concat(($s2sName.ToLower()[0..13]) -join "",'-IPSec','-s2s')
    $vngw = Get-AzureRmVirtualNetworkGateway -Name $((Get-AzureRmResource -ResourceType Microsoft.Network/virtualNetworkGateways)[0]).Name -ResourceGroupName $rg.ResourceGroupName

    New-AzureRmVirtualNetworkGatewayConnection -Name $vngwS2SName `
                                 -ResourceGroupName $rg.ResourceGroupName `
                                 -Location $rg.Location `
                                 -VirtualNetworkGateway1 $vngw `
                                 -LocalNetworkGateway2 $lgw `
                                 -ConnectionType IPsec `
                                 -IpsecPolicies $IpSecPolicy `
                                 -SharedKey $sharedKey `
                                 -UsePolicyBasedTrafficSelectors $True

#####################################                                 
#####UPLOAD GOLD IMAGE###############
#####STILL WORKING OUT SOME BUGS#####
#####################################
<#
#UPLOAD VHD TO BLOB STORAGE
    $UploadFile = @{
                    BlobType  = 'Page'
                    Context   = $StorageContext.Context;
                    Container = 'uploads';
                    File      = "C:\VMs\ws2019-standard_template.vhd"
                   }
    #Long upload
    Set-AzureStorageBlobContent @UploadFile

    #Url to the .vhd file, use later when creating VM - Research ways to streamline the vhd upload process & Uri gathering
    #
    #To create the "$StorageContext" variable without recreating the Storage Context, type: $StorageContext = Get-AzureStorageContainer -Context $(Get-AzureRmStorageAccount).Context.Context
    #
    $vhdUri = (Get-AzureStorageBlob -Context $StorageContext.Context.Context -Container uploads -ErrorAction Stop).iCloudBLob.Uri.AbsoluteUri 

#PENDING-CREATE VIRTUAL MACHINE

#CREATE MANAGED DISK IMAGE CONFIGURATION
    $imageConfig = New-AzureRmImageConfig -Location $rg.Location -ErrorAction Stop

#CREATE OPERATING SYSTEM IMAGE OBJECT
    Set-AzureRmImageOsDisk -Image $imageConfig  -OsType Windows -OsState Generalized -BlobUri $vhdUri -ErrorAction Stop

#CREATE A NEW AZURE IMAGE

    #name. (e.g. 2018-12-10_ws2019-standard_template.vhd)
    $imageName = "$(Get-Date -Format "yyyy-MM-dd")_$($vhdUri.Split('/')[-1])"

    $templateImage = New-AzureRmImage -ImageName $imageName -ResourceGroupName $rg.ResourceGroupName -Image $imageConfig -ErrorAction Stop

#CREATE A VIRTUAL MACHINE
    $vmParams = [ordered]@{
                   ResourceGroupName   = $rg.ResourceGroupName
                   Name                = "test-dc-1"
                   ImageName           = $templateImage.Name
                   Location            = $rg.Location
                   VirtualNetworkName  = $vNet.Name
                   SubnetName          = $subnetNames[1]
                   SecurityGroupName   = $nsg.Name
                   PublicIpAddressName = "test-dc-1-pip"
                   Size                = "Standard_D2s_v3"
                }

    New-AzureRmVM @vmParams

#>