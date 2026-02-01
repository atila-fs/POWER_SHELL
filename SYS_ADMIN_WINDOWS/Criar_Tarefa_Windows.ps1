# ==========================
# CONFIGURAÇÕES
# ==========================
$Username      = "<Usuário>"
$UserPassword  = "<Senha>"
$TaskName      = "<Nome_Tarefa>"

$WorkingDir    = "<Caminho_Tarefa>"
$TaskExe       = "<Nome_EXE>"
$TaskArguments = "<Argumentos>"

$ScheduleTime  = "<Hora>"
$ScheduleDate  = "<Data>"

# ==========================
# CONVERTENDO PARA ISO 8601
# ==========================
$DateObj = Get-Date "$ScheduleDate $ScheduleTime"
$StartBoundary = $DateObj.ToString("yyyy-MM-ddTHH:mm:ss")

# ==========================
# CRIAR TAREFA VIA COM API
# ==========================
$service = New-Object -ComObject "Schedule.Service"
$service.Connect()

$rootFolder = $service.GetFolder("\")
$task = $service.NewTask(0)

# --- Registration Info ---
$regInfo = $task.RegistrationInfo
$regInfo.Description = "Executa o <Nome_Tarefa> com argumentos."

# --- Trigger ---
$trigger = $task.Triggers.Create(1)  # 1 = EXECUTA UMA VEZ
$trigger.StartBoundary = $StartBoundary
$trigger.Enabled = $true

# --- Action ---
$action = $task.Actions.Create(0)    # 0 = EXEC
$action.Path = "$TaskExe"
$action.Arguments = "$TaskArguments"
$action.WorkingDirectory = "$WorkingDir"

# --- Principal ---
$principal = $task.Principal
$principal.UserId = $Username
$principal.LogonType = 1  # PASSWORD
$principal.RunLevel = 1   # NORMAL USER

# --- Settings ---
$settings = $task.Settings
$settings.Enabled = $true
$settings.AllowDemandStart = $true
$settings.DisallowStartIfOnBatteries = $false

# --- Registrar ---
$rootFolder.RegisterTaskDefinition(
    $TaskName,
    $task,
    6,               # CREATE OR UPDATE
    $Username,
    $UserPassword,
    1
) | Out-Null

Write-Host "✔ Tarefa criada com EXE + argumentos + Iniciar Em"