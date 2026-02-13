#!/bin/bash
set -e

# Default values
DOMAIN=""
USERNAME=""
PASSWORD=""
NO_SSL=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --no-ssl)
      NO_SSL=true
      shift
      ;;
    *)
      if [ -z "$DOMAIN" ]; then
        DOMAIN="$1"
      elif [ -z "$USERNAME" ]; then
        USERNAME="$1"
      elif [ -z "$PASSWORD" ]; then
        PASSWORD="$1"
      fi
      shift
      ;;
  esac
done

if [ "$NO_SSL" = false ] && ([ -z "$DOMAIN" ] || [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]); then
  echo "Usage: $0 [OPTIONS] <domain> <web_user> <web_password>"
  echo "       $0 --no-ssl"
  exit 1
fi

echo "🚀 Starting WebSSH deployment..."

# Update system
apt update && apt upgrade -y

# Install dependencies
apt install -y git golang nginx certbot python3-certbot-nginx

# Create app directory
APP_DIR="/opt/webssh"
mkdir -p "$APP_DIR"

# Build GoTTY
cd /tmp
git clone https://github.com/yudai/gotty.git
cd gotty
go build -o gotty main.go
cp gotty "$APP_DIR/"

# Generate htpasswd
if [ "$NO_SSL" = false ]; then
  apt install -y apache2-utils
  htpasswd -b -c "$APP_DIR/.htpasswd" "$USERNAME" "$PASSWORD"
fi

# Deploy systemd service
cat > /etc/systemd/system/webssh.service <<EOF
[Unit]
Description=WebSSH Service (GoTTY)
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root
ExecStart=$APP_DIR/gotty -w --title-format "WebSSH" --permit-write ssh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable webssh
systemctl start webssh

if [ "$NO_SSL" = true ]; then
  echo "✅ WebSSH running on http://$(hostname -I | awk '{print $1}'):8080"
  echo "⚠️  No SSL/TLS enabled. Use only for testing!"
  exit 0
fi

# Configure Nginx
cat > /etc/nginx/sites-available/webssh <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        auth_basic "Restricted Access";
        auth_basic_user_file $APP_DIR/.htpasswd;
    }
}
EOF

ln -sf /etc/nginx/sites-available/webssh /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

# Request Let's Encrypt cert
certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email

echo "✅ Deployment complete!"
echo "🌐 Visit: https://$DOMAIN"
echo "🔑 Login with user '$USERNAME' and your password."
