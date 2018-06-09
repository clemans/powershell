$wmiParams = @{
    ApplicationName = "WinRM/Config/Listener"

    SelectorSet     = @{Address = "*"; Transport="HTTPS"}

    ValueSet        = @{Hostname = 
                             [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties() | 
                             % {"{0}.{1}" -f $_.Hostname,$_.DomainName};

                        CertificateThumbprint = 
                             (Get-ChildItem -Path "Cert:\LocalMachine\My\")[-1].ThumbPrint
                       }
              }

New-WSManInstance @wmiParams

