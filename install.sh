#!/bin/bash
# ===============================
# install.sh - Security Bootstrap
# ===============================

# ---------------------------
# Helpers
# ---------------------------
install_package() {
    local pkg=$1
    echo "[+] Installing package: $pkg..."
    sudo apt-get update -y
    sudo apt-get install -y "$pkg"
}

stop_disable_service() {
    local service=$1
    echo "[+] Stopping and disabling $service..."
    sudo systemctl stop "$service" 2>/dev/null || true
    sudo systemctl disable "$service" 2>/dev/null || true
}

# ---------------------------
# SSH & Authentication
# ---------------------------
generate_ssh_key_and_send() {
    read -p "Enter SSH username: " USERNAME
    read -p "Enter server IP or hostname: " SERVER
    local KEY_PATH="$HOME/.ssh/id_ed25519"

    if [[ ! -f "$KEY_PATH" ]]; then
        echo "[+] Generating new SSH key..."
        ssh-keygen -t ed25519 -C "$USERNAME@$SERVER" -f "$KEY_PATH" -N ""
    else
        echo "[!] SSH key already exists at $KEY_PATH"
    fi

    echo "[+] Sending public key to $SERVER..."
    ssh-copy-id -i "$KEY_PATH.pub" "$USERNAME@$SERVER"
    echo "[✓] Public key installed on server."
}

install_google_authenticator() {
    echo "[+] Installing Google Authenticator PAM module..."
    install_package libpam-google-authenticator

    echo "[+] Configuring PAM for Google Authenticator..."
    sudo grep -qxF "auth required pam_google_authenticator.so nullok" /etc/pam.d/sshd || \
        echo "auth required pam_google_authenticator.so nullok" | sudo tee -a /etc/pam.d/sshd

    sudo sed -i 's/^#*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
    sudo systemctl restart sshd
    echo "[!] Each user should run 'google-authenticator' to setup their secret key."
}

disable_password_ssh_on_server() {
    echo "[!] Disabling password login..."
    local sshd_config="/etc/ssh/sshd_config"
    sudo cp "$sshd_config" "${sshd_config}.bak"

    sudo sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' "$sshd_config"
    sudo sed -i 's/^#*ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' "$sshd_config"
    sudo sed -i 's/^#*UsePAM.*/UsePAM no/' "$sshd_config"
    sudo sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' "$sshd_config"

    sudo systemctl restart ssh || sudo systemctl restart sshd
}

update_ssh_login_policy() {
    local sshd_config="/etc/ssh/sshd_config"
    local backup="${sshd_config}.bak.$(date +%F-%H%M%S)"
    echo "[+] Backing up $sshd_config to $backup"
    sudo cp "$sshd_config" "$backup"

    sudo sed -i 's/^PermitRootLogin .*/PermitRootLogin yes/' "$sshd_config"
    sudo sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' "$sshd_config"
    grep -q '^PermitRootLogin' "$sshd_config" || echo 'PermitRootLogin yes' | sudo tee -a "$sshd_config" > /dev/null
    grep -q '^PasswordAuthentication' "$sshd_config" || echo 'PasswordAuthentication yes' | sudo tee -a "$sshd_config" > /dev/null

    if sshd -t; then
        echo "✔ sshd_config syntax is valid. Restarting SSH..."
        sudo systemctl restart sshd
    else
        echo "❌ sshd_config has syntax errors. Reverting changes."
        sudo mv "$backup" "$sshd_config"
    fi
}

configure_sshd() {
    echo "[+] Hardening sshd_config..."
    sudo tee /etc/ssh/sshd_config > /dev/null <<EOF
Port 22
PermitRootLogin no
PasswordAuthentication no
X11Forwarding no
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
EOF
    sudo systemctl restart ssh
}

configure_ssh_banner() {
    echo "[+] Configuring SSH banner..."
    echo "Authorized access only!" | sudo tee /etc/issue
}

# ---------------------------
# Quality of life configs
# ---------------------------
uncomment_force_color_prompt() {
    sudo sed -i 's/^#\s*\(force_color_prompt=yes\)/\1/' /root/.bashrc
    echo "✔ force_color_prompt enabled"
}

enable_case_insensitive_completion() {
    echo "set completion-ignore-case On" | sudo tee -a /etc/inputrc > /dev/null
    echo "✔ Case-insensitive completion enabled"
}

install_packages() {
    sudo apt update && sudo apt upgrade -y
    mkdir -p ~/.ssh && chmod 700 ~/.ssh
    echo -e "Host 10.200.200.*\n    StrictHostKeyChecking no\n    UserKnownHostsFile /dev/null" >> ~/.ssh/config
    sudo apt install -y sshpass bc rsync bash-completion
}

