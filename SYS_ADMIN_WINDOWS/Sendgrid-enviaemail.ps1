# Coleta o nome do computador
$ComputerName = $env:COMPUTERNAME

# Configurações do servidor SMTP (SendGrid)
$SMTPServer   = "smtp.sendgrid.net"
$SMTPPort     = 587
$SMTPUser     = "apikey"  # Não altere — padrão para autenticação via API Key no SendGrid
$SMTPPassword = "<API_KEY>"

# Inicialização do cliente SMTP
$SMTPClient = New-Object Net.Mail.SmtpClient($SMTPServer, $SMTPPort)
$SMTPClient.EnableSsl = $false  # Use true se o servidor exigir SSL
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($SMTPUser, $SMTPPassword)

# Endereço de e-mail do remetente e destinatário
$EmailFrom = "<Email_Remetente>"
$EmailTo   = "<Email_Destinatário>"

# Dados da mensagem (essas variáveis devem estar definidas em outro lugar no script)
# $JOBNAME, $RESULT, $ERRORS, $SYNCOK, $ALLARGS devem ser definidos anteriormente
$Subject = "Job Name: $JOBNAME, $RESULT, Errors: $ERRORS, Synced: $SYNCOK"
$Body    = "$ALLARGS"

# Envia o e-mail
$SMTPClient.Send($EmailFrom, $EmailTo, $Subject, $Body)
