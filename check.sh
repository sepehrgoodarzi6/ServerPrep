#!/bin/bash
# ---------------------------------
# System & Security Check Script
# ---------------------------------

# ---------- Helper ----------
check_service() {
    local svc=$1
    if systemctl is-active --quiet "$svc"; then
        echo "[OK] $svc is running"
    else
        echo "[FAIL] $svc is not running"
    fi
}

check_package() {
    local pkg=$1
    if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "ok installed"; then
        echo "[OK] Package '$pkg' is installed"
    else
        echo "[FAIL] Package '$pkg' is not installed"
    fi
}

# ---------- Security Tools ----------
check_fail2ban() { check_service fail2ban; }
check_ufw() { check_service ufw; }
check_clamav() { check_service clamav-freshclam; }
check_rkhunter() { command -v rkhunter >/dev/null && echo "[OK] rkhunter found" || echo "[FAIL] rkhunter not found"; }
check_chkrootkit() { command -v chkrootkit >/dev/null && echo "[OK] chkrootkit found" || echo "[FAIL] chkrootkit not found"; }
check_logwatch() { command -v logwatch >/dev/null && echo "[OK] logwatch found" || echo "[FAIL] logwatch not found"; }
check_auditd() { check_service auditd; }
check_apparmor() { check_service apparmor; }
check_unattended_upgrades() { check_package unattended-upgrades; }
check_google_authenticator() { check_package libpam-google-authenticator; }

# ---------- SSH Config ----------
check_password_authentication_enabled() {
    if sudo grep -q "^PasswordAuthentication yes" /etc/ssh/sshd_config; then
        echo "[WARN] PasswordAuthentication is ENABLED"
    else
        echo "[OK] PasswordAuthentication is DISABLED"
    fi
}

check_permit_root_login() {
    if sudo grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config; then
        echo "[WARN] Root login is ENABLED"
    else
        echo "[OK] Root login is DISABLED"
    fi
}

# ---------- System State ----------
check_deleted_files() {
    echo "[*] Checking for deleted files still in use..."
    if lsof | grep deleted >/dev/null; then
        echo "[WARN] Deleted files are still in use!"
    else
        echo "[OK] No deleted files found in use."
    fi
}

check_selinux() {
    if command -v getenforce >/dev/null 2>&1; then
        echo "[INFO] SELinux status: $(getenforce)"
    else
        echo "[INFO] SELinux tools not installed"
    fi
}

check_grsecurity() {
    if uname -a | grep -q grsecurity; then
        echo "[OK] Grsecurity kernel detected"
    else
        echo "[INFO] No grsecurity detected"
    fi
}

# ---------- Run All ----------
run_all_checks() {
    echo "=== Running Security Checks ==="
    check_fail2ban
    check_ufw
    check_clamav
    check_rkhunter
    check_chkrootkit
    check_logwatch
    check_auditd
    check_apparmor
    check_unattended_upgrades
    check_google_authenticator
    check_password_authentication_enabled
    check_permit_root_login
    check_deleted_files
    check_selinux
    check_grsecurity
    echo "=== Checks Completed ==="
}

# Uncomment below line to run all checks automatically
# run_all_checks
