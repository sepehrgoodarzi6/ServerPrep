# ServerPrep
Automated Bash script to bootstrap a fresh Linux server with essential tools, SSH access, and environment setup ready for development or deployment.

# ServerBootstrap: Quick and Automated Server Preparation Script 🛠️

This is a Bash script designed to streamline the **initial setup of a fresh Linux server** (especially Ubuntu/Debian-based systems). It configures essential settings, installs commonly-used tools, and prepares your server for remote access, development, or deployment — all with a single command.

## 🚀 Features

- Enables SSH root login and password authentication
- Installs essential packages: `sshpass`, `bc`, `rsync`, `bash-completion`
- Automatically accepts host keys for a specific subnet (`10.200.200.*`)
- Enables case-insensitive tab completion
- Activates color prompt for root

## 📦 Packages Installed

- `sshpass`
- `bc`
- `rsync`
- `bash-completion`

## 📁 Files Modified

- `/etc/ssh/sshd_config` – for SSH access
- `/etc/inputrc` – for case-insensitive completion
- `/root/.bashrc` – to enable colored prompt

## ⚙️ Usage

> ⚠️ This script should be run as `root`.

```bash
wget -qO- https://raw.githubusercontent.com/sepehrgoodarzi6/ServerBootstrap/main/bootstrap.sh | bash
```
**OR**
```bash
curl -sO https://raw.githubusercontent.com/sepehrgoodarzi6/ServerBootstrap/main/bootstrap.sh && chmod +x bootstrap.sh && ./bootstrap.sh
```

## The script will:

- Update your system

- Install useful tools

- Reconfigure SSH settings

- Prepare the shell environment

## 📌 Requirements
- Debian/Ubuntu-based Linux

- Root privileges

- Internet access

## 🧠 Why Use This?
Setting up servers repeatedly can be time-consuming. This script helps you automate the boring parts and ensures consistency in your initial server configuration — especially useful for developers, sysadmins, and anyone working with VPS/VM setups.

## 🤝 Contribute
Got an idea? Found a bug? Want to add more features?

## Feel free to open a pull request or issue!
I’m happy to consider your ideas and contributions to make this script even more useful for the community.


