$ccDir = "$env:UserProfile\.cloud-init"
$ccData = @"
#cloud-config
users:
- name: u
  gecos: U
  groups: [adm, dialout, cdrom, floppy, sudo, audio, dip, video, plugdev, netdev]
  sudo: ALL=(ALL) NOPASSWD:ALL
  shell: /bin/bash
"@

$wslConfig = "$env:UserProfile\.wslconfig"
$kernelCmdConfig = @"
[wsl2]
kernelCommandLine=cloud-init=disabled
"@

$releases = @{
    "Ubuntu-20.04" = @{
        # Starts a shell after the first boot experience
        LaunchCmd   = "ubuntu2004.exe";
        # Only registers the distro instance without doing any custom provisioning.
        RegisterCmd = "ubuntu2004.exe install --root";
    };
    "Ubuntu-22.04" = @{
        # Starts a shell after the first boot experience
        LaunchCmd   = "ubuntu2204.exe";
        # Only registers the distro instance without doing any custom provisioning.
        RegisterCmd = "ubuntu2204.exe install --root";
    };
    "Ubuntu-24.04" = @{
        # Starts a shell after the first boot experience
        LaunchCmd   = "wsl -d Ubuntu-24.04";
        # Only registers the distro instance without doing any custom provisioning.
        RegisterCmd = "wsl --install -d Ubuntu-24.04";
    };
}

foreach ($hasConfig in @($false, $true)) {
    # With or without cloud-config data for cloud-init to pick up.
    if ($hasConfig) {
        New-Item -ItemType Directory -Force -Path $ccDir  | Out-Null
        Out-File -Encoding UTF8 -FilePath "$ccDir\default.user-data" -InputObject $ccData
    }
    else {
        Remove-Item -Path $ccDir -Force -Recurse -ErrorAction SilentlyContinue
    }

    foreach ($release in @("Ubuntu-24.04", "Ubuntu-22.04")) {
        # Enable or disable cloud-init via kernel command line.
        foreach ($enabled in @($false, $true)) {
            if ($enabled) {
                Remove-Item -Path $wslConfig -Force -Recurse -ErrorAction SilentlyContinue
            }
            else {
                Out-File -FilePath $wslConfig -InputObject $kernelCmdConfig
            }

            $case = "cloud-init-$enabled-has-config-$hasConfig"
            $register = $releases[$release].RegisterCmd
            $launch = $releases[$release].LaunchCmd

            for ($i = 1; $i -le 30; $i++) {
                # Always shutdown and let it breathe in hopes to prevent wslservice.exe crashes.
                # Also required if we change .wslconfig.
                wsl --shutdown
                Start-Sleep -Seconds 3
                wsl --unregister $release
                # Registers a new instance. We don't want to measure that part, as it's outside of our control besides the image size.
                Invoke-Expression $register
                # Inject a system-wide bashrc that runs `free -k` and exits. Let's trust wsl's filesystem feature to do a soft startup.
                Add-Content -Path "\\wsl.localhost\$release\etc\bash.bashrc" -Value "free -k; exit" -NoNewline
                # Prevent prompting for user creation
                wsl -d $release adduser --quiet --gecos '' "test-user" --disabled-password
                wsl --terminate $release
                # Starts the shell after running the first boot experience.
                $measurement = Measure-Command { $output = Invoke-Expression $launch }

                # Parse the 'used' memory from the second line
                $memLine = $output[-2].Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)
                $usedMem = $memLine[2]

                # Write ticks and used memory to a file
                $dir = New-Item -Type Directory -Force -Path "d:\Benchmarks\first-boot\$release"
                Add-Content -Path "$dir\$case.txt" -Value ("Ticks: {0}, Used Memory (KiB): {1}" -f $measurement.Ticks, $usedMem)
                "Finished round $i for $release"
            }
        }
    }    
}
