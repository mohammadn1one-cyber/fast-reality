#!/bin/bash

echo "Updating minimal packages..."
apt update -y

echo "Installing curl..."
apt install curl -y

echo "Installing Xray..."
bash <(curl -Ls https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh)

UUID=$(cat /proc/sys/kernel/random/uuid)
KEY=$(xray x25519 | grep Private | awk '{print $3}')
PUBLIC=$(xray x25519 | grep Public | awk '{print $3}')
SHORTID=$(openssl rand -hex 8)

cat > /usr/local/etc/xray/config.json <<EOF
{
  "log": {"loglevel": "warning"},
  "inbounds": [{
    "port": 443,
    "protocol": "vless",
    "settings": {
      "clients": [{"id": "$UUID","flow": "xtls-rprx-vision"}],
      "decryption": "none"
    },
    "streamSettings": {
      "network": "tcp",
      "security": "reality",
      "realitySettings": {
        "show": false,
        "dest": "www.cloudflare.com:443",
        "xver": 0,
        "serverNames": ["www.cloudflare.com"],
        "privateKey": "$KEY",
        "shortIds": ["$SHORTID"]
      }
    }
  }],
  "outbounds": [{"protocol": "freedom"}]
}
EOF

systemctl restart xray

IP=$(curl -s ifconfig.me)

echo "=============================="
echo "Reality Installed Successfully"
echo "IP: $IP"
echo "UUID: $UUID"
echo "Public Key: $PUBLIC"
echo "ShortID: $SHORTID"
echo "Port: 443"
echo "SNI: www.cloudflare.com"
echo "=============================="
