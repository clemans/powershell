### `clemans/powershell` is a collection of Microsoft PowerShell resources that can be used to aid IT professionals in system administration, automation, and more. This project is comprised of:

## System Administration

**A directory of functions that aim to automate and assist in Microsoft Windows system administration.**

#### `Add-EnvironmentVariable`

Function that takes the input of a folder path and appends it to the existing $ENV:PATH variable.

#### `ConnectTo-Exchange`

A function that creates and establishes a Microsoft Exchange command-line connection allowing to import the Microsoft.Exchange module.

#### `Set-FullPermissions`

 A cmdlet that sets administration ownership and adds full permission inheritance to a specified path file or folder. 
 By default, the local system administrators group takes ownership and is provided full permissions.

## License

The repository and all individual scripts are under the [GNU GENERAL PUBLIC LICENSE](https://www.gnu.org/licenses/gpl.txt)

## Usage

The default computer-level module path is: "$Env:windir\System32\WindowsPowerShell\v1.0\Modules"

## Script Style Guide

* Avoid Write-Host **at all costs**. PowerShell functions/cmdlets are not command-line utilities! Pull requests containing code that uses Write-Host will not be considered. You should output custom objects instead. For more information on creating custom objects, read these articles:
   * <http://blogs.technet.com/b/heyscriptingguy/archive/2011/05/19/create-custom-objects-in-your-powershell-script.aspx>
   * <http://technet.microsoft.com/en-us/library/ff730946.aspx>
