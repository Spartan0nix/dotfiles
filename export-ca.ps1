class CertificateAuthority {
    [string]$name

    # Display an exit message and stop the script
    [void]stop() {
        Write-Host "[export-script][info]: Exiting..."
        Exit
    }

    [System.Security.Cryptography.X509Certificates.X509Certificate2[]]Get() {
        $n = $this.name
        $certs = @(Get-ChildItem Cert:\LocalMachine\Root -Recurse | Where-Object { $_.Subject -match "CN=${n}" })
        return $certs
    }

    [void]Export([System.Security.Cryptography.X509Certificates.X509Certificate2]$ca, [string]$file_name) {
        # Get the common name from the certificate
        $friendly_name = $ca.FriendlyName
        # Export the CA certificate
        Write-Host "[export-script][info]: Exporting Authority '${friendly_name}' ..."
        Export-Certificate -Cert $ca -FilePath "${file_name}.cer" -Type CERT | Out-Null

        Write-Host "[export-script][info]: Converting certificate to PEM format."
        # Convert the certificate from DER to PEM
        certutil -encode "${file_name}.cer" "${file_name}.crt" | Out-Null
        # Remove the DER certificate
        Remove-Item -Path "${file_name}.cer"
    }
}

class WslDistro {
    [string]$name
    [string]$version
}

class WslCommandResult {
    [string[]]$Output
    [string[]]$Err
    [string]$Command
    [int]$ExitCode

    [void]CheckForError() {
        $cmd = $this.Command
        if($this.Err -ne "") {
            $err_value = $this.Err
            Write-Host "[export-script][error]: Error when executing '${cmd}'`nReason : ${err_value}"
            Exit
        }

        if($this.ExitCode -ne 0) {
            $out = $this.Output
            $exit_code = $this.ExitCode
            Write-Host "[export-script][error]: Exit code '${exit_code}' returned when executing '${cmd}'"
            Write-Host "[export-script][error]: Printing output for debug`n${out}"
            Exit
        }
    }

    [void]Print() {
        if ($this.Output -eq "") {
            Write-Host "[export-script][info]: No output to print"
            return
        }
        $out = $this.Output
        Write-Host "[export-script][info]: Printing command output`n${out}"
    }
}

class WslInterface {
    [string]$Distro = ""
    [pscredential]$Credentials

    # Display an exit message and stop the script
    [void]stop() {
        Write-Host "[export-script][info]: Exiting..."
        Exit
    }

    # Add credentials to the process if needed
    [System.Diagnostics.ProcessStartInfo]auth([System.Diagnostics.ProcessStartInfo]$ps_info) {
        if($this.Credentials) {
            $ps_info.UserName = $this.Credentials.GetNetworkCredential().UserName
            $ps_info.Password = $this.Credentials.Password
            $ps_info.Domain = $this.Credentials.GetNetworkCredential().Domain
        }
        return $ps_info
    }

    # Return a new process to execute the given command
    [System.Diagnostics.Process]buildProcess([string]$cmd) {
        # Set the configuration for the process
        $process_info = New-Object System.Diagnostics.ProcessStartInfo
        $process_info.FileName = "powershell.exe"
        $process_info.CreateNoWindow = $true
        $process_info.RedirectStandardError = $true 
        $process_info.RedirectStandardOutput = $true 
        $process_info.UseShellExecute = $false
        $process_info.Arguments = $cmd
        $process_info = $this.auth($process_info)

        # Generate a new process
        $process = New-Object System.Diagnostics.Process 
        $process.StartInfo = $process_info

        return $process
    }

    # Run the given process and return a new WslCommandResult instance
    [WslCommandResult]runProcess([System.Diagnostics.Process]$ps) {
            # Run the process
            [void]$ps.Start() 
            # Wait for an exit signal
            $ps.WaitForExit()
            
            # Retrieve stdout and stderr
            $out = $ps.StandardOutput.ReadToEnd()
            $err = $ps.StandardError.ReadToEnd()

            # Close the process
            $ps.Close()

            # Build a new WslCommandResult instance
            $res = [WslCommandResult]::new()
            $res.Output = $out
            $res.Err = $err
            $res.Command = $ps.StartInfo.Arguments
            $res.ExitCode = $ps.ExitCode

            return $res
    }
    
