# Importa o módulo necessário para administrar o IIS via PowerShell
Import-Module WebAdministration

# Define os nomes dos dois servidores IIS que serão comparados
$server1 = "SERVER01"
$server2 = "SERVER02"

# Define o caminho do arquivo onde será salvo o relatório final em CSV
$outputCSV = "C:\IISAppPoolsExport\Relatorio_Divergencias_AppPools.csv"

# Verifica se o diretório de exportação existe. Caso não exista, ele é criado.
if (-not (Test-Path -Path "C:\IISAppPoolsExport")) {
    New-Item -ItemType Directory -Path "C:\IISAppPoolsExport"
}

# Função que coleta os dados de Application Pools de um servidor IIS específico
function Get-AppPoolData {
    param ([string]$server)

    # Executa remotamente no servidor informado
    Invoke-Command -ComputerName $server -ScriptBlock {
        # Importa novamente o módulo IIS (necessário no contexto remoto)
        Import-Module WebAdministration

        # Para cada App Pool encontrado, cria um objeto com suas propriedades principais
        Get-ChildItem IIS:\AppPools | ForEach-Object {
            [PSCustomObject]@{
                Server                     = $env:COMPUTERNAME  # Nome do servidor
                AppPool                    = $_.Name            # Nome do Application Pool
                State                      = $_.State           # Estado atual (Started, Stopped, etc.)
                ManagedRuntimeVersion      = $_.ManagedRuntimeVersion  # Versão do .NET utilizada
                AutoStart                  = $_.AutoStart       # Início automático ativado?
                StartMode                  = $_.StartMode       # Modo de início do pool
                QueueLength                = $_.QueueLength     # Tamanho da fila
                CPUAction                  = $_.CPU.Action      # Ação ao atingir o limite de CPU
                CPULimit                   = $_.CPU.Limit       # Limite de CPU configurado
                CPUResetInterval           = $_.CPU.ResetInterval # Intervalo de reset do contador de CPU
                ProcessModelIdentityType   = $_.ProcessModel.IdentityType # Tipo de identidade usada pelo processo
                Enable32BitApplications    = $_.Enable32BitAppOnWin64     # 32 bits ativado em SO 64 bits?
                MaxProcesses               = $_.ProcessModel.MaxProcesses # Máximo de processos
                RecyclingTimeLimit         = $_.Recycling.PeriodicRestart.Time  # Tempo para reciclagem automática
                RegularTimeIntervalMinutes = $_.Recycling.PeriodicRestart.Time.TotalMinutes  # Mesmo valor acima, convertido em minutos
            }
        }
    }
}

# Coleta os dados de Application Pools dos dois servidores definidos
$data1 = Get-AppPoolData -server $server1
$data2 = Get-AppPoolData -server $server2

# Cria uma lista com todos os nomes únicos de App Pools encontrados nos dois servidores
$allNames = ($data1.AppPool + $data2.AppPool) | Sort-Object -Unique

# Inicia o processo de geração do relatório final com as divergências encontradas
$relatorioFinal = foreach ($appPool in $allNames) {
    # Pega os dados do App Pool específico no servidor 1
    $item1 = $data1 | Where-Object { $_.AppPool -eq $appPool }

    # Pega os dados do App Pool específico no servidor 2
    $item2 = $data2 | Where-Object { $_.AppPool -eq $appPool }

    # Se o App Pool não existir no servidor 1
    if (-not $item1) {
        [PSCustomObject]@{
            AppPool          = $appPool
            Propriedade      = "App Pool Inexistente"
            "Valor $server1" = "Não Existe"
            "Valor $server2" = "Existe"
            Status           = "Ausente em $server1"
        }
    }
    # Se o App Pool não existir no servidor 2
    elseif (-not $item2) {
        [PSCustomObject]@{
            AppPool          = $appPool
            Propriedade      = "App Pool Inexistente"
            "Valor $server1" = "Existe"
            "Valor $server2" = "Não Existe"
            Status           = "Ausente em $server2"
        }
    }
    # Se o App Pool existir nos dois servidores, comparar as propriedades configuradas
    else {
        # Define as propriedades que serão comparadas entre os dois servidores
        $props = @(
            'State','ManagedRuntimeVersion','AutoStart','StartMode','QueueLength',
            'CPUAction','CPULimit','CPUResetInterval','ProcessModelIdentityType',
            'Enable32BitApplications','MaxProcesses','RecyclingTimeLimit','RegularTimeIntervalMinutes'
        )

        # Para cada propriedade, compara os valores nos dois servidores
        foreach ($prop in $props) {
            $val1 = $item1.$prop
            $val2 = $item2.$prop

            # Se os valores forem diferentes, adiciona ao relatório como divergente
            if ($val1 -ne $val2) {
                [PSCustomObject]@{
                    AppPool          = $appPool
                    Propriedade      = $prop
                    "Valor $server1" = $val1
                    "Valor $server2" = $val2
                    Status           = "Valor Divergente"
                }
            }
        }
    }
}

# Exporta o resultado final para um arquivo CSV no caminho definido
$relatorioFinal | Export-Csv -Path $outputCSV -NoTypeInformation -Encoding UTF8

# Informa ao usuário que o relatório foi salvo com sucesso
Write-Host "✔ Relatório de divergências salvo em: $outputCSV" -ForegroundColor Green
