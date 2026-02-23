#!/bin/bash

echo "Disabling auto updates..."
systemctl stop unattended-upgrades 2>/dev/null
systemctl disable unattended-upgrades 2>/dev/null

echo "Updating packages..."
apt update -y

echo "Installing required packages..."
apt install -y curl openssl qrencode

echo "Installing Xray..."
bash <(curl -Ls https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh)

# Ensure config directory exists
mkdir -p /usr/local/etc/xray

echo "Generating UUID..."
UUID=$(cat /proc/sys/kernel/random/uuid)

echo "Generating X25519 key pair..."
KEY_PAIR=$(xray x25519)

PRIVATE_KEY=$(echo "$KEY_PAIR" | grep -i "Private" | awk -F ': ' '{print $2}')
PUBLIC_KEY=$(echo "$KEY_PAIR" | grep -i "Public" | awk -F ': ' '{print $2}')

if [[ -z "$PRIVATE_KEY" || -z "$PUBLIC_KEY" ]]; then
    echo "❌ Failed to generate Reality keys!"
    exit 1
fi

echo "Generating ShortID..."
SHORTID=$(openssl rand -hex 8)

echo "Creating config..."
cat > /usr/local/etc/xray/config.json <<EOF
{
  "log": { "loglevel": "warning" },
  "inbounds": [{
    "port": 443,
    "protocol": "vless",
    "settings": {
      "clients": [{
        "id": "$UUID",
        "flow": "xtls-rprx-vision"
      }],
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
        "privateKey": "$PRIVATE_KEY",
        "shortIds": ["$SHORTID"]
      }
    }
  }],
  "outbounds": [{
    "protocol": "freedom"
  }]
}
EOF

echo "Restarting Xray..."
systemctl restart xray

sleep 2

if ! systemctl is-active --quiet xray; then
    echo "❌ Xray failed to start!"
    systemctl status xray
    exit 1
fi

echo "Detecting Public IP..."
IP=$(curl -4 -s https://api.ipify.org || curl -4 -s ifconfig.me)

if [[ -z "$IP" ]]; then
    echo "❌ Failed to detect public IP!"
    exit 1
fi

LINK="vless://$UUID@$IP:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.cloudflare.com&fp=chrome&pbk=$PUBLIC_KEY&sid=$SHORTID&type=tcp&headerType=none#FastReality"

echo ""
echo "=============================="
echo " Reality Installed Successfully"
echo "=============================="
echo "IP: $IP"
echo "UUID: $UUID"
echo "Public Key: $PUBLIC_KEY"
echo "ShortID: $SHORTID"
echo "Port: 443"
echo "=============================="
echo ""
echo "VLESS LINK:"
echo "$LINK"
echo ""
echo "QR Code:"
qrencode -t ansiutf8 "$LINK"
echo ""
