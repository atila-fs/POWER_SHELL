Add-Type -AssemblyName System.Windows.Forms
Import-Module ActiveDirectory

# Nome do grupo de segurança no AD
$securityGroupName = "<Grupo_Segurança>"

# Obter o usuário atual
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$userName = $currentUser.Name

# Se o nome de usuário está no formato "DOMAIN\username", pegar somente a parte "username"
$userName = $userName.Split('\')[1]

# Tentar pegar o usuário no AD
try {
    # Usando Get-ADUser com o nome do usuário
    $user = Get-ADUser -Identity $userName -Properties MemberOf

    # Verificar se o usuário está no grupo de segurança
    $isMember = $false

    foreach ($group in $user.MemberOf) {
        if ($group -like "*$securityGroupName*") {
            $isMember = $true
            break
        }
    }

    if (-not $isMember) {
        [System.Windows.Forms.MessageBox]::Show("Você não tem permissão para executar este script. Acesso negado.")
        exit
    }
} catch {
    [System.Windows.Forms.MessageBox]::Show("Erro ao buscar informações do usuário no Active Directory. Verifique o nome do usuário ou suas permissões.")
    exit
}

# Criar formulário
$form = New-Object System.Windows.Forms.Form
$form.Text = "Gerenciador de Usuários - AD"
$form.Size = New-Object System.Drawing.Size(850, 1080)
$form.StartPosition = "CenterScreen"
$form.Font = New-Object System.Drawing.Font("Segoe UI", 11)

# Título
$lblTitulo = New-Object System.Windows.Forms.Label
$lblTitulo.Text = "Gerenciador de Usuários do Active Directory"
$lblTitulo.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$lblTitulo.AutoSize = $true
$lblTitulo.Location = New-Object System.Drawing.Point(220, 10)
$form.Controls.Add($lblTitulo)

# GroupBox - Criar Usuário
$grpCreate = New-Object System.Windows.Forms.GroupBox
$grpCreate.Text = "Criar Novo Usuário"
$grpCreate.Size = New-Object System.Drawing.Size(800, 480)
$grpCreate.Location = New-Object System.Drawing.Point(20, 50)
$form.Controls.Add($grpCreate)

function Add-LabelTextboxPair($group, $labelText, [ref]$textboxRef, $top) {
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $labelText
    $label.Location = New-Object System.Drawing.Point(10, $top)
    $label.Size = New-Object System.Drawing.Size(180, 25)
    $group.Controls.Add($label)

    $textbox = New-Object System.Windows.Forms.TextBox
    $textbox.Location = New-Object System.Drawing.Point(200, $top)
    $textbox.Size = New-Object System.Drawing.Size(580, 25)
    $group.Controls.Add($textbox)

    $textboxRef.Value = $textbox
}

$null = Add-LabelTextboxPair $grpCreate "Nome:" ([ref]$txtFirstName) 30
$null = Add-LabelTextboxPair $grpCreate "Sobrenome:" ([ref]$txtLastName) 70
$null = Add-LabelTextboxPair $grpCreate "Login:" ([ref]$txtUsername) 110
$null = Add-LabelTextboxPair $grpCreate "E-mail:" ([ref]$txtEmail) 150
$null = Add-LabelTextboxPair $grpCreate "Senha Inicial:" ([ref]$txtPassword) 190
$txtPassword.UseSystemPasswordChar = $true

# Campo de seleção de OU
$lblOU = New-Object System.Windows.Forms.Label
$lblOU.Text = "Departamento:"
$lblOU.Location = New-Object System.Drawing.Point(10, 230)
$lblOU.Size = New-Object System.Drawing.Size(180, 25)
$grpCreate.Controls.Add($lblOU)

$cbOU = New-Object System.Windows.Forms.ComboBox
$cbOU.Location = New-Object System.Drawing.Point(200, 230)
$cbOU.Size = New-Object System.Drawing.Size(580, 25)
$cbOU.DropDownStyle = 'DropDownList'

# Mapeamento de OUs visíveis x caminho real
$ouMap = @{
<Incluir_OUs_Aqui>
}

# Preencher o ComboBox com os departamentos (OUs)
$cbOU.Items.AddRange($ouMap.Keys)

$grpCreate.Controls.Add($cbOU)

# Botão Criar Usuário
$btnCreate = New-Object System.Windows.Forms.Button
$btnCreate.Text = "Criar Usuário"
$btnCreate.Size = New-Object System.Drawing.Size(200, 50)
$btnCreate.Location = New-Object System.Drawing.Point(580, 280)
$btnCreate.Add_Click({
    $firstName = $txtFirstName.Text
    $lastName = $txtLastName.Text
    $username = $txtUsername.Text
    $email = $txtEmail.Text
    $password = $txtPassword.Text
    $selectedOUName = $cbOU.SelectedItem

    if ($firstName -and $lastName -and $username -and $email -and $password -and $selectedOUName) {
        try {
            $ouDN = $ouMap[$selectedOUName]
            $displayName = "$firstName $lastName"
            New-ADUser -Name $displayName -GivenName $firstName -Surname $lastName -SamAccountName $username -UserPrincipalName $email -EmailAddress $email -DisplayName $displayName -Path $ouDN -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) -Enabled $true -ChangePasswordAtLogon $true
            [System.Windows.Forms.MessageBox]::Show("Usuário '$username' criado com sucesso na OU '$selectedOUName'.")
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Erro: $_")
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Preencha todos os campos e selecione uma OU.")
    }
})
$grpCreate.Controls.Add($btnCreate)

# GroupBox - Gerenciar Conta
$grpManage = New-Object System.Windows.Forms.GroupBox
$grpManage.Text = "Gerenciar Conta"
$grpManage.Size = New-Object System.Drawing.Size(800, 200)
$grpManage.Location = New-Object System.Drawing.Point(20, 540)
$form.Controls.Add($grpManage)

$lblManageUser = New-Object System.Windows.Forms.Label
$lblManageUser.Text = "Usuário (Login):"
$lblManageUser.Location = New-Object System.Drawing.Point(10, 30)
$lblManageUser.Size = New-Object System.Drawing.Size(180, 25)
$grpManage.Controls.Add($lblManageUser)

$txtManageUser = New-Object System.Windows.Forms.TextBox
$txtManageUser.Location = New-Object System.Drawing.Point(200, 30)
$txtManageUser.Size = New-Object System.Drawing.Size(580, 25)
$grpManage.Controls.Add($txtManageUser)

$btnBlock = New-Object System.Windows.Forms.Button
$btnBlock.Text = "Desabilitar Conta"
$btnBlock.Size = New-Object System.Drawing.Size(200, 40)
$btnBlock.Location = New-Object System.Drawing.Point(10, 70)
$btnBlock.Add_Click({
    try {
        Disable-ADAccount -Identity $txtManageUser.Text
        [System.Windows.Forms.MessageBox]::Show("Conta '$($txtManageUser.Text)' bloqueada com sucesso.")
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Erro ao bloquear a conta '$($txtManageUser.Text)': $_")
    }
})
$grpManage.Controls.Add($btnBlock)

$btnUnlock = New-Object System.Windows.Forms.Button
$btnUnlock.Text = "Desbloquear Conta"
$btnUnlock.Size = New-Object System.Drawing.Size(200, 40)
$btnUnlock.Location = New-Object System.Drawing.Point(270, 70)
$btnUnlock.Add_Click({
    try {
        Unlock-ADAccount -Identity $txtManageUser.Text
        [System.Windows.Forms.MessageBox]::Show("Conta '$($txtManageUser.Text)' desbloqueada com sucesso.")
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Erro ao desbloquear a conta '$($txtManageUser.Text)': $_")
    }
})
$grpManage.Controls.Add($btnUnlock)

$btnEnable = New-Object System.Windows.Forms.Button
$btnEnable.Text = "Habilitar Conta"
$btnEnable.Size = New-Object System.Drawing.Size(200, 40)
$btnEnable.Location = New-Object System.Drawing.Point(530, 70)
$btnEnable.Add_Click({
    try {
        Enable-ADAccount -Identity $txtManageUser.Text
        [System.Windows.Forms.MessageBox]::Show("Conta '$($txtManageUser.Text)' habilitada com sucesso.")
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Erro ao habilitar a conta '$($txtManageUser.Text)': $_")
    }
})
$grpManage.Controls.Add($btnEnable)

# GroupBox - Redefinir Senha
$grpResetPassword = New-Object System.Windows.Forms.GroupBox
$grpResetPassword.Text = "Redefinir Senha"
$grpResetPassword.Size = New-Object System.Drawing.Size(800, 200)  # Aumentando o tamanho para acomodar melhor os campos
$grpResetPassword.Location = New-Object System.Drawing.Point(20, 760)  # Ajustando a posição para aumentar o espaçamento
$form.Controls.Add($grpResetPassword)

# Adicionando Título e Caixa de Texto para Redefinir Senha
$lblResetUsername = New-Object System.Windows.Forms.Label
$lblResetUsername.Text = "Login do Usuário:"
$lblResetUsername.Location = New-Object System.Drawing.Point(10, 40)
$lblResetUsername.Size = New-Object System.Drawing.Size(180, 25)
$grpResetPassword.Controls.Add($lblResetUsername)

$txtResetUsername = New-Object System.Windows.Forms.TextBox
$txtResetUsername.Location = New-Object System.Drawing.Point(200, 40)
$txtResetUsername.Size = New-Object System.Drawing.Size(580, 25)
$grpResetPassword.Controls.Add($txtResetUsername)

$lblNewPassword = New-Object System.Windows.Forms.Label
$lblNewPassword.Text = "Nova Senha:"
$lblNewPassword.Location = New-Object System.Drawing.Point(10, 80)
$lblNewPassword.Size = New-Object System.Drawing.Size(180, 25)
$grpResetPassword.Controls.Add($lblNewPassword)

$txtNewPassword = New-Object System.Windows.Forms.TextBox
$txtNewPassword.Location = New-Object System.Drawing.Point(200, 80)
$txtNewPassword.Size = New-Object System.Drawing.Size(580, 25)
$txtNewPassword.UseSystemPasswordChar = $true
$grpResetPassword.Controls.Add($txtNewPassword)

# Botão de Redefinir Senha
$btnResetPassword = New-Object System.Windows.Forms.Button
$btnResetPassword.Text = "Redefinir Senha"
$btnResetPassword.Size = New-Object System.Drawing.Size(200, 50)
$btnResetPassword.Location = New-Object System.Drawing.Point(580, 120)
$btnResetPassword.Add_Click({
    $userName = $txtResetUsername.Text
    $newPassword = $txtNewPassword.Text
    if ($userName -and $newPassword) {
        try {
            Set-ADAccountPassword -Identity $userName -NewPassword (ConvertTo-SecureString $newPassword -AsPlainText -Force)
            [System.Windows.Forms.MessageBox]::Show("Senha do usuário '$userName' redefinida com sucesso.")
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Erro ao redefinir a senha: $_")
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Preencha todos os campos de login e nova senha.")
    }
})
$grpResetPassword.Controls.Add($btnResetPassword)



# Exibir o formulário
$form.ShowDialog()
