# Lista de nomes dos serviços (nome curto ou nome definido na criação)
$servicos = @(
    "<Nome_Serviço>",
    "<Nome_Serviço>",
    "<Nome_Serviço>",
    "<Nome_Serviço>",
    "<Nome_Serviço>",
    "<Nome_Serviço>"
)

foreach ($nome in $servicos) {
    try {
        Set-Service -Name $nome -StartupType Disabled -ErrorAction Stop
        Write-Host "✅ Serviço desativado: $nome"
    } catch {
        Write-Host "❌ Falha ao desativar '$nome': $_"
    }
}
