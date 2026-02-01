# Carrega o módulo de clusters
Import-Module FailoverClusters

# Obtém todos os grupos de cluster do tipo VirtualMachine
$clusterVMGroups = Get-ClusterGroup | Where-Object { $_.GroupType -eq 'VirtualMachine' }

# Lista de VMs com dados relevantes
$vmInfo = foreach ($group in $clusterVMGroups) {
    # O nome da VM geralmente é igual ao nome do grupo
    $vmName = $group.Name
    $ownerNode = $group.OwnerNode.Name

    # Tenta obter o estado real da VM via Hyper-V
    $vmState = $null
    try {
        $vm = Get-VM -Name $vmName -ErrorAction Stop
        $vmState = $vm.State
        $hostNode = $vm.ComputerName
    } catch {
        $vmState = "Desconhecido"
        $hostNode = "Não encontrado"
    }

    [PSCustomObject]@{
        ClusterNode = $ownerNode
        VMName      = $vmName
        VMState     = $vmState
        HostNode    = $hostNode
    }
}

# Exporta para CSV
$vmInfo | Export-Csv -Path "C:\Temp\ClusterVMs.csv" -NoTypeInformation -Encoding UTF8

Write-Host "Exportação concluída para C:\Temp\ClusterVMs.csv" -ForegroundColor Green
