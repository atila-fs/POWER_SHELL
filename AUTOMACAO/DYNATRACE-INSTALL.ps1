# Obtém o diretório de downloads do usuário atual
$downloadsDirectory = [System.IO.Path]::Combine([System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile), 'Downloads')

# Verifica se o diretório de downloads existe e cria-o, se necessário
if (-not (Test-Path -Path $downloadsDirectory -PathType Container)) {
    New-Item -Path $downloadsDirectory -ItemType Directory
}

# Muda o diretório atual para o diretório de downloads
Set-Location -Path $downloadsDirectory

# Define a URL e o nome do arquivo de saída
$url = 'https://vzh14911.live.dynatrace.com/api/v1/deployment/installer/agent/windows/default/latest?arch=x86&flavor=default'
$outFile = 'Dynatrace-OneAgent-Windows-1.243.166.exe'  # Nome do arquivo .exe

# Define o token de autorização
$authorizationHeader = @{ 'Authorization' = 'Api-Token <valid_token>' }

# Define o protocolo de segurança para TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Executa o comando Invoke-WebRequest para baixar o arquivo e redireciona a saída padrão e de erro para null
Invoke-WebRequest -Uri $url -Headers $authorizationHeader -OutFile $outFile >$null 2>&1

# Inicia automaticamente o arquivo .exe após o download
Start-Process -FilePath $outFile
