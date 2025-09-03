# ServerPrep

ServerPrep automates the initial setup of a fresh Linux server, providing essential tools, security configurations, and environment optimizations.

## Features

- Configure SSH with root login and password authentication options  
- Install essential packages: `sshpass`, `bc`, `rsync`, `bash-completion`  
- Harden SSH settings for improved security and access control  
- Enable case-insensitive tab completion for easier navigation  
- Activate a colorful shell prompt for the root user  
- Optional setup of advanced security tools:
  - Fail2Ban
  - UFW firewall
  - ClamAV antivirus
  - Rootkit detectors (`rkhunter`, `chkrootkit`)
  - Google Authenticator for SSH 2FA
  - Log monitoring with Logwatch
  - Audit system with `auditd`
  - AppArmor protection
  - Automatic security updates

## Requirements
- Debian or Ubuntu based systems
- Root or sudo privileges

## Usage

Run as root on Debian/Ubuntu systems:
```bash
curl -sO https://raw.githubusercontent.com/sepehrgoodarzi6/ServerPrep/main/bootstrap.sh
chmod +x bootstrap.sh
sudo ./bootstrap.sh
```

## Contributing
Feel free to open issues or pull requests for improvements or fixes!
