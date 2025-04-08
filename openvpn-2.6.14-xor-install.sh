#!/bin/bash

set -e

echo "📦 Updating system and installing dependencies..."

apt update && apt install -y \
  build-essential \
  libssl-dev \
  iproute2 \
  liblz4-dev \
  liblzo2-dev \
  libpam0g-dev \
  libpkcs11-helper1-dev \
  libsystemd-dev \
  resolvconf \
  pkg-config \
  wget \
  curl

echo "💾 Downloading OpenVPN 2.6.14..."
wget -q https://swupdate.openvpn.org/community/releases/openvpn-2.6.14.tar.gz
tar -xzf openvpn-2.6.14.tar.gz
cd openvpn-2.6.14

echo "📥 Downloading XOR patch files..."
PATCH_URL_BASE="https://raw.githubusercontent.com/Tunnelblick/Tunnelblick/master/third_party/sources/openvpn/openvpn-2.6.14/patches"

for patch in 02-tunnelblick-openvpn_xorpatch-a.diff 03-tunnelblick-openvpn_xorpatch-b.diff 04-tunnelblick-openvpn_xorpatch-c.diff 05-tunnelblick-openvpn_xorpatch-d.diff 06-tunnelblick-openvpn_xorpatch-e.diff; do
  wget -q "${PATCH_URL_BASE}/${patch}"
done

echo "🩹 Applying XOR patches..."
for patch in 02-tunnelblick-openvpn_xorpatch-a.diff 03-tunnelblick-openvpn_xorpatch-b.diff 04-tunnelblick-openvpn_xorpatch-c.diff 05-tunnelblick-openvpn_xorpatch-d.diff 06-tunnelblick-openvpn_xorpatch-e.diff; do
  patch -p1 < "$patch"
done

echo "🛠️ Compiling OpenVPN..."
./configure --enable-static=yes --enable-shared --disable-debug --disable-plugin-auth-pam --disable-dependency-tracking
make
make install

cd ~

echo "📜 Setting up OpenVPN configs and XOR scramble..."

# Generate random XOR scramble key (at least 10 characters, up to 32)
XOR_KEY=$(head -c 32 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 16)

# Adjust server config
if [ -f /etc/openvpn/server.conf ]; then
  sed -i 's/^port .*/port 443/' /etc/openvpn/server.conf
  echo "scramble xormask $XOR_KEY" >> /etc/openvpn/server.conf
fi

# Adjust client template
if [ -f /etc/openvpn/client-template.txt ]; then
  sed -i 's/1194/443/g' /etc/openvpn/client-template.txt
  echo "scramble xormask $XOR_KEY" >> /etc/openvpn/client-template.txt
fi

# Adjust default client config
if [ -f /root/client.ovpn ]; then
  echo "scramble xormask $XOR_KEY" >> /root/client.ovpn
fi

echo "✅ OpenVPN 2.6.14 installed and patched with XOR scramble key!"
echo "🔑 Your XOR scramble key is: $XOR_KEY"

echo "🔄 Restart OpenVPN server to apply changes:"
echo "    sudo systemctl restart openvpn@server || sudo systemctl restart openvpn-server@server"
