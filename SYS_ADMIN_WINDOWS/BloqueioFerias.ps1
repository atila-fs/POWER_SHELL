Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Criar o formulário principal
$form = New-Object System.Windows.Forms.Form
$form.Text = "Agendamento de Férias - Active Directory"
$form.Size = New-Object System.Drawing.Size(600, 400)
$form.StartPosition = "CenterScreen"
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)

# Grupo - Agendamento de Férias
$groupBox = New-Object System.Windows.Forms.GroupBox
$groupBox.Text = "Agendar Bloqueio e Desbloqueio Automático"
$groupBox.Size = New-Object System.Drawing.Size(560, 280)
$groupBox.Location = New-Object System.Drawing.Point(10, 20)
$form.Controls.Add($groupBox)

# Rótulo e textbox - Login do usuário
$lblUser = New-Object System.Windows.Forms.Label
$lblUser.Text = "Login do Usuário:"
$lblUser.Location = New-Object System.Drawing.Point(20, 40)
$lblUser.Size = New-Object System.Drawing.Size(140, 30)
$groupBox.Controls.Add($lblUser)

$txtUser = New-Object System.Windows.Forms.TextBox
$txtUser.Location = New-Object System.Drawing.Point(170, 40)
$txtUser.Size = New-Object System.Drawing.Size(360, 30)
$groupBox.Controls.Add($txtUser)

# Rótulo e DateTimePicker - Data de Início
$lblStart = New-Object System.Windows.Forms.Label
$lblStart.Text = "Início das Férias:"
$lblStart.Location = New-Object System.Drawing.Point(20, 90)
$lblStart.Size = New-Object System.Drawing.Size(140, 30)
$groupBox.Controls.Add($lblStart)

$dtStart = New-Object System.Windows.Forms.DateTimePicker
$dtStart.Location = New-Object System.Drawing.Point(170, 90)
$dtStart.Size = New-Object System.Drawing.Size(250, 30)
$dtStart.Format = 'Custom'
$dtStart.CustomFormat = "dd/MM/yyyy HH:mm"
$groupBox.Controls.Add($dtStart)

# Rótulo e DateTimePicker - Data de Fim
$lblEnd = New-Object System.Windows.Forms.Label
$lblEnd.Text = "Fim das Férias:"
$lblEnd.Location = New-Object System.Drawing.Point(20, 140)
$lblEnd.Size = New-Object System.Drawing.Size(140, 30)
$groupBox.Controls.Add($lblEnd)

$dtEnd = New-Object System.Windows.Forms.DateTimePicker
$dtEnd.Location = New-Object System.Drawing.Point(170, 140)
$dtEnd.Size = New-Object System.Drawing.Size(250, 30)
$dtEnd.Format = 'Custom'
$dtEnd.CustomFormat = "dd/MM/yyyy HH:mm"
$groupBox.Controls.Add($dtEnd)

# Botão Agendar
$btnAgendar = New-Object System.Windows.Forms.Button
$btnAgendar.Text = "Agendar"
$btnAgendar.Size = New-Object System.Drawing.Size(180, 50)
$btnAgendar.Location = New-Object System.Drawing.Point(190, 200)
$groupBox.Controls.Add($btnAgendar)

# Lógica do agendamento
$btnAgendar.Add_Click({
    $usuario = $txtUser.Text
    $dataInicio = $dtStart.Value
    $dataFim = $dtEnd.Value

    if (-not $usuario) {
        [System.Windows.Forms.MessageBox]::Show("Informe o login do usuário.")
        return
    }

    if ($dataFim -le $dataInicio) {
        [System.Windows.Forms.MessageBox]::Show("A data de fim deve ser posterior à de início.")
        return
    }

    $scriptBlock = @"
`$usuario = '$usuario'
`$dataInicio = [datetime]'$($dataInicio.ToString("yyyy-MM-dd HH:mm:ss"))'
`$dataFim = [datetime]'$($dataFim.ToString("yyyy-MM-dd HH:mm:ss"))'

Start-Sleep -Seconds ([int]((`$dataInicio - (Get-Date)).TotalSeconds))
Disable-ADAccount -Identity `$usuario

Start-Sleep -Seconds ([int]((`$dataFim - `$dataInicio).TotalSeconds))
Enable-ADAccount -Identity `$usuario
"@

    $taskScriptPath = "$env:TEMP\BloquearFerias_$usuario.ps1"
    $scriptBlock | Out-File -FilePath $taskScriptPath -Encoding UTF8

    $taskName = "AgendamentoFérias_$usuario"

    # Cria tarefa agendada
    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-ExecutionPolicy Bypass -File `"$taskScriptPath`""
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(10)
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -RunLevel Highest -Force

    [System.Windows.Forms.MessageBox]::Show("Agendamento criado com sucesso.")
})

$form.ShowDialog()
