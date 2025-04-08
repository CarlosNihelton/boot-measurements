
$ccData = @"
#cloud-config
users:
- name: u
  gecos: U
  groups: [adm, dialout, cdrom, floppy, sudo, audio, dip, video, plugdev, netdev]
  sudo: ALL=(ALL) NOPASSWD:ALL
  shell: /bin/bash
write_files:
- path: /etc/bash.bashrc
  append: true
  content: systemd-analyze blame; systemd-analyze critical-chain; systemd-analyze plot > /mnt/d/Benchmarks/first-critical-chain/plot.svg; exit
"@

$release = "Ubuntu-24.04"
Out-File -Encoding UTF8 -FilePath "$env:UserProfile\.cloud-init\$release.user-data" -InputObject $ccData

for ($i = 1; $i -le 40; $i++) {
    wsl --shutdown
    Start-Sleep -Seconds 3
    wsl --unregister $release
    wsl --install --from-file "D:/ubuntu-24.04.2-wsl-amd64.wsl" --no-launch
    $output = wsl -d $release
    Add-Content -Path "D:\Benchmarks\first-critical-chain.txt" -Value "=== FIRST BOOT $i ==="
    Add-Content -Path "D:\Benchmarks\first-critical-chain.txt" -Value $output
    Move-Item -Path "D:\Benchmarks\first-critical-chain\plot.svg" -Destination "D:\Benchmarks\first-critical-chain\$i.svg"
}
