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

foreach ($hasConfig in @($true, $false)) {
    # With or without cloud-config data for cloud-init to pick up.
    if ($hasConfig) {
        New-Item -ItemType Directory -Force -Path $ccDir | Out-Null
        Out-File -Encoding UTF8 -Path "$ccDir\default.user-data" -InputObject $ccData
    }
    else {
        Remove-Item -Path $ccDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    foreach ($release in @("Ubuntu-20.04", "Ubuntu-22.04", "Ubuntu-24.04")) {
        foreach ($enabled in @($true, $false)) {
            if ($enabled) {
                Remove-Item -Path $wslConfig -Recurse -Force -ErrorAction SilentlyContinue
            }
            else {
                Out-File -FilePath $wslConfig -InputObject $kernelCmdConfig
            }
            # After changing .wslconfig file, shutdown the WSL VM.
            wsl --shutdown

            $case = "cloud-init-$enabled-has-config-$hasConfig"
        
            foreach ($operation in @("shutdown", "terminate")) {
                for ($i = 1; $i -le 40; $i++) {
                    wsl "--$operation" $release
                    Start-Sleep -Seconds 3
                    $measurement = Measure-Command { $output = wsl.exe -d $release free -k }

                    # Parse the 'used' memory from the second line
                    $memLine = $output[1].Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)
                    $usedMem = $memLine[2]

                    # Write ticks and used memory to a file
                    $dir = New-Item -Type Directory -Force -Path "D:\Benchmarks\non-first-boot\$release"
                    Add-Content -Path "$dir\$operation-$case.txt" -Value ("Ticks: {0}, Used Memory (KiB): {1}" -f $measurement.Ticks, $usedMem)
                    "Finished round $i for $operation with $release"
                }
            }
        }
    }
}
