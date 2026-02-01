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

Write-Log "`n===== VERIFICAÇÃO E AJUSTE DE PRELOAD/STARTMODE (IIS) =====`n"

$psPath = "MACHINE/WEBROOT/APPHOST"
$sites = Get-Website

foreach ($site in $sites) {
    $siteName = $site.Name
    $appPool = $site.ApplicationPool

    Write-Log "▶️ Site: $siteName"

    # Garante que existe a aplicação raiz "/"
    $appRootFilter = "system.applicationHost/sites/site[@name='$siteName']/application[@path='/']"
    $existingRoot = Get-WebConfiguration -pspath $psPath -Filter $appRootFilter

    if (-not $existingRoot) {
        New-WebApplication -Site $siteName -Name "/" -PhysicalPath $site.physicalPath -ApplicationPool $appPool | Out-Null
        Write-Log "   ➕ Criado application path='/' para o site."
    }

    # Verifica se já está com preloadEnabled = true
    $preloadRoot = (Get-WebConfigurationProperty -pspath $psPath -Filter $appRootFilter -Name "preloadEnabled").Value

    if (-not $preloadRoot) {
        Set-WebConfigurationProperty -pspath $psPath -Filter $appRootFilter -Name "preloadEnabled" -Value "True"
        Write-Log "   ✔️ preloadEnabled = True na raiz do site."
    } else {
        Write-Log "   - preloadEnabled já está habilitado na raiz do site."
    }

    # App Pool
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

        $preload = (Get-WebConfigurationProperty -pspath $psPath -Filter $appFilter -Name "preloadEnabled").Value

        if (-not $preload) {
            Set-WebConfigurationProperty -pspath $psPath -Filter $appFilter -Name "preloadEnabled" -Value "True"
            Write-Log "   🔹 preloadEnabled = True na aplicação '$appPath'"
        } else {
            Write-Log "   - preloadEnabled já está habilitado na aplicação '$appPath'"
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
