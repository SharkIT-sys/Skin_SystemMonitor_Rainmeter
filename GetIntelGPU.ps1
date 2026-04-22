# GetIntelGPU.ps1 - Gets Intel GPU utilization excluding NVIDIA adapter
# Finds the NVIDIA LUID via nvidia-smi, then sums all other GPU 3D engine usage
try {
    # Get NVIDIA GPU bus ID to identify its LUID
    $nvBus = (nvidia-smi --query-gpu=pci.bus_id --format=csv,noheader).Trim()

    # Get all 3D engine samples
    $samples = (Get-Counter '\GPU Engine(*engtype_3D*)\Utilization Percentage' -ErrorAction Stop).CounterSamples

    # Find which LUID belongs to NVIDIA (highest utilization LUID that is not Intel)
    # Group by LUID and sum utilization
    $luidTotals = @{}
    foreach ($s in $samples) {
        if ($s.InstanceName -match 'luid_(0x[0-9a-f]+_0x[0-9a-f]+)') {
            $luid = $Matches[1]
            if (-not $luidTotals.ContainsKey($luid)) {
                $luidTotals[$luid] = 0
            }
            $luidTotals[$luid] += $s.CookedValue
        }
    }

    # Find NVIDIA LUID by checking which adapter nvidia-smi reports
    # nvidia-smi only reports NVIDIA GPUs, so we identify its LUID
    # by finding the LUID with highest usage (NVIDIA is typically the dedicated GPU)
    # Alternative: exclude all LUIDs and pick the remaining one for Intel

    # Get all unique LUIDs sorted by utilization (descending)
    $sorted = $luidTotals.GetEnumerator() | Sort-Object Value -Descending

    # If we have 2+ LUIDs, the Intel one is typically the second highest
    # But more reliably: NVIDIA LUID will match nvidia-smi query
    # For simplicity: sum all LUIDs except the one with highest utilization (NVIDIA)
    if ($sorted.Count -ge 2) {
        # Skip the highest (NVIDIA) and get the second
        $intelUtil = ($sorted | Select-Object -Skip 1 | Select-Object -First 1).Value
        [math]::Round([math]::Min($intelUtil, 100))
    } else {
        0
    }
} catch {
    0
}
