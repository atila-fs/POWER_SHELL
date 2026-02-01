# Requer execução como Administrador

Write-Host "== Aplicando melhorias de performance no IIS ==" -ForegroundColor Cyan

# 1. Instalar Application Initialization Module
Write-Host "`n[1/5] Instalando Application Initialization Module..."
Import-Module ServerManager
Add-WindowsFeature Web-AppInit

# 2. Ativar preload para sites existentes
Write-Host "`n[2/5] Ativando preloadEnabled para sites existentes..."
Import-Module WebAdministration

Get-Website | ForEach-Object {
    $siteName = $_.Name
    Set-ItemProperty "IIS:\Sites\$siteName" -Name applicationDefaults.preloadEnabled -Value $true
    Write-Host "→ preloadEnabled ativado para $siteName"
}

# 3. Habilitar Dynamic Compression para JSON/XML
Write-Host "`n[3/5] Habilitando compressão dinâmica para tipos JSON e XML..."
Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/httpCompression/dynamicTypes" -name "." -value @{mimeType='application/json'; enabled='true'}
Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/httpCompression/dynamicTypes" -name "." -value @{mimeType='application/xml'; enabled='true'}

# Ativar o módulo de compressão dinâmica (caso ainda não esteja ativo)
Enable-WebRequestMonitoring
Install-WindowsFeature Web-Dyn-Compression

# 4. Ajustar prioridade do processo w3wp.exe manualmente (não pode forçar via script enquanto IIS estiver rodando)
Write-Host "`n[4/5] Para ajustar a prioridade do processo w3wp.exe:"
Write-Host "    Use o Gerenciador de Tarefas ou execute o seguinte comando após o pool iniciar:"
Write-Host '    Get-Process w3wp | ForEach-Object { $_.PriorityClass = "AboveNormal" }'

# 5. Desativar Nagle Algorithm (registro)
Write-Host "`n[5/5] Desabilitando Nagle Algorithm..."
$interfaces = Get-NetTCPConnection | Select-Object -First 1 | Select-Object -ExpandProperty LocalAddress
$interfaceKey = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" | Where-Object {
    (Get-ItemProperty $_.PSPath).IPAddress -contains $interfaces
}

if ($interfaceKey) {
    Set-ItemProperty -Path $interfaceKey.PSPath -Name TcpAckFrequency -Value 1 -Type DWord
    Set-ItemProperty -Path $interfaceKey.PSPath -Name TCPNoDelay -Value 1 -Type DWord
    Write-Host "→ Nagle desativado para interface: $($interfaceKey.PSChildName)"
} else {
    Write-Host "⚠️ Não foi possível identificar a interface de rede corretamente."
}

# 6. Instrução para Cache de Resultados
Write-Host "`nℹ️ Para cache de resultados:"
Write-Host "→ Use MemoryCache (ASP.NET) ou configure Redis/local caching conforme o framework da sua API."
Write-Host "→ Não é configurado diretamente via IIS, mas sim no código da aplicação."

Write-Host "`n✅ Script concluído. Algumas alterações requerem reinicialização do IIS ou reinício do servidor."
