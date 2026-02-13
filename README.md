# 🚀 webssh-deploy

> One-command deployment of a secure, browser-accessible SSH terminal on your VPS.

This Bash script automatically installs and configures a **WebSSH** service on a fresh Ubuntu/Debian VPS, so you can access your server via a web browser — no local SSH client needed. Perfect for restricted networks (e.g., corporate firewalls) or quick remote access.

🔐 **Features**:
- ✅ Auto-install `gotty` (GoTTY) — a simple terminal-in-browser tool
- ✅ Optional: Use `shellinabox` instead (toggle in script)
- ✅ Automatic HTTPS via **Let's Encrypt** (using `certbot`)
- ✅ Basic HTTP auth for added security
- ✅ Runs as a systemd service (auto-restart on boot)
- ✅ Works on **Ubuntu 20.04/22.04/24.04** and **Debian 11/12**

> ⚠️ **Warning**: Exposing SSH via the web increases attack surface. Always use strong passwords, 2FA, and restrict access via firewall if possible.

---

## 🛠️ Quick Start

Run this **on a fresh VPS** (as root or sudo user):

```
curl -sSL https://raw.githubusercontent.com/your-username/webssh-deploy/main/install.sh | sudo bash -s your-domain.com admin yourpassword123
```

Replace:
- your-domain.com → your DNS A-record pointing to this VPS
- admin → your desired web login username
- yourpassword123 → a strong password

💡 No domain? Use --no-ssl mode (not recommended for production):
```
curl -sSL https://raw.githubusercontent.com/your-username/webssh-deploy/main/install.sh | sudo bash -s -- --no-ssl
```
After ~2 minutes, visit:
👉 https://your-domain.com (or http://YOUR_VPS_IP:8080 in --no-ssl mode)

## 🔧 How It Works
- Installs dependencies (git, go, nginx, certbot)
- Builds **yudai/gotty** from source
- Configures reverse proxy with Nginx
- Requests free TLS certificate from Let’s Encrypt (if domain provided)
- Sets up HTTP Basic Auth
- Creates & enables systemd service (webssh.service)
- All configuration files are placed in /opt/webssh/.

## 📂 Project Structure
```
webssh-deploy/
├── install.sh            # Main deployment script
├── templates/
│   ├── nginx-site.conf   # Nginx config template
│   └── webssh.service    # Systemd service file
├── README.md
└── LICENSE
```

## 🔐 Security Notes
- The WebSSH endpoint is protected by HTTP Basic Authentication.
- Never expose this on a public IP without auth or firewall rules.
- Consider restricting access by IP using ufw:
```
ufw allow from 203.0.113.0/24 to any port 443
```
- Disable root login in SSH daemon (PermitRootLogin no in /etc/ssh/sshd_config).

## 🔄 Uninstall 
```
sudo systemctl stop webssh
sudo systemctl disable webssh
sudo rm -rf /opt/webssh /etc/nginx/sites-enabled/webssh /etc/systemd/system/webssh.service
sudo nginx -t && sudo systemctl reload nginx
```

## 📜 License
---
MIT
