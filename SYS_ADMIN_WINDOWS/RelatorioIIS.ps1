# Importa o módulo necessário para gerenciar IIS localmente
Import-Module WebAdministration

# Lista com os nomes dos servidores IIS a serem comparados
$servers = @(
    "SERVER01"
)

# Caminho do diretório e nome do arquivo de saída
$outputDir = "C:\IISAppPoolsExport"
$outputXLSX = Join-Path $outputDir "Relatorio_Divergencias_AppPools.xlsx"

# Cria o diretório de exportação, se não existir
if (-not (Test-Path -Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

# Função para coletar informações de Application Pools de um servidor remoto
function Get-AppPoolData {
    param ([string]$server)

    Invoke-Command -ComputerName $server -ScriptBlock {
        Import-Module WebAdministration

        $apps = @{}
        $paths = @{}

        Get-ChildItem IIS:\Sites | ForEach-Object {
            $site = $_
            Get-ChildItem "IIS:\Sites\$($site.Name)" | ForEach-Object {
                $app = $_
                $poolName = $app.applicationPool

                # Só processa se poolName não for null ou vazio
                if (-not [string]::IsNullOrEmpty($poolName)) {
                    $physicalPath = $app.physicalPath
                    if (-not $physicalPath) { $physicalPath = "" }

                    if ($apps.ContainsKey($poolName)) {
                        $apps[$poolName]++
                        if ([string]::IsNullOrEmpty($paths[$poolName])) {
                            $paths[$poolName] = $physicalPath
                        } else {
                            $paths[$poolName] += ", " + $physicalPath
                        }
                    } else {
                        $apps[$poolName] = 1
                        $paths[$poolName] = $physicalPath
                    }
                }
            }
        }

        Get-ChildItem IIS:\AppPools | ForEach-Object {
            $appPoolName = $_.Name
            $appCount = if ($apps.ContainsKey($appPoolName)) { $apps[$appPoolName] } else { 0 }
            $physicalPaths = if ($paths.ContainsKey($appPoolName)) { $paths[$appPoolName] } else { "" }

            [PSCustomObject]@{
                Server                     = $env:COMPUTERNAME
                AppPool                    = $appPoolName
                ApplicationsCount          = $appCount
                PhysicalPaths              = $physicalPaths
                State                      = $_.State
                ManagedRuntimeVersion      = $_.ManagedRuntimeVersion
                AutoStart                  = $_.AutoStart
                StartMode                  = $_.StartMode
                QueueLength                = $_.QueueLength
                CPUAction                  = $_.CPU.Action
                CPULimit                   = $_.CPU.Limit
                CPUResetInterval           = $_.CPU.ResetInterval
                ProcessModelIdentityType   = $_.ProcessModel.IdentityType
                Enable32BitApplications    = $_.Enable32BitAppOnWin64
                MaxProcesses               = $_.ProcessModel.MaxProcesses
                RecyclingTimeLimit         = $_.Recycling.PeriodicRestart.Time
                RegularTimeIntervalMinutes = $_.Recycling.PeriodicRestart.Time.TotalMinutes
            }
        }
    }
}

$appPoolsPorServidor = @{}

foreach ($srv in $servers) {
    $appPoolsPorServidor[$srv] = Get-AppPoolData -server $srv
}

$allAppPools = $appPoolsPorServidor.Values | ForEach-Object { $_.AppPool } | Sort-Object -Unique

$props = @(
    'State', 'ManagedRuntimeVersion', 'AutoStart', 'StartMode', 'QueueLength',
    'CPUAction', 'CPULimit', 'CPUResetInterval', 'ProcessModelIdentityType',
    'Enable32BitApplications', 'MaxProcesses', 'RecyclingTimeLimit', 'RegularTimeIntervalMinutes',
    'ApplicationsCount', 'PhysicalPaths'
)

$relatorioFinal = @()

foreach ($appPool in $allAppPools) {
    $dadosAppPool = @{}
    foreach ($srv in $servers) {
        $dados = $appPoolsPorServidor[$srv] | Where-Object { $_.AppPool -eq $appPool }
        $dadosAppPool[$srv] = $dados
    }

    foreach ($srv in $servers) {
        if (-not $dadosAppPool[$srv]) {
            $obj = [ordered]@{
                AppPool     = $appPool
                Propriedade = "App Pool Inexistente"
                Status      = "❌ Ausente em $srv"
            }
            foreach ($s in $servers) {
                $obj["Valor $s"] = if ($s -eq $srv) { "❌ Não Existe" } else { if ($dadosAppPool[$s]) { "✅ Existe" } else { "❌ Não Existe" } }
            }
            $relatorioFinal += [PSCustomObject]$obj
        }
    }

    $servidoresComAppPool = $dadosAppPool.Keys | Where-Object { $dadosAppPool[$_] }
    if ($servidoresComAppPool.Count -ge 2) {
        foreach ($prop in $props) {
            $valores = @{}
            foreach ($srv in $servidoresComAppPool) {
                $valores[$srv] = $dadosAppPool[$srv].$prop
            }

            $valoresUnicos = $valores.Values | Select-Object -Unique
            $divergente = ($valoresUnicos.Count -gt 1)

            $obj = [ordered]@{
                AppPool     = $appPool
                Propriedade = $prop
                Status      = if ($divergente) { "❌ Valor Divergente" } else { "✅ OK" }
            }

            foreach ($srv in $servers) {
                if ($valores.ContainsKey($srv)) {
                    $val = $valores[$srv]
                    $obj["Valor $srv"] = if ($divergente) { "❌ $val" } else { "✅ $val" }
                } else {
                    $obj["Valor $srv"] = "❌ Não Existe"
                }
            }

            $relatorioFinal += [PSCustomObject]$obj
        }
    }
}

# Exporta para Excel com cores e formatação
$excelParams = @{
    Path          = $outputXLSX
    WorksheetName = "DivergenciasAppPools"
    AutoSize      = $true
    TableName     = "RelatorioAppPools"
    BoldTopRow    = $true
    FreezeTopRow  = $true
    FreezePane    = "2"
    Show          = $false
}

$relatorioFinal | Export-Excel @excelParams

$excelPackage = Open-ExcelPackage -Path $outputXLSX
$ws = $excelPackage.Workbook.Worksheets["DivergenciasAppPools"]

$lastRow = $ws.Dimension.End.Row
$lastCol = $ws.Dimension.End.Column
$range = $ws.Cells["A2"].Resize($lastRow - 1, $lastCol)

Set-ExcelRange -Range $range -ConditionalFormat {
    $_.Text -like "*❌*"
} -BackgroundColor Red -FontColor White

Set-ExcelRange -Range $range -ConditionalFormat {
    $_.Text -like "*✅*"
} -BackgroundColor LightGreen -FontColor Black

Close-ExcelPackage $excelPackage

Write-Host "✅ Relatório Excel com cores salvo em: $outputXLSX" -ForegroundColor Green
