# Define a data limite: logs mais antigos que 7 dias atrás serão excluídos
$dataLimite = (Get-Date).AddDays(-7)

# Loop pelos diretórios W3SVC1 até W3SVC16
1..16 | ForEach-Object {
    # Monta o caminho da pasta de logs correspondente ao número atual do loop
    $caminho = "C:\inetpub\logs\W3SVC$_"

    # Verifica se a pasta existe
    if (Test-Path $caminho) {
        # Exibe qual diretório está sendo verificado
        Write-Output "Verificando: $caminho"
        
        # Busca todos os arquivos .log dentro do diretório e subdiretórios
        Get-ChildItem -Path $caminho -Filter *.log -File -Recurse | Where-Object {
            # Filtra apenas os arquivos cuja data de última modificação é menor que a data limite
            $_.LastWriteTime -lt $dataLimite
        } | ForEach-Object {
            # Exibe o caminho completo do arquivo que será excluído
            Write-Output "Excluindo: $($_.FullName)"
            
            # Exclui o arquivo
            Remove-Item $_.FullName -Force
        }
    } else {
        # Informa que o diretório não foi encontrado (pode não existir para todos os números)
        Write-Output "Diretório não encontrado: $caminho"
    }
}
