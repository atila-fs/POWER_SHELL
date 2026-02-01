1º No servidor antigo rodar o seguinte comando via powershell:
& "$env:windir\system32\inetsrv\appcmd.exe" add backup "BackupNovo"

2º No servidor novo rodar o seguinte comando via powershell:
& "$env:windir\system32\inetsrv\appcmd.exe" add backup "AntesDeRestaurar"

3º Ainda no servidor novo ir até o path: C:\Windows\System32\inetsrv\backup e incluir a pasta (BackupNovo) no diretório (OBS: Gerado no passo 1º)

4º Agora por ultimo rodar o seguinte comando no servidor novo:
& "$env:windir\system32\inetsrv\appcmd.exe" restore backup "BackupNovo"