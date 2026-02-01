# Baixando o agente Zabbix2
$downloadPath = "$env:USERPROFILE\Downloads"
Write-Host "Baixando o agente Zabbix2 para $downloadPath..."
$msiUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/6.0/6.0.21/zabbix_agent-6.0.21-windows-amd64-openssl.msi"
$msiPath = "$downloadPath\zabbix_agent.msi"
Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath

# Verificando se o arquivo MSI foi baixado corretamente
if (Test-Path $msiPath) {
    Write-Host "Arquivo MSI baixado com sucesso."

    # Inicia o arquivo MSI para instalação
    Start-Process -FilePath $msiPath
} else {
    Write-Host "Falha ao baixar o arquivo MSI."
}
