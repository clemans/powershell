
<#PSScriptInfo

.VERSION 1.0.0.0

.GUID 34273d63-ffe9-47ac-a660-12bc8db0f99e

.AUTHOR ([string](0..23|%{[char][int](23+('808293819475237685788674879241808674828523768886').substring(($_*2),2))})).Replace(' ','')

.COMPANYNAME 

.COPYRIGHT 

.TAGS 

.LICENSEURI 

.PROJECTURI https://git.io/fjX0M

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES


#>

<# 

.DESCRIPTION 
 A collection of cmdlets that assist with the deletion of browsing and explorer related history. 

#> 

Function Delete-IEHistory()
{
    Get-Process iexplore -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue -Verbose

    $tempInternetFolders = @( "C:\Users\$env:username\Appdata\Local\Temp\Microsoft\Windows\Temporary Internet Files\*", 
                              "C:\Users\$env:username\Appdata\Local\TMicrosoft\Windows\INetCache\*", 
                              "C:\Users\$env:username\Appdata\Local\Microsoft\Windows\Cookies\*"
                            )
    Remove-Item $tempInternetFolders -Force -Recurse -Verbose -ErrorAction SilentlyContinue

    $t_path_7 = "C:\Users\$env:username\AppData\Local\Microsoft\Windows\Temporary Internet Files"
    $c_path_7 = "C:\Users\$env:username\AppData\Local\Microsoft\Windows\Caches"
 
    $temporary_path =  Test-Path $t_path_7
    $check_cache =    Test-Path $c_path_7
 
    if($temporary_path -eq $True -And $check_cache -eq $True)
    {
        #Delete History
        RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 1
 
        RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 8
        
        Remove-Item $t_path_7\* -Force -Recurse -ErrorAction SilentlyContinue
        RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 2
 
        #Delete Cache
        Remove-Item $c_path_7\* -Force -Recurse -ErrorAction SilentlyContinue

    }
}    

Function Delete-ChromeHistory()
{

    Get-Process chrome -ErrorAction SilentlyContinue | Stop-Process -Force -Verbose -ErrorAction SilentlyContinue

    $Items = @('Archived History',
            'Cache\*',
            'Cookies',
            'History',
            'Login Data',
            'Top Sites',
            'Visited Links',
            'Web Data')
    $Folder = "$($env:LOCALAPPDATA)\Google\Chrome\User Data\Default"
    $Items | % { 
        if (Test-Path "$Folder\$_") {
            Remove-Item "$Folder\$_" 
        }
}

}

Function Delete-FirefoxHistory()
{
    Get-Process firefox -ErrorAction SilentlyContinue | Stop-Process -ErrorAction SilentlyContinue -Force -Verbose

    $LocalDataDir = "C:\Users\$($env:USERNAME)\AppData\Local\Mozilla\Firefox\Profiles"
    $RoamingDataDir = "C:\Users\$($env:USERNAME)\AppData\Roaming\Mozilla\Firefox\Profiles\*"

    if (ls $LocalDataDir -ErrorAction SilentlyContinue)
    {
        Remove-Item -Path $LocalDataDir -Recurse -Force -Confirm:$False -Verbose
    }

    if (ls $RoamingDataDir)
    {
        $sqlTables = [System.String]::Concat($file.FullName,"\*sqlite")
        foreach ($table in $(ls $sqlTables))
        {   
            Remove-Item -Path $table -Force -Confirm:$False -Verbose 
        }
    }  
}

Function Delete-WindowsHistory()
{
    #Delete Recent Items Contents
    Remove-Item HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU\    -Verbose -Force -ErrorAction SilentlyContinue
    Remove-Item HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths -Verbose -Force -ErrorAction SilentlyContinue
    
    #Delete Recycling Bin Contents
    Get-ChildItem -path 'C:\$Recycle.Bin' -Include '*' -Recurse -Force | Remove-Item -Verbose -Force -Recurse -ErrorAction SilentlyContinue
    
    #Delete PowerShell History
    Remove-Item (Get-PSReadlineOption).HistorySavePath

    #Delete Downloads
    Remove-Item "C:\Users\$env:username\Downloads\*" -Force -Recurse -ErrorAction SilentlyContinue

    #Delete Temporary User Profile Files
    Remove-Item "C:\Users\$env:username\AppData\Local\Temp\*" -Force -Recurse -ErrorAction SilentlyContinue
}   

Function Delete-History()
{
Param(
[Parameter(Mandatory=$false)]
    [Switch]
    $All,

[Parameter(Mandatory=$false)]
    [Switch]
    $Chrome,

[Parameter(Mandatory=$false)]
    [Switch]
    $Firefox,

[Parameter(Mandatory=$false)]
    [Switch]
    $InternetExplorer,

[Parameter(Mandatory=$false)]
    [Switch]
    $Windows
)

    if ($All)
    {
        Delete-ChromeHistory
        Delete-FirefoxHistory
        Delete-IEHistory
        Delete-WindowsHistory
    }

    if ($Chrome)
    {
        Delete-ChromeHistory
    }

    if ($Firefox)
    {
        Delete-FirefoxHistory
    }

    if ($InternetExplorer)
    {
        Delete-IEHistory
    }
    
    if ($Windows)
    {
        Delete-WindowsHistory
    }  
}