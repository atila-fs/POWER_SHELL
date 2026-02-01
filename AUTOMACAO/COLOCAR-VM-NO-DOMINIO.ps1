# Criar objeto de credencial programaticamente
$Senha = ConvertTo-SecureString '<senha>' -AsPlainText -Force
$Credencial = New-Object System.Management.Automation.PSCredential ("administrator", $Senha)

$configFile = "C:\ClusterStorage\Volume1\Automacao\VMConfig.csv"
$DomainName = "safewebpsc.local"        # Nome do domínio

# Credenciais de administrador do domínio
$DomainCredential = Get-Credential

# Lê as configurações das VMs a partir de um arquivo CSV
$vmConfigs = Import-Csv -Path $configFile

foreach ($config in $vmConfigs) {
    $vmName = $config.VMName

    Invoke-Command -VMName $vmName -Credential $Credencial -ScriptBlock {
        Write-Host "------------------------------------------------------------------"
        
        # Capturar o nome antigo do computador
        $AntigoNome = hostname
        Write-Host "Antigo nome: $AntigoNome"

        # Alterar o nome do computador
        Rename-Computer -NewName $using:vmName -Force -PassThru -DomainCredential $using:DomainCredential
        Write-Host "O nome do computador foi alterado para: $using:vmName"

        # Adicionar ao domínio (opcional, atualmente comentado)
        # Add-Computer -DomainName $using:DomainName -Credential $using:DomainCredential -Force -PassThru
        # Write-Host "O computador foi adicionado ao domínio $using:DomainName com sucesso."

        # Reiniciar para aplicar as mudanças
        Restart-Computer -Force
    }
}