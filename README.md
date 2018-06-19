### `clemans/powershell` is a collection of Microsoft PowerShell resources that can be used to aid IT professionals in system administration, automation, and more. This project is comprised of:

## System Administration

**A directory of functions that aim to automate and assist in Microsoft Windows system administration.**

#### `>_: Add-EnvironmentVariable.ps1`

Function that takes the input of a folder path and appends it to the existing $ENV:PATH variable.

#### `>_: Create-SecurePassword.ps1`

A quick script that safely encrypts a password and outputs to a file.

#### `>_: ConnectTo-Exchange.ps1`

A function that creates and establishes a Microsoft Exchange command-line connection allowing to import the Microsoft.Exchange module.

#### `>_: Find-ADUser.ps1`

A function that attempts to return an Active Directory user object using string input such as a SQL record DisplayName string.

#### `>_: Get-ADManager.ps1`

A workaround function that resolves DisplayName overlap in Active Directory. This function compliments the `Start-DatabaseSync.ps1` script.

#### `>_: Get-PCs.ps1`

A custom function that attempts to find a user's computer when searching their name in the ADComputer's description attribute.

#### `>_: New-HttpsListener.ps1`

A group policy script that creates an HTTP/HTTPS WS-Man listener for PowerShell remoting.

#### `>_: New-SQLDataSet.ps1`

A function that creates a new SQL connection, queries the specified MSSQL database, and outputs the specified tableset.

#### `PowerShellRemoting.md`

PowerShell remoting group policy object documentation. Requires scripts: `New-HttpsListener.ps1` & `Set-PowerShell_SDDL.ps1` 

#### `>_: Set-CustomDirectoryACLs.ps1`

A custom function that sets a root folders' parents' ACLs on child objects. Useful if there are multiple parent folders with identical child objects. (Created as a workaround) 

#### `>_: Set-PowerShell_SDDL.ps1`

A group policy script that sets SDDLs on the PSSessionConfiguration of a client machine's PowerShell instance.

#### `>_: Set-FullPermissions.ps1`

A cmdlet that sets administration ownership and adds full permission inheritance to a specified path file or folder. 
By default, the local system administrators group takes ownership and is provided full permissions.

#### `>_: Start-DatabaseSync.ps1`

A Main() script that updates Active Directory user accounts using a MSSQL database single point-of-truth table by passing splatted attributes.

#### `>_: Start-TerminateUserProcess.ps1

A multi-function custom script which aims to automate a specific company's disable user account process.

## License

The repository and all individual scripts are under the [GNU GENERAL PUBLIC LICENSE](https://www.gnu.org/licenses/gpl.txt)

## Usage

The default computer-level module path is: "$Env:windir\System32\WindowsPowerShell\v1.0\Modules"

## Script Style Guide

* Avoid Write-Host **at all costs**. PowerShell functions/cmdlets are not command-line utilities! Pull requests containing code that uses Write-Host will not be considered. You should output custom objects instead. For more information on creating custom objects, read these articles:
   * <http://blogs.technet.com/b/heyscriptingguy/archive/2011/05/19/create-custom-objects-in-your-powershell-script.aspx>
   * <http://technet.microsoft.com/en-us/library/ff730946.aspx>
