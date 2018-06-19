[CmdletBinding()]	 
Param
(
[Parameter( Mandatory=$False,
            ValueFromPipeline=$True,
            Position=0)]
    [ValidateScript( {[System.IO.Directory]::Exists($_)})]
             $Root = [System.IO.DirectoryInfo]::new(<# "UPDATE ROOT FILE LOCATION" #>),

[Parameter( Mandatory=$False,
            ValueFromPipeline=$True,
            Position=1)]
             $Directories = [System.IO.Directory]::GetDirectories($Root),

[Parameter( Mandatory=$False,
            ValueFromPipeline=$True,
            Position=2)]
            [System.String]
             $Parent <# = "UPDATE PARENT FOLDER NAME HERE" #>,

[Parameter( Mandatory=$False,
            ValueFromPipeline=$True,
            Position=2)]
            [System.String[]]$Children = @(<# "ADD CHILD HERE", "AND HERE", "AND EVEN HERE" #>),
[Parameter( Mandatory=$True,
            ValueFromPipeline=$False,
            Position=3)]
            [System.String]$Group
)

PROCESS
{
    foreach ($Directory in $Directories)
    {
        try {
              [array]$TargetParents += Resolve-Path -Path (Join-Path -Path $Directory -ChildPath $Parent) -ErrorAction SilentlyContinue
              
        }

        catch { [System.IO.DirectoryNotFoundException]::new($_) }
    }

    foreach ($Parent in $TargetParents)
    {
        foreach ($Child in $Children)
        {
            try { 
              [array]$TargetChildren += Resolve-Path -Path (Join-Path -Path $Parent -ChildPath $Child) -ErrorAction SilentlyContinue
            }

            catch { [System.IO.DirectoryNotFoundException]::new($_) }

        }
    }
}

END
{
    foreach ($Child in $TargetChildren)
    {                                                       # OI = Object inheritance
                                                            # CI = Container Inheritence 
                                                            # M  = Modify
                                                            #/T  = Recursive
     ##icacls.exe $($Child.ProviderPath) /grant ($Group + ':(OI)(CI)(M)') /T  ##Comment/Uncomment as needed
    }
                           # Log the affected directories
    return $TargetChildren | Out-File $PSScriptRoot\ICACLS_Directories.log
}