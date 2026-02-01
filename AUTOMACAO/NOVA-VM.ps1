param (
    [string]$isoPath,
    [string]$vmPathBase,
    [string]$vmPrefix,
    [int]$vmCount,
    [int]$cpuCount,
    [int]$memoryMB,
    [int]$diskGB
)

for ($i = 1; $i -le $vmCount; $i++) {
    $vmNumber = "{0:D2}" -f $i
    $vmName = "$vmPrefix$vmNumber"
    $vmPath = Join-Path $vmPathBase $vmName
    $vhdPath = Join-Path $vmPath "$vmName.vhdx"

    Write-Host "Criando VM: $vmName"

    # Cria diretório da VM
    New-Item -ItemType Directory -Path $vmPath -Force | Out-Null

    # Cria disco VHDX
    $sizeBytes = $diskGB * 1GB
    New-VHD -Path $vhdPath -SizeBytes $sizeBytes -Dynamic | Out-Null

    # Cria a VM
    $memoryBytes = $memoryMB * 1MB
    New-VM -Name $vmName `
           -Generation 2 `
           -MemoryStartupBytes $memoryBytes `
           -VHDPath $vhdPath `
           -Path $vmPath | Out-Null

    # ISO como mídia de boot
    Add-VMDvdDrive -VMName $vmName -Path $isoPath | Out-Null

    # CPUs
    Set-VMProcessor -VMName $vmName -Count $cpuCount | Out-Null

    # Cluster
    Add-ClusterVirtualMachineRole -VirtualMachine $vmName | Out-Null

    Write-Host "VM '$vmName' criada e adicionada ao cluster."
}

Write-Host "Todas as VMs foram criadas com sucesso!" -ForegroundColor Cyan