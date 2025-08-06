#!/bin/bash

update_ssh_login_policy() {
    local sshd_config="/etc/ssh/sshd_config"

    # Backup the original config
    cp "$sshd_config" "${sshd_config}.bak.$(date +%F-%H%M%S)"

    # Update or insert the desired configuration lines
    sed -i 's/^PermitRootLogin .*/PermitRootLogin yes/' "$sshd_config"
    sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' "$sshd_config"
    grep -q '^PermitRootLogin' "$sshd_config" || echo 'PermitRootLogin yes' >> "$sshd_config"
    grep -q '^PasswordAuthentication' "$sshd_config" || echo 'PasswordAuthentication yes' >> "$sshd_config"

    # Test SSH configuration syntax
    if sshd -t; then
        echo "✔ sshd_config syntax is valid. Restarting SSH..."
        systemctl restart sshd
        echo "✔ SSH service restarted successfully."
    else
        echo "❌ sshd_config has syntax errors. Reverting changes."
        mv "${sshd_config}.bak."* "$sshd_config"
    fi
}

uncomment_force_color_prompt() {
    sed -i 's/^#\s*\(force_color_prompt=yes\)/\1/' /root/.bashrc
    echo "✔ Uncommented 'force_color_prompt=yes' in /root/.bashrc"
}

enable_case_insensitive_completion() {
    echo "set completion-ignore-case On" >> /etc/inputrc
    echo "✔ Enabled case-insensitive tab completion."
}

apt update && apt upgrade -y
mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo -e "Host 10.200.200.*\n    StrictHostKeyChecking no\n    UserKnownHostsFile /dev/null" >> ~/.ssh/config
apt install sshpass
apt install bc
apt install rsync
apt install bash-completion
update_ssh_login_policy
uncomment_force_color_prompt
enable_case_insensitive_completion
bash
echo "Done!"
