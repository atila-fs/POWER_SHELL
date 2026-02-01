# Lista todas as VMs do host local
$allVMs = Get-VM | Select-Object -ExpandProperty Name

# Lista todas as VMs que já estão no cluster
$clusterVMs = Get-ClusterGroup | Where-Object { $_.GroupType -eq "VirtualMachine" } | Select-Object -ExpandProperty Name

# Descobre as VMs que ainda não estão no cluster
$missingVMs = $allVMs | Where-Object { $_ -notin $clusterVMs }

# Adiciona somente as VMs que estão fora do cluster
foreach ($vm in $missingVMs) {
    Write-Host "Adicionando VM '$vm' ao cluster..."
    Add-ClusterVirtualMachineRole -VirtualMachine $vm
}