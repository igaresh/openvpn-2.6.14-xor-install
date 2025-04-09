#!/bin/bash

set -e

# Colors
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Update and install dependencies
echo -e "${GREEN}📦 Updating system and installing dependencies...${NC}"
apt update && apt install -y build-essential libssl-dev iproute2 liblz4-dev liblzo2-dev libpam0g-dev libpkcs11-helper1-dev libsystemd-dev resolvconf pkg-config curl wget

# Download OpenVPN
echo -e "${GREEN}💾 Downloading OpenVPN 2.6.14...${NC}"
wget https://swupdate.openvpn.net/community/releases/openvpn-2.6.14.tar.gz
rm -rf openvpn-2.6.14

# Extract

tar xzf openvpn-2.6.14.tar.gz
cd openvpn-2.6.14

# Download XOR patches
echo -e "${GREEN}📥 Downloading XOR patch files...${NC}"
for patch in 02 03 04 05 06; do
  wget https://raw.githubusercontent.com/Tunnelblick/Tunnelblick/master/third_party/sources/openvpn/openvpn-2.6.14/patches/${patch}-tunnelblick-openvpn_xorpatch-$(echo $patch | tr '0' 'a').diff
  patch -p1 < ${patch}-tunnelblick-openvpn_xorpatch-$(echo $patch | tr '0' 'a').diff
done

# Configure and install
echo -e "${GREEN}🛠️ Configuring and compiling OpenVPN...${NC}"
./configure --enable-static=yes --enable-shared --disable-debug --disable-plugin-auth-pam --disable-dependency-tracking
make
make install

# Create OpenVPN service file
echo -e "${GREEN}📆 Creating OpenVPN service...${NC}"
cat << EOF > /etc/systemd/system/openvpn@server.service
[Unit]
Description=OpenVPN Robust And Highly Flexible Tunneling Application On %I
After=syslog.target network.target

[Service]
Type=forking
PrivateTmp=true
ExecStart=/usr/local/sbin/openvpn --daemon --cd /etc/openvpn/ --config /etc/openvpn/server.conf
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reexec
systemctl enable openvpn@server
systemctl start openvpn@server

# Generate random XOR key
echo -e "${GREEN}🔑 Generating random XOR key...${NC}"
xor_key=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 12)
echo "scramble xormask $xor_key" >> /etc/openvpn/server.conf
echo "scramble xormask $xor_key" >> /etc/openvpn/client-template.txt
echo "scramble xormask $xor_key" >> /root/client.ovpn
echo -e "${GREEN}Random XOR key generated and applied: $xor_key${NC}"

# Offer to install hourly cron restart (optional)
echo -e "${GREEN}📅 Offer: Restart OpenVPN hourly to make DPI harder${NC}"
read -p "Do you want to auto-restart OpenVPN every hour via cron? (y/n): " restart_choice
if [[ "$restart_choice" == "y" ]]; then
    (crontab -l 2>/dev/null; echo "0 * * * * systemctl restart openvpn@server") | crontab -
    echo -e "${GREEN}Cron job installed: OpenVPN will restart every hour.${NC}"
else
    echo -e "${GREEN}Skipped installing hourly restart.${NC}"
fi

echo -e "${GREEN}✅ OpenVPN 2.6.14 with XOR scramble installed successfully!${NC}"
