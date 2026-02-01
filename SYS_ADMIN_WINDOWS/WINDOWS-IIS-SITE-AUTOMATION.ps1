Import-Module WebAdministration

# Nome do site e diretório
$siteName = "SECURE"
$sitePath = "C:\inetpub\wwwroot\$siteName"
$port = 443

# Lista de domínios
$bindings = @(
    "<Dominio>",
    "<Dominio>",
    "<Dominio>"
)

# Thumbprint fixo do certificado (sem espaços e em minúsculo, como netsh exige)
$certThumbprint = "<Thumbprint>"

# Criar diretório do site
if (!(Test-Path $sitePath)) {
    New-Item -Path $sitePath -ItemType Directory
    Write-Host "Diretório $sitePath criado."
} else {
    Write-Host "Diretório $sitePath já existe."
}

# Criar Application Pool
if (!(Test-Path "IIS:\AppPools\$siteName")) {
    New-WebAppPool -Name $siteName
    Write-Host "Application Pool '$siteName' criado."
} else {
    Write-Host "Application Pool '$siteName' já existe."
}

# Verificar se o site já existe
if (Get-Website -Name $siteName -ErrorAction SilentlyContinue) {
    Write-Host "O site $siteName já existe. Abortando criação."
    return
}

# Criar o site com binding temporário (porta 1 para evitar conflito com http)
New-Website -Name $siteName -PhysicalPath $sitePath -ApplicationPool $siteName -Port 1
Write-Host "Site $siteName criado com binding temporário."

# Remover binding temporário
Remove-WebBinding -Name $siteName -Protocol http -Port 1

# Adicionar bindings HTTPS com SNI e associar certificado
foreach ($hostHeader in $bindings) {
    New-WebBinding -Name $siteName -Protocol https -Port $port -HostHeader $hostHeader -SslFlags 1
    Write-Host "Binding criado para $hostHeader"

    & netsh http add sslcert hostnameport="${hostHeader}:${port}" `
        certhash=$certThumbprint certstorename=MY `
        appid='{00112233-4455-6677-8899-AABBCCDDEEFF}' | Out-Null

    Write-Host "Certificado com Thumbprint $certThumbprint associado a $hostHeader"
}
