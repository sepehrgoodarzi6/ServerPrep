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
wget -qO- https://raw.githubusercontent.com/sepehrgoodarzi6/ServerBootstrap/main/bootstrap.sh | bash
```
**OR**
```bash
curl -sO https://raw.githubusercontent.com/sepehrgoodarzi6/ServerBootstrap/main/bootstrap.sh && chmod +x bootstrap.sh && ./bootstrap.sh
```
## Requirements
Debian/Ubuntu based Linux

Root privileges

Internet access

## Contributing
Feel free to open issues or pull requests for improvements or fixes!
