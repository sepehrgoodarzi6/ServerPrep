#!/bin/bash

# Colors
GREEN='\e[32m'
ORANGE='\e[33m'
BLUE='\033[0;34m'
RESET='\e[0m'

print_banner() {
  #local GREEN='\033[0;32m'
  #local BLUE='\033[0;34m'
  #local RESET='\033[0m'

  echo -e "${GREEN}====================================="
  echo -e "Together, by supporting one another,"
  echo "we make it impossible for the bad guys"
  echo "to harm us."
  echo -e "${BLUE}                     — SKYCHAN"
  echo -e "${GREEN}=====================================${RESET}"
}

generate_ssh_key_and_send() {
    read -p "Enter SSH username: " USERNAME
    read -p "Enter server IP or hostname: " SERVER
    KEY_PATH="$HOME/.ssh/id_ed25519"

    if [[ ! -f "$KEY_PATH" ]]; then
        echo "[+] Generating new SSH key..."
        ssh-keygen -t ed25519 -C "$USERNAME@$SERVER" -f "$KEY_PATH" -N ""
    else
        echo "[!] SSH key already exists at $KEY_PATH"
    fi

    echo "[+] Sending public key to $SERVER..."
    ssh-copy-id -i "$KEY_PATH.pub" "$USERNAME@$SERVER"

    echo "[✓] Public key installed on server."
    echo "[!] You can now connect without a password: ssh $USERNAME@$SERVER"
}

install_google_authenticator() {
    echo "[+] Installing Google Authenticator PAM module..."
    sudo apt install -y libpam-google-authenticator

    echo "[+] Configuring PAM for Google Authenticator..."
    sudo grep -qxF "auth required pam_google_authenticator.so nullok" /etc/pam.d/sshd || \
        echo "auth required pam_google_authenticator.so nullok" | sudo tee -a /etc/pam.d/sshd

    echo "[+] Configuring SSHD to use ChallengeResponseAuthentication..."
    sudo sed -i 's/^#*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config

    echo "[+] Disabling PasswordAuthentication (optional, or if just want it to be the keys)..."
    # sudo sed -i 's/^#*PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config

    echo "[+] Restarting SSH service..."
    sudo systemctl restart sshd

    echo "[!] Now, each user should run 'google-authenticator' command once to setup their secret key."
    echo "    They will receive QR code and emergency scratch codes."
}

disable_password_ssh_on_server() {
    echo "[!] This function should be run on the server (or via ssh)."
    sshd_config="/etc/ssh/sshd_config"
    sudo cp "$sshd_config" "${sshd_config}.bak"

    sudo sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' "$sshd_config"
    sudo sed -i 's/^#*ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' "$sshd_config"
    sudo sed -i 's/^#*UsePAM.*/UsePAM no/' "$sshd_config"
    sudo sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' "$sshd_config"

    echo "[+] Restarting SSH service..."
    sudo systemctl restart ssh || sudo systemctl restart sshd

    echo "[✓] Password authentication disabled. Only key-based login allowed."
}

update_ssh_login_policy() {
    local sshd_config="/etc/ssh/sshd_config"
    echo "[+] Backing up $sshd_config to ${sshd_config}.bak.$(date +%F-%H%M%S)"
    sudo cp "$sshd_config" "${sshd_config}.bak.$(date +%F-%H%M%S)"

    sudo sed -i 's/^PermitRootLogin .*/PermitRootLogin yes/' "$sshd_config"
    sudo sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' "$sshd_config"
    grep -q '^PermitRootLogin' "$sshd_config" || echo 'PermitRootLogin yes' | sudo tee -a "$sshd_config" > /dev/null
    grep -q '^PasswordAuthentication' "$sshd_config" || echo 'PasswordAuthentication yes' | sudo tee -a "$sshd_config" > /dev/null

    if sshd -t; then
        echo "✔ sshd_config syntax is valid. Restarting SSH..."
        sudo systemctl restart sshd
        echo "✔ SSH service restarted successfully."
    else
        echo "❌ sshd_config has syntax errors. Reverting changes."
        sudo mv "${sshd_config}.bak."* "$sshd_config"
    fi
}

uncomment_force_color_prompt() {
    sudo sed -i 's/^#\s*\(force_color_prompt=yes\)/\1/' /root/.bashrc
    echo "✔ Uncommented 'force_color_prompt=yes' in /root/.bashrc"
}