    # Execute the command passed
    [WslCommandResult]Exec([string]$command, [string]$root) {
        $cmd = "wsl"
        $d = $this.Distro

        if($root -eq $true) {
            $cmd += " -u root"
        }

        if($d -ne "") {
            $cmd += " -d ${d}"
        }

        $cmd += " -- ${command}"

        try {
            $ps = $this.buildProcess($cmd)
            $res = $this.runProcess($ps)

            return $res            
        }
        catch {
            $res = [WslCommandResult]::new()
            $res.Err = $_

            return $res
        }
    }
    
    # Retrieve a list of the available WLS distros in given user context
    [WslDistro[]]GetDistro() {
        $cmd = @"
`$entries = Get-ChildItem HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss 
foreach(`$entry in `$entries) { 
    `$name = (`$entry | Get-ItemProperty -Name DistributionName).DistributionName 
    `$version = (`$entry | Get-ItemProperty -Name Version).Version 
    Write-Host `"`${name}:`${version}`"
}
"@
        $distros = @()
        try {
            $ps = $this.buildProcess($cmd)
            $out = $this.runProcess($ps)

            $out.CheckForError()
            $out.CheckForError()
    
            $rows = $out.Output.Split("`n")
            foreach ($row in $rows) {
                $name = $row.Split(":")[0]
                if($name -eq "") {
                    continue
                }
                
                $version = $row.Split(":")[1]

                $d = [WslDistro]::new()
                $d.name = $name
                $d.version = $version

                $distros += $d
            }             
        }
        catch {
            $err = $_
            Write-Host "[export-script][error]: Error when retrieving WSL available distros.`nReason : ${err}"
        }

        return $distros  
    }

    # Create a directory
    [WslCommandResult]CreateDir([string]$path, [bool]$root = $false) {
        return $this.Exec("mkdir -p ${path}", $root)
    }

    # Copy a local file inside wsl to the given path
    [WslCommandResult]CopyLocal([string]$local_path, [string]$remote_path, [bool]$overwrite, [bool]$root) {
        $cmd += "cp"

        if($overwrite -eq $true) {
            $cmd += " -f "
        }

        $cmd += " ${local_path} ${remote_path}"
        return $this.Exec($cmd, $root)
    }

    # Update the apt repositories
    [WslCommandResult]UpdatePackageSourceList() {
        return $this.Exec("apt-get update", $true)
    }
    
    # Upgrade the system
    [WslCommandResult]UpgradeSystem() {
        return $this.Exec("apt-get upgrade -y", $true)
    }
    
    # Install packages with apt
    [WslCommandResult]InstallPackage([string[]]$packages) {
        return $this.Exec("apt-get install -y ${packages}", $true)
    }
}

function main() {
    $CURRENT_PATH = (Get-Location)

    do {
        [string]$CA_NAME = Read-Host -Prompt "[export-script][input]: Enter the name of the Certificate Authority to export "    
    } until ($CA_NAME -match "[A-Za-z0-9]" -and $CA_NAME.Length -gt 4)
    
    $CA_FILE_NAME = [string]::Join('',$CA_NAME.Split("")).ToLower()
    $CAInterface = [CertificateAuthority]::new()
    $CAInterface.name = $CA_NAME

    $certs = $CAInterface.Get()
    if(!$certs) {
        Write-Host "[export-script][info]: No certificate authority found for the given name '${CA_NAME}'."
        $CAInterface.stop()
    }

    # $cert = $CAInterface.SelectFromList($certs)
    if($certs.Length -gt 1) {
        Write-Host "[export-script][info]: More than one certificate found for the given name"

        # Display the subject for each certificate
        for ($i = 0; $i -lt $certs.Length; $i++) {
            $ca_info = ("`n`t-- Subject : " + $certs[$i].Subject)
            $ca_info += ("`n`t-- Key size : " + $certs[$i].PublicKey.Key.KeySize)

            $public_key = $certs[$i].PublicKey.Key
            if ($public_key) {
                $ca_info += ("`n`t-- Key Algorithm : " + $certs[$i].PublicKey.Key.SignatureAlgorithm.Split("#")[1])
            } else {
                $ca_info += ("`n`t-- Key Algorithm : ")
            }

            $ca_info += ("`n`t-- Expiration date : " + $certs[$i].GetExpirationDateString())
            Write-Host "(${i}) : ${ca_info}"
        }

        do {
            [int]$cert_index = Read-Host -Prompt "[export-script][input]: Select a the Certificate Authority from the given list (enter the number matching the row, Ex : 0)"
        } until ($cert_index -match "[0-9]" -and $cert_index -lt $certs.Length)

        $cert = $certs[$cert_index]
    }

    # Check if certificate was already exported
    if(Get-ChildItem -Path $CURRENT_PATH -Name "${CA_FILE_NAME}.crt") {
        $overwrite = Read-Host -Prompt "[export-script][info]: Certificate for Authority '${CA_NAME}' already exist. Would you like to skip the export step ? (Y) yes : (N) no [default] "
  
        if ($overwrite -match '(y|Y|yes)') {
            $CAInterface.Export($cert, $CA_FILE_NAME)
        } else {
            Write-Host "[export-script][info]: Skipping certificate export step."
        }
    } else {
        $CAInterface.Export($cert, $CA_FILE_NAME)
    }

    # =======================================
    # WSL Interactions
    # =======================================
    $wsl = [WslInterface]::new()
	Write-Host "[export-script][info]: Running wsl as user ?"
    $cred = Get-Credential -Credential ""
    $wsl.Credentials = $cred

    $distros = $wsl.GetDistro()
    Write-Host "[export-script][info]: List of available WSL distros"
    for ($i = 0; $i -lt $distros.Length; $i++) {
        $distro_info = "`n`t-- Name : " + $distros[$i].name
        $distro_info += "`n`t-- Version : " + + $distros[$i].version
        Write-Host "(${i}) : ${distro_info}"
    }

    do {
        [int]$distro_index = Read-Host -Prompt "[export-script][input]: Select a distro from the given list (enter the number matching the row, Ex : 0)"
    } until ($distro_index -match "[0-9]" -and $distro_index -lt $distros.Length)

    $wsl.Distro = $distros[$distro_index].name

    # Create the directory to store the certificates
    $res = $wsl.CreateDir("/usr/local/share/ca-certificates/${CA_FILE_NAME}", $true)
    $res.CheckForError()

    # Copy the certificate
    $res = $wsl.CopyLocal("./${CA_FILE_NAME}.crt", "/usr/local/share/ca-certificates/${CA_FILE_NAME}", $true, $true)
    $res.CheckForError()

    # update packages
    $res = $wsl.UpdatePackageSourceList()
    $res.CheckForError()
    $res.Print()

    # Upgrade system
    # $res = $wsl.UpgradeSystem()
    # $res.CheckForError()
    # $res.Print()
    
    # Install ca-certificates packages and load custom AC
    $res = $wsl.InstallPackage(@("ca-certificates", "openssl"))
    $res.CheckForError()
    $res.Print()
    
    $res = $wsl.Exec("sudo update-ca-certificates", $true)
    $res.CheckForError()
    $res.Print()

    # Add configuration for python-pip
    # Create the directory for the config file
    $res = $wsl.CreateDir("~/.pip", $false)
    $res.CheckForError()
	
	# Create the directory for the root config file
    $res = $wsl.CreateDir("/root/.pip", $true)
    $res.CheckForError()

    # Prepare the config
    $pip_conf = @"
[global]
cert = /usr/local/share/ca-certificates/${CA_FILE_NAME}/${CA_FILE_NAME}.crt
"@

    # Create the config file
    Add-Content -Path "./pip.conf" -Value $pip_conf

    # Copy the file
    $res = $wsl.CopyLocal("pip.conf", "~/.pip", $true, $false)
    $res.CheckForError()
	
	# Copy the file to the root home
	$res = $wsl.CopyLocal("pip.conf", "/root/.pip", $true, $true)
	$res.CheckForError()

    # Remove the file
    Remove-Item -Path "./pip.conf"

    # Add configuration for npm
    # Create the config file
    Add-Content -Path "./npmrc" -Value "cafile = `"/usr/local/share/ca-certificates/${CA_FILE_NAME}/${CA_FILE_NAME}.crt`""

    # Copy the file
    $res = $wsl.CopyLocal("npmrc", "~/.npmrc", $true, $false)
    $res.CheckForError()

    # Remove the file
    Remove-Item -Path "./npmrc"
}

main