configure_timeout() {
    echo "[+] Setting shell timeout..."
    sudo tee /etc/profile.d/timeout.sh > /dev/null <<EOF
TMOUT=600
readonly TMOUT
export TMOUT
EOF
}

set_timezone() {
    echo "[+] Setting timezone to Asia/Tehran..."
    sudo timedatectl set-timezone Asia/Tehran
}

# ---------------------------
# Security tools
# ---------------------------
install_fail2ban() {
    install_package fail2ban
    sudo systemctl enable fail2ban
    sudo systemctl start fail2ban
}

configure_fail2ban() {
    echo "[+] Configuring Fail2Ban..."
    sudo tee /etc/fail2ban/jail.local > /dev/null <<EOF
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
bantime = 600
EOF
    sudo systemctl restart fail2ban
}

install_ufw() {
    install_package ufw
    sudo ufw allow ssh
    sudo ufw --force enable
}

install_clamav() {
    install_package clamav
    install_package clamav-daemon
    sudo systemctl enable clamav-daemon
    sudo systemctl start clamav-daemon
}

install_rkhunter() {
    install_package rkhunter
    sudo rkhunter --update
    sudo rkhunter --propupd
}

install_chkrootkit() {
    install_package chkrootkit
}

install_logwatch() {
    install_package logwatch
}

install_auditd() {
    install_package auditd
    sudo systemctl enable auditd
    sudo systemctl start auditd
}

install_apparmor() {
    install_package apparmor
    install_package apparmor-utils
    sudo systemctl enable apparmor
    sudo systemctl start apparmor
}

install_unattended_upgrades() {
    install_package unattended-upgrades
    sudo dpkg-reconfigure -plow unattended-upgrades
}

install_aide() {
    install_package aide
    echo "[+] Initializing AIDE..."
    sudo aideinit || true
}

# ---------------------------
# Network / Database / Proxy
# ---------------------------
configure_iptables() {
    echo "[+] Configuring iptables..."
    sudo tee /etc/iptables/rules.v4 > /dev/null <<EOF
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -p tcp --dport 22 -j ACCEPT
COMMIT
EOF
    sudo iptables-restore < /etc/iptables/rules.v4
}

install_mariadb() {
    install_package mariadb-server
    sudo systemctl enable mariadb
    sudo systemctl start mariadb
}

install_openldap() {
    install_package slapd
    sudo systemctl enable slapd
    sudo systemctl start slapd
}

install_snmp() {
    install_package snmpd
    sudo systemctl enable snmpd
    sudo systemctl start snmpd
}

install_php() {
    install_package php
}

install_squid() {
    install_package squid
    sudo systemctl enable squid
    sudo systemctl start squid
}

install_apache_security() {
    install_package apache2
    install_package libapache2-mod-evasive
    install_package libapache2-mod-security2
    sudo systemctl enable apache2
    sudo systemctl start apache2
    sudo a2enmod evasive
    sudo a2enmod security2
    sudo systemctl restart apache2
    sudo apt-get remove -y nginx || true
}

# ---------------------------
# Hardening
# ---------------------------
harden_permissions() {
    echo "[+] Setting secure permissions..."
    sudo chmod 0644 /etc/passwd
    sudo chmod 0400 /etc/shadow
    sudo chmod 0644 /etc/group
    sudo chmod 0600 /boot/grub/grub.cfg
    sudo chmod 0600 /etc/crontab
    sudo chmod 0600 /etc/ssh/sshd_config
    sudo chmod 0700 /etc/cron.d /etc/cron.* || true
}

harden_sysctl() {
    echo "[+] Applying sysctl kernel hardening..."
    sudo tee -a /etc/sysctl.conf > /dev/null <<EOF
net.ipv4.ip_forward=0
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0
net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.default.accept_source_route=0
kernel.randomize_va_space=2
dev.tty.ldisc_autoload=0
fs.protected_fifos=2
fs.suid_dumpable=0
kernel.kptr_restrict=2
kernel.modules_disabled=1
kernel.sysrq=0
kernel.unprivileged_bpf_disabled=1
net.core.bpf_jit_harden=2
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.all.log_martians=1
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.default.log_martians=1
net.ipv6.conf.all.accept_redirects=0
net.ipv6.conf.default.accept_redirects=0
EOF
    sudo sysctl -p
}

restrict_compilers() {
    echo "[+] Restricting compilers..."
    sudo chmod 0700 /usr/bin/gcc 2>/dev/null || true
    sudo chmod 0700 /usr/bin/g++ 2>/dev/null || true
}
