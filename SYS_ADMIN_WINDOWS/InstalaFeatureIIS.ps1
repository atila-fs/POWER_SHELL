# Script para instalar Roles e Features no Windows Server

# Lista de features a serem instaladas
$features = @(
    # Web Server (IIS)
    "Web-Server",
    "Web-Common-Http",          # Common HTTP Features
    "Web-Default-Doc",          # Default Document
    "Web-Dir-Browsing",         # Directory Browsing
    "Web-Http-Errors",          # HTTP Errors
    "Web-Static-Content",       # Static Content
    "Web-Http-Redirect",        # HTTP Redirection
    "Web-Http-Logging",         # HTTP Logging
    "Web-Request-Monitor",      # Request Monitor
    "Web-Stat-Compression",     # Static Content Compression
    "Web-Filtering",            # Request Filtering
    "Web-Net-Ext45",            # .NET Extensibility 4.6
    "Web-Asp-Net45",            # ASP.NET 4.6
    "Web-ISAPI-Ext",            # ISAPI Extensions
    "Web-ISAPI-Filter",         # ISAPI Filters
    "Web-Mgmt-Console",         # IIS Management Console
    "Web-Mgmt-Service",         # IIS Management Scripts and Tools (script-based management)

    # File and Storage Services
    "FS-FileServer",            # File Server
    "FS-DFS-Namespace",         # DFS Namespaces
    "FS-DFS-Replication",       # DFS Replication

    # Storage Services
    "Storage-Services",

    # .NET Framework
    "NET-Framework-45-Core",    # .NET Framework 4.6
    "NET-Framework-45-ASPNET",  # ASP.NET 4.6
    "NET-WCF-TCP-PortSharing45",# WCF TCP Port Sharing

    # Failover Clustering
    "Failover-Clustering",

    # Remote Server Administration Tools
    "RSAT",

    # Telnet Client
    "Telnet-Client",

    # WoW64 Support (em sistemas Server Core)
    "WoW64-Support"
)

Write-Host "Instalando roles e features selecionadas..." -ForegroundColor Cyan

foreach ($feature in $features) {
    $result = Get-WindowsFeature -Name $feature
    if ($result -and -not $result.Installed) {
        Write-Host "Instalando: $($result.Name) - $($result.DisplayName)"
        Install-WindowsFeature -Name $feature -IncludeManagementTools -ErrorAction SilentlyContinue
    } else {
        Write-Host "Já instalado: $($result.Name) - $($result.DisplayName)" -ForegroundColor Yellow
    }
}

Write-Host "`nInstalação concluída." -ForegroundColor Green
