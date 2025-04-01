$release = "Ubuntu-24.04"
foreach ($operation in @("shutdown", "terminate") ) {
    for ($i = 1; $i -le 30; $i++) {
        wsl "--$operation" $release
        Start-Sleep -Seconds 1
        $output = wsl -d $release
        Add-Content -Path "D:\Benchmarks\$operation-blame-chain.txt" -Value "=== BOOT $i FOR OPERATION $operation ==="
        Add-Content -Path "D:\Benchmarks\$operation-blame-chain.txt" -Value $output
        Move-Item -Path "D:\Benchmarks\critical-chain\plot.svg" -Destination "D:\Benchmarks\critical-chain\$operation-$i.svg"
    }
}