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

echo "Generating X25519 key pair..."
KEY_PAIR=$(/usr/local/bin/xray x25519)

# ===== FIXED SECTION =====
PRIVATE_KEY=$(echo "$KEY_PAIR" | grep "PrivateKey" | awk '{print $2}')
PUBLIC_KEY=$(echo "$KEY_PAIR" | grep "Password" | awk '{print $2}')

if [[ -z "$PRIVATE_KEY" || -z "$PUBLIC_KEY" ]]; then
    echo "❌ Failed to generate Reality keys!"
    exit 1
fi
# ==========================

SHORTID=$(openssl rand -hex 8)

mkdir -p /usr/local/etc/xray

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

# ===== FIXED IP SECTION =====
IP=$(curl -4 -s https://api.ipify.org)
# ============================

LINK="vless://$UUID@$IP:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.cloudflare.com&fp=chrome&pbk=$PUBLIC_KEY&sid=$SHORTID&type=tcp&headerType=none#FastReality"

echo ""
echo "=============================="
echo "Reality Installed Successfully"
echo "IP: $IP"
echo "UUID: $UUID"
echo "Public Key (pbk): $PUBLIC_KEY"
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
