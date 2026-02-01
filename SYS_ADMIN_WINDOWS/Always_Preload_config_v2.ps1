Import-Module WebAdministration

$logDir = "C:\Logs"
If (!(Test-Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory | Out-Null
}
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile = Join-Path $logDir "IIS-Preload-Status-$timestamp.txt"

function Write-Log {
    param ([string]$message)
    Write-Host $message
    Add-Content -Path $logFile -Value $message
}

Write-Log "`n===== AJUSTE DE PRELOAD EM WEBSITES RAIZ E APLICAÇÕES =====`n"

$psPath = "MACHINE/WEBROOT/APPHOST"
$sites = Get-Website

foreach ($site in $sites) {
    $siteName = $site.Name
    $appPool = $site.ApplicationPool

    Write-Log "▶️ Site: $siteName"

    # Verifica se já existe um application path="/" (raiz)
    $appRootFilter = "system.applicationHost/sites/site[@name='$siteName']/application[@path='/']"
    $existingRoot = Get-WebConfiguration -pspath $psPath -Filter $appRootFilter

    if (-not $existingRoot) {
        # Cria application raiz se não existir
        New-WebApplication -Site $siteName -Name "/" -PhysicalPath $site.physicalPath -ApplicationPool $appPool | Out-Null
        Write-Log "   ➕ Criado application path='/' para o site."
    }

    # Agora define preloadEnabled = True na raiz
    try {
        Set-WebConfigurationProperty -pspath $psPath -Filter $appRootFilter -Name "preloadEnabled" -Value "True" -ErrorAction Stop
        Write-Log "   ✔️ preloadEnabled = True na raiz do site."
    } catch {
        Write-Log "   ❌ ERRO ao definir preloadEnabled na raiz: $_"
    }

    # Define startMode do App Pool
    $appPoolPath = "IIS:\AppPools\$appPool"
    if (Test-Path $appPoolPath) {
        $mode = (Get-Item $appPoolPath).startMode
        if ($mode -ne "AlwaysRunning") {
            Set-ItemProperty -Path $appPoolPath -Name startMode -Value "AlwaysRunning"
            Write-Log "   ✔️ AppPool '$appPool' definido como AlwaysRunning"
        } else {
            Write-Log "   - AppPool '$appPool' já está como AlwaysRunning"
        }
    }

    # Aplicações convertidas
    $apps = Get-WebApplication -Site $siteName
    foreach ($app in $apps) {
        $appPath = $app.Path
        $appAppPool = $app.ApplicationPool
        $appFilter = "system.applicationHost/sites/site[@name='$siteName']/application[@path='$appPath']"

        try {
            Set-WebConfigurationProperty -pspath $psPath -Filter $appFilter -Name "preloadEnabled" -Value "True"
            Write-Log "   🔹 preloadEnabled = True na aplicação '$appPath'"
        } catch {
            Write-Log "   ❌ ERRO ao definir preload na aplicação '$appPath': $_"
        }

        # Pool das aplicações
        $appAppPoolPath = "IIS:\AppPools\$appAppPool"
        if (Test-Path $appAppPoolPath) {
            $mode = (Get-Item $appAppPoolPath).startMode
            if ($mode -ne "AlwaysRunning") {
                Set-ItemProperty -Path $appAppPoolPath -Name startMode -Value "AlwaysRunning"
                Write-Log "      ✔️ AppPool '$appAppPool' definido como AlwaysRunning"
            } else {
                Write-Log "      - AppPool '$appAppPool' já está como AlwaysRunning"
            }
        }
    }

    Write-Log ""
}

Write-Log "`n✅ Finalizado. Log salvo em: $logFile"
