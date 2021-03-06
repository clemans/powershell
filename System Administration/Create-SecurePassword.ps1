param (
[Parameter( Mandatory=$true,
            Position=0,
            ValueFromPipeline=$false)]
            [securestring]
    $Password = (Read-Host -AsSecureString -Prompt "Input password" |  ConvertTo-SecureString -AsPlainText -Force)
)

$Password | ConvertFrom-SecureString | Out-File $PSScriptRoot\.password.dat
