# Lista de servidores onde aplicar
$servidores = @("SERVER01", "SERVER02", "SERVER03", "SERVER04", "SERVER05", "SERVER06", "SERVER07")

# Lista dos sites principais
$sites = @(
    "Site1", "Site2", "Site3", "Site4",
    "Site5", "Site6", "Site7", "Site8",
    "Site9", "Site10", "Site11", "Site12"
)

# Caminho da pasta de logs
$logFolderPath = "C:\Log Ajuste IIS"
if (-not (Test-Path $logFolderPath)) {
    New-Item -ItemType Directory -Path $logFolderPath
}

foreach ($servidor in $servidores) {
    $logFilePath = "$logFolderPath\$servidor-log.txt"
    Write-Host "`n🔧 Conectando a $servidor e registrando logs em: $logFilePath"
    $logContent = "Log de Ajuste IIS - $servidor - Data: $(Get-Date)`r`n"

    Invoke-Command -ComputerName $servidor -ScriptBlock {
        param($sites, $logContent)

        Import-Module WebAdministration

        # Ajustar padrão para novos App Pools
        Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' `
            -filter "system.applicationHost/applicationPools/applicationPoolDefaults" `
            -name "startMode" -value "AlwaysRunning"
        $logContent += "✔️ Padrão de App Pools ajustado para AlwaysRunning.`r`n"

        # Ajustar todos os App Pools existentes
        Get-ChildItem IIS:\AppPools | ForEach-Object {
            $_.startMode = "AlwaysRunning"
            $_ | Set-Item
            $logContent += "✔️ App Pool '$($_.Name)' atualizado.`r`n"
        }

        # Para cada site:
        foreach ($siteName in $sites) {
            $sitePath = "IIS:\Sites\$siteName"
            if (Test-Path $sitePath) {
                # Ativar preload no nível do site
                Set-ItemProperty $sitePath -Name applicationDefaults.preloadEnabled -Value $true
                Restart-WebItem $sitePath
                $logContent += "✔️ Site '$siteName' configurado com preloadEnabled = true e reiniciado.`r`n"

                # Validação site
                $current = Get-ItemProperty $sitePath -Name applicationDefaults.preloadEnabled
                $logContent += if ($current.preloadEnabled -eq $true) {
                    "✅ Validação: preloadEnabled ATIVO no site '$siteName'.`r`n"
                } else {
                    "⚠️ Validação falhou no site '$siteName'.`r`n"
                }

                # Obter subaplicações do site (ex: /api, /painel, etc)
                $apps = Get-WebApplication -Site $siteName
                foreach ($app in $apps) {
                    $appPath = $app.Path
                    $filter = "system.applicationHost/sites/site[@name='$siteName']/application[@path='$appPath']"

                    Set-WebConfigurationProperty -Filter $filter `
                        -Name preloadEnabled -Value $true

                    $logContent += "✔️ Subaplicação '$appPath' em '$siteName' configurada com preloadEnabled = true.`r`n"
                }
            } else {
                $logContent += "❌ Site '$siteName' não encontrado.`r`n"
            }
        }

        # Salvar log no disco
        $logFilePath = "C:\Log Ajuste IIS\$env:COMPUTERNAME-log.txt"
        $logContent | Out-File -FilePath $logFilePath -Append -Encoding UTF8

    } -ArgumentList $sites, $logContent -ErrorAction Stop
}
