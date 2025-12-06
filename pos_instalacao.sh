#!/bin/bash
# Script de Pós-Instalação Completo - Ubuntu 24.04 LTS
# Autor: Glaucion
# Data: Dezembro 2025
# Uso: sudo bash pos_instalacao.sh

# --- Variáveis de Configuração ---
USERNAME="glaucion"
HOMEDIR="/home/$USERNAME"
LOGFILE="$HOMEDIR/pos-inst.log"
# AJUSTE: Mude este caminho para onde você copiar ou montar seus arquivos .deb
DEB_SOURCE_DIR="$HOMEDIR/extras" 

echo "### Pós-instalação iniciada: $(date)" | tee "$LOGFILE"

# --- 0. Checagem Inicial ---
if [[ $EUID -ne 0 ]]; then
   echo "ERRO: Este script deve ser executado com 'sudo' ou como root."
   exit 1
fi
echo "Usuário alvo: $USERNAME" | tee -a "$LOGFILE"

# --- 1. Atualização e Instalação de Pacotes Base (APT) ---
echo "--- 1. Atualizando sistema e instalando pacotes base (APT) ---" | tee -a "$LOGFILE"

# Atualização e Upgrade
apt update && apt -y upgrade | tee -a "$LOGFILE"

# Lista de pacotes
PACKAGES=(
  curl wget vim git htop tmux unzip build-essential net-tools nmap iperf3
  traceroute mtr bridge-utils vlan wireshark tcpdump openssh-server python3-pip
  virtualbox gparted flameshot openvpn wireguard docker.io docker-compose
  qemu-kvm libvirt-daemon-system libvirt-clients virt-manager nodejs npm kitty
  ansible ubuntu-restricted-extras # Adicionado codecs e drivers
)

# Instalação dos pacotes
apt install -y "${PACKAGES[@]}" | tee -a "$LOGFILE"

# --- 2. Instalação de Snaps ---
echo "--- 2. Instalando Snaps ---" | tee -a "$LOGFILE"
snap install spotify --channel=stable | tee -a "$LOGFILE"

# --- 3. Instalação de Pacotes .deb Extras ---
echo "--- 3. Instalando pacotes DEB extras do diretório $DEB_SOURCE_DIR ---" | tee -a "$LOGFILE"

# Verifica se a pasta existe e contém arquivos .deb
if [ -d "$DEB_SOURCE_DIR" ] && find "$DEB_SOURCE_DIR" -maxdepth 1 -name "*.deb" -print -quit 2>/dev/null; then
    echo "Instalando pacotes .deb..." | tee -a "$LOGFILE"
    
    # 1. Instalação inicial dos pacotes
    dpkg -i "$DEB_SOURCE_DIR"/*.deb || true | tee -a "$LOGFILE"
    
    # 2. Correção de dependências
    apt --fix-broken install -y | tee -a "$LOGFILE"
    
    echo "Instalação de pacotes .deb extras concluída." | tee -a "$LOGFILE"
else
    echo "AVISO: Diretório $DEB_SOURCE_DIR não encontrado ou vazio. Pulando esta etapa." | tee -a "$LOGFILE"
fi

# --- 4. Comandos de Configuração e Instalações Específicas ---
echo "--- 4. Executando comandos de configuração e instalações de terceiros ---" | tee -a "$LOGFILE"

# Adiciona usuário a grupos essenciais
usermod -aG wireshark,docker,libvirt,kvm "$USERNAME" | tee -a "$LOGFILE"

# Ativar TRIM SSD
systemctl enable fstrim.timer | tee -a "$LOGFILE"
systemctl start fstrim.timer

# Google Chrome
echo "Instalando Google Chrome..." | tee -a "$LOGFILE"
wget -qO /usr/share/keyrings/google-linux-signing-key.gpg https://dl.google.com/linux/linux_signing_key.pub 
echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/google-linux-signing-key.gpg] http://dl.google.com/linux/chrome/deb/ stable main' > /etc/apt/sources.list.d/google-chrome.list
apt update | tee -a "$LOGFILE"
apt install -y google-chrome-stable | tee -a "$LOGFILE"

# VS Code
echo "Instalando VS Code..." | tee -a "$LOGFILE"
wget -qO /usr/share/keyrings/vscode-archive-keyring.gpg https://packages.microsoft.com/keys/microsoft.asc
echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/vscode-archive-keyring.gpg] https://packages.microsoft.com/repos/code stable main' > /etc/apt/sources.list.d/vscode.list
apt update | tee -a "$LOGFILE"
apt install -y code | tee -a "$LOGFILE"

# Terraform
echo "Instalando Terraform (v1.7.7)..." | tee -a "$LOGFILE"
wget -O /tmp/terraform.zip https://releases.hashicorp.com/terraform/1.7.7/terraform_1.7.7_linux_amd64.zip | tee -a "$LOGFILE"
unzip -o /tmp/terraform.zip -d /usr/local/bin | tee -a "$LOGFILE" # '-o' para sobrescrever
rm /tmp/terraform.zip

# KVM, bridges e libvirt
echo "Configurando KVM/Libvirt..." | tee -a "$LOGFILE"
systemctl enable libvirtd | tee -a "$LOGFILE"
systemctl start libvirtd
# Habilita e inicia a rede 'default' (se não estiver ativa)
virsh net-start default || true | tee -a "$LOGFILE"
virsh net-autostart default || true | tee -a "$LOGFILE"

# Criação de workspace e permissões
echo "Criando diretório Workspace..." | tee -a "$LOGFILE"
mkdir -p "$HOMEDIR/Workspace" | tee -a "$LOGFILE"
chown -R "$USERNAME:$USERNAME" "$HOMEDIR" | tee -a "$LOGFILE"

# --- 5. Finalização e Reboot ---
echo "--- 5. Finalização e Limpeza ---" | tee -a "$LOGFILE"
apt autoremove -y | tee -a "$LOGFILE"
apt clean | tee -a "$LOGFILE"

echo "### Pós-instalação finalizada. Necessário REINICIAR para aplicar permissões de grupo (docker, libvirt, wireshark)." | tee -a "$LOGFILE"
echo "### Log completo disponível em $LOGFILE"

# Pergunta se deseja reiniciar
read -p "Deseja reiniciar o sistema agora para aplicar todas as mudanças (S/n)? " choice
choice=${choice:-S} # 'S' é o default
case "$choice" in
  s|S ) reboot;;
  * ) echo "Reinicie o sistema manualmente em breve.";;
esac
