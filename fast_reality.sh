#!/bin/bash

echo "Disabling auto updates..."
systemctl stop unattended-upgrades 2>/dev/null
systemctl disable unattended-upgrades 2>/dev/null

echo "Updating minimal packages..."
apt update -y

echo "Installing required packages..."
apt install curl openssl qrencode -y

echo "Installing Xray..."
bash <(curl -Ls https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh)

UUID=$(cat /proc/sys/kernel/random/uuid)

KEY_PAIR=$(xray x25519)
PRIVATE_KEY=$(echo "$KEY_PAIR" | grep Private | awk '{print $3}')
PUBLIC_KEY=$(echo "$KEY_PAIR" | grep Public | awk '{print $3}')

SHORTID=$(openssl rand -hex 8)

cat > /usr/local/etc/xray/config.json <<EOF
{
  "log": {"loglevel": "warning"},
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

systemctl restart xray

IP=$(curl -s ifconfig.me)

LINK="vless://$UUID@$IP:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.cloudflare.com&fp=chrome&pbk=$PUBLIC_KEY&sid=$SHORTID&type=tcp&headerType=none#FastReality"

echo ""
echo "=============================="
echo "Reality Installed Successfully"
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
