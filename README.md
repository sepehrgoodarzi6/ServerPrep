# ServerPrep

Automate the initial setup of a fresh Linux server with essential tools, SSH configuration, and environment tweaks.

## Features

- Enable SSH root login and password authentication  
- Install essential packages: `sshpass`, `bc`, `rsync`, `bash-completion`  
- Configure SSH for improved security and access  
- Enable case-insensitive tab completion  
- Activate colored prompt for root user  
- Optional setup for Fail2Ban, UFW firewall, ClamAV, rootkit detectors, Google Authenticator (2FA), and more  

## Usage

Run as root on Debian/Ubuntu systems:
```bash
curl -sO https://raw.githubusercontent.com/sepehrgoodarzi6/ServerPrep/main/bootstrap.sh && chmod +x bootstrap.sh && ./bootstrap.sh
```

## Contributing
Feel free to open issues or pull requests for improvements or fixes!
