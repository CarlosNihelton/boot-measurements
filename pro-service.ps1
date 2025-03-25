foreach ($version in @("Ubuntu-20.04")) {
    foreach ($operation in @("shutdown", "terminate")) {
        for ($i = 1; $i -le 40; $i++) {
            if ($operation -eq "shutdown") {
                wsl --shutdown
            }
            elseif ($operation -eq "terminate") {
                wsl -t $version
            }
            Start-Sleep -Seconds 3
            $measurement = Measure-Command { $output = wsl.exe -d $version free -k }

            # Parse the 'used' memory from the second line
            $memLine = $output[1].Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)
            $usedMem = $memLine[2]

            # Write ticks and used memory to a file
            $fileName = "F:\source\boot-measurements\pro-service\$version\$version-$operation-no-no.txt"
            Add-Content -Path $fileName -Value ("Ticks: {0}, Used Memory (KiB): {1}" -f $measurement.Ticks, $usedMem)
            "Finished round $i for $operation"
        }
    }
}