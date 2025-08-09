#!/bin/bash

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

# -------------------------
# Menu and main control loop
# -------------------------

clear
echo "============================"
echo "  SSH & System Setup Manager"
echo "============================"

while true; do
    clear
    echo
    echo "Choose environment to manage:"
    echo "1) Server"
    echo "2) Laptop"
    echo "3) Exit"
    read -p "Enter choice [1-3]: " env_choice
    clear
    

    case $env_choice in
        1)
            echo
            echo "Server options:"
            echo "  1) Update SSH login policy (PermitRootLogin yes, PasswordAuthentication yes)"
            echo "  2) Disable SSH password login (enable key-only login)"
            echo "  3) Uncomment force_color_prompt in /root/.bashrc"
            echo "  4) Enable case-insensitive tab completion"
            echo "  5) Install useful packages (sshpass, bc, rsync, bash-completion)"
            echo "  6) Back to main menu"
            read -p "Select option [1-6]: " server_opt

            case $server_opt in
                1) update_ssh_login_policy ;;
                2) disable_password_ssh_on_server ;;
                3) uncomment_force_color_prompt ;;
                4) enable_case_insensitive_completion ;;
                5) install_packages ;;
                6) continue ;;
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