enable_case_insensitive_completion() {
    echo "set completion-ignore-case On" | sudo tee -a /etc/inputrc > /dev/null
    echo "✔ Enabled case-insensitive tab completion."
}

install_packages() {
    sudo apt update && sudo apt upgrade -y
    mkdir -p ~/.ssh && chmod 700 ~/.ssh
    echo -e "Host 10.200.200.*\n    StrictHostKeyChecking no\n    UserKnownHostsFile /dev/null" >> ~/.ssh/config
    sudo apt install -y sshpass bc rsync bash-completion
    echo "[+] Installed packages: sshpass, bc, rsync, bash-completion"
}

install_fail2ban() {
    echo "[+] Installing Fail2Ban..."
    sudo apt install -y fail2ban
    sudo systemctl enable fail2ban
    sudo systemctl start fail2ban
    echo "[+] Fail2Ban installed and started."
}

configure_fail2ban_ssh() {
    echo "[+] Configuring Fail2Ban for SSH..."
    sudo bash -c 'cat > /etc/fail2ban/jail.d/ssh.conf << EOF
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
bantime = 600
EOF'
    sudo systemctl restart fail2ban
    echo "[+] Fail2Ban configured for SSH."
}

install_ufw() {
    echo "[+] Installing and enabling UFW firewall..."
    sudo apt install -y ufw
    sudo ufw allow ssh
    sudo ufw --force enable
    echo "[+] UFW firewall enabled with SSH allowed."
}

install_clamav() {
    echo "[+] Installing ClamAV antivirus..."
    sudo apt install -y clamav clamav-daemon
    sudo systemctl enable clamav-freshclam
    sudo systemctl start clamav-freshclam
    echo "[+] ClamAV installed and freshclam started."
}

install_rkhunter() {
    echo "[+] Installing rkhunter for rootkit detection..."
    sudo apt install -y rkhunter
    sudo rkhunter --update
    sudo rkhunter --propupd
    echo "[+] rkhunter installed and database updated."
}

install_chkrootkit() {
    echo "[+] Installing chkrootkit for rootkit detection..."
    sudo apt install -y chkrootkit
    echo "[+] chkrootkit installed."
}

install_logwatch() {
    echo "[+] Installing Logwatch for log monitoring..."
    sudo apt install -y logwatch
    echo "[+] Logwatch installed."
}

install_auditd() {
    echo "[+] Installing auditd for system auditing..."
    sudo apt install -y auditd
    sudo systemctl enable auditd
    sudo systemctl start auditd
    echo "[+] auditd installed and running."
}

install_apparmor() {
    echo "[+] Ensuring AppArmor is installed and enabled..."
    sudo apt install -y apparmor apparmor-utils
    sudo systemctl enable apparmor
    sudo systemctl start apparmor
    echo "[+] AppArmor installed and running."
}

install_unattended_upgrades() {
    echo "[+] Installing unattended-upgrades for automatic security updates..."
    sudo apt install -y unattended-upgrades
    sudo dpkg-reconfigure -plow unattended-upgrades
    echo "[+] unattended-upgrades installed and configured."
}

# ---- Status check functions ----

check_fail2ban() {
    systemctl is-active --quiet fail2ban
}

check_ufw() {
    systemctl is-active --quiet ufw
}

check_clamav() {
    systemctl is-active --quiet clamav-freshclam
}

check_rkhunter() {
    command -v rkhunter >/dev/null 2>&1
}

check_chkrootkit() {
    command -v chkrootkit >/dev/null 2>&1
}

check_logwatch() {
    command -v logwatch >/dev/null 2>&1
}

check_auditd() {
    systemctl is-active --quiet auditd
}

check_apparmor() {
    systemctl is-active --quiet apparmor
}

check_unattended_upgrades() {
    dpkg-query -W -f='${Status}' unattended-upgrades 2>/dev/null | grep -q "ok installed"
}

check_google_authenticator() {
    dpkg-query -W -f='${Status}' libpam-google-authenticator 2>/dev/null | grep -q "ok installed"
}

check_password_authentication_enabled() {
    sudo grep -q "^PasswordAuthentication yes" /etc/ssh/sshd_config
}

