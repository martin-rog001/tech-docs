#!/bin/bash
# Security Hardening Script for Web Server

set -e

echo "Starting security hardening..."

# Disable root login via SSH
echo "Hardening SSH configuration..."
sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# Reload SSH
systemctl reload sshd

# Install fail2ban
echo "Installing fail2ban..."
apt-get install -y fail2ban

# Configure fail2ban
cat > /etc/fail2ban/jail.local <<'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log

[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/*error.log

[nginx-noscript]
enabled = true
port = http,https
logpath = /var/log/nginx/*access.log
EOF

systemctl enable fail2ban
systemctl start fail2ban

# Disable unnecessary services
echo "Disabling unnecessary services..."
systemctl disable --now avahi-daemon 2>/dev/null || true
systemctl disable --now cups 2>/dev/null || true

# Set secure file permissions
echo "Setting secure permissions..."
chmod 644 /etc/passwd
chmod 644 /etc/group
chmod 600 /etc/shadow
chmod 600 /etc/gshadow

# Enable automatic security updates
echo "Configuring automatic security updates..."
apt-get install -y unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades

# Configure kernel parameters
echo "Hardening kernel parameters..."
cat >> /etc/sysctl.conf <<'EOF'

# Security hardening
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
EOF

sysctl -p

# Create marker file
touch /root/.security-hardened

echo "Security hardening completed!"
