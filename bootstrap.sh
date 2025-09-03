#!/bin/bash

# -------------------------
# Colors
# -------------------------
GREEN='\e[32m'
ORANGE='\e[33m'
BLUE='\033[0;34m'
RESET='\e[0m'

# -------------------------
# Banner
# -------------------------
print_banner() {
  echo -e "${GREEN}====================================="
  echo -e "Together, by supporting one another,"
  echo "we make it impossible for the bad guys"
  echo "to harm us."
  echo -e "${BLUE}                     — SKYCHAN"
  echo -e "${GREEN}=====================================${RESET}"
}

# -------------------------
# Load external functions
# -------------------------
source ./install.sh
source ./check.sh

# -------------------------
# Helper to print status
# -------------------------
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
# Submenu: Server
# -------------------------
server_menu() {
    local fail2ban_status=0
    local ufw_status=0
    local clamav_status=0
    local rkhunter_status=0
    local chkrootkit_status=0
    local logwatch_status=0
    local auditd_status=0
    local apparmor_status=0
    local unattended_status=0
    local google_auth_status=0
    local pass_auth_status=0
    local root_login_status=0

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
    echo "  1) $(print_status "Update SSH login policy" $root_login_status)"
    echo "  2) $(print_status "Disable SSH password login" $((1 - pass_auth_status)))"
    echo "  3) Uncomment force_color_prompt"
    echo "  4) Enable case-insensitive tab completion"
    echo "  5) Install useful packages (sshpass, bc, rsync, bash-completion)"
    echo "  6) $(print_status "Install and configure Fail2Ban" $fail2ban_status)"
    echo "  7) $(print_status "Install and enable UFW firewall" $ufw_status)"
    echo "  8) $(print_status "Install ClamAV antivirus" $clamav_status)"
    echo "  9) $(print_status "Install rootkit detectors" $((rkhunter_status && chkrootkit_status)))"
    echo " 10) $(print_status "Install Logwatch" $logwatch_status)"
    echo " 11) $(print_status "Install auditd" $auditd_status)"
    echo " 12) $(print_status "Install and enable AppArmor" $apparmor_status)"
    echo " 13) $(print_status "Install unattended-upgrades" $unattended_status)"
    echo " 14) $(print_status "Install Google Authenticator (2FA)" $google_auth_status)"
    echo " 15) Back to main menu"
    read -p "Select option [1-15]: " server_opt

    case $server_opt in
        1) update_ssh_login_policy ;;
        2) disable_password_ssh_on_server ;;
        3) uncomment_force_color_prompt ;;
        4) enable_case_insensitive_completion ;;
        5) install_packages ;;
        6) install_fail2ban && configure_fail2ban_ssh ;;
        7) install_ufw ;;
        8) install_clamav ;;
        9) install_rkhunter && install_chkrootkit ;;
        10) install_logwatch ;;
        11) install_auditd ;;
        12) install_apparmor ;;
        13) install_unattended_upgrades ;;
        14) install_google_authenticator ;;
        15) return ;;
        *) echo "Invalid option." ;;
    esac
}

# -------------------------
# Submenu: Laptop
# -------------------------
laptop_menu() {
    echo
    echo "Laptop options:"
    echo "  1) Generate SSH key and send to server"
    echo "  2) Back to main menu"
    read -p "Select option [1-2]: " laptop_opt

    case $laptop_opt in
        1) generate_ssh_key_and_send ;;
        2) return ;;
        *) echo "Invalid option." ;;
    esac
}

# -------------------------
# Submenu: Secure Bootstrap
# -------------------------
secure_bootstrap_menu() {
    echo
    echo "Secure Bootstrap options:"
    echo "  1) Install Fail2Ban"
    echo "  2) Configure SSH (sshd + banner)"
    echo "  3) Configure iptables"
    echo "  4) Install MariaDB"
    echo "  5) Install Apache (with security modules)"
    echo "  6) Harden system (sysctl + permissions)"
    echo "  7) Check services"
    echo "  8) Back to main menu"
    read -p "Select option [1-8]: " choice

    case $choice in
        1) install_fail2ban && configure_fail2ban ;;
        2) configure_sshd && configure_ssh_banner ;;
        3) configure_iptables ;;
        4) install_mariadb ;;
        5) install_apache_security ;;
        6) harden_permissions && harden_sysctl && restrict_compilers ;;
        7) check_service fail2ban; check_service mariadb; check_selinux; check_grsecurity; check_deleted_files ;;
        8) return ;;
        *) echo "Invalid choice" ;;
    esac
}

# -------------------------
# Main control loop
# -------------------------
while true; do
    clear
    print_banner
    echo
    echo "Choose environment to manage:"
    echo "1) Server"
    echo "2) Laptop"
    echo "3) Secure Bootstrap"
    echo "4) Exit"
    read -p "Enter choice [1-4]: " env_choice
    clear
    print_banner

    case $env_choice in
        1) server_menu ;;
        2) laptop_menu ;;
        3) secure_bootstrap_menu ;;
        4) echo "Exiting..."; break ;;
        *) echo "Invalid choice." ;;
    esac
    read -p "Press enter to continue..."
done