check_permit_root_login() {
    sudo grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config
}

print_status() {
    local name="$1"
    local status="$2"
    if [[ "$status" -eq 1 ]]; then
        echo -e "${GREEN}✔ ${name}${RESET}"
    else
        echo -e "${ORANGE}✘ ${name}${RESET}"
    fi
}

# -------------------------
# Menu and main control loop
# -------------------------

while true; do
    clear
    print_banner
    echo
    echo "Choose environment to manage:"
    echo "1) Server"
    echo "2) Laptop"
    echo "3) Exit"
    read -p "Enter choice [1-3]: " env_choice
    clear
    print_banner

    case $env_choice in
        1)
            # Check statuses
            fail2ban_status=0
            ufw_status=0
            clamav_status=0
            rkhunter_status=0
            chkrootkit_status=0
            logwatch_status=0
            auditd_status=0
            apparmor_status=0
            unattended_status=0
            google_auth_status=0
            pass_auth_status=0
            root_login_status=0

            check_fail2ban && fail2ban_status=1
            check_ufw && ufw_status=1
            check_clamav && clamav_status=1
            check_rkhunter && rkhunter_status=1
            check_chkrootkit && chkrootkit_status=1
            check_logwatch && logwatch_status=1
            check_auditd && auditd_status=1
            check_apparmor && apparmor_status=1
            check_unattended_upgrades && unattended_status=1
            check_google_authenticator && google_auth_status=1
            check_password_authentication_enabled && pass_auth_status=1
            check_permit_root_login && root_login_status=1

            echo
            echo "Server options:"
            echo "  1) $(print_status "Update SSH login policy (PermitRootLogin yes, PasswordAuthentication yes)" $root_login_status)"
            echo "  2) $(print_status "Disable SSH password login (enable key-only login)" $((1 - pass_auth_status)))"
            echo "  3) Uncomment force_color_prompt in /root/.bashrc"
            echo "  4) Enable case-insensitive tab completion"
            echo "  5) Install useful packages (sshpass, bc, rsync, bash-completion)"
            echo "  6) $(print_status "Install and configure Fail2Ban" $fail2ban_status)"
            echo "  7) $(print_status "Install and enable UFW firewall" $ufw_status)"
            echo "  8) $(print_status "Install ClamAV antivirus" $clamav_status)"
            echo "  9) $(print_status "Install rootkit detectors (rkhunter, chkrootkit)" $((rkhunter_status && chkrootkit_status)))"
            echo " 10) $(print_status "Install Logwatch log monitoring" $logwatch_status)"
            echo " 11) $(print_status "Install auditd system auditing" $auditd_status)"
            echo " 12) $(print_status "Install and enable AppArmor" $apparmor_status)"
            echo " 13) $(print_status "Install unattended-upgrades for auto security updates" $unattended_status)"
            echo " 14) $(print_status "Install and configure Google Authenticator (2FA for SSH)" $google_auth_status)"
            echo " 15) Back to main menu"
            read -p "Select option [1-15]: " server_opt

            case $server_opt in
                1) update_ssh_login_policy ;;
                2) disable_password_ssh_on_server ;;
                3) uncomment_force_color_prompt ;;
                4) enable_case_insensitive_completion ;;
                5) install_packages ;;
                6)
                    install_fail2ban
                    configure_fail2ban_ssh
                    ;;
                7) install_ufw ;;
                8) install_clamav ;;
                9)
                    install_rkhunter
                    install_chkrootkit
                    ;;
                10) install_logwatch ;;
                11) install_auditd ;;
                12) install_apparmor ;;
                13) install_unattended_upgrades ;;
                14) install_google_authenticator ;;
                15) continue ;;
                *) echo "Invalid option." ;;
            esac
            ;;
        2)
            echo
            echo "Laptop options:"
            echo "  1) Generate SSH key and send to server"
            echo "  2) Back to main menu"
            read -p "Select option [1-2]: " laptop_opt

            case $laptop_opt in
                1) generate_ssh_key_and_send ;;
                2) continue ;;
                *) echo "Invalid option." ;;
            esac
            ;;
        3)
            echo "Exiting..."
            break
            ;;
        *)
            echo "Invalid choice, please select 1, 2 or 3."
            ;;
    esac
done
