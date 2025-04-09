```bash
#!/bin/bash
set -e

echo "📦 Updating system and installing dependencies..."
sudo apt update && sudo apt install -y \
  build-essential libssl-dev iproute2 liblz4-dev \
  liblzo2-dev libpam0g-dev libpkcs11-helper1-dev \
  libsystemd-dev resolvconf pkg-config curl wget

echo "💾 Downloading OpenVPN 2.6.14..."
wget -q https://swupdate.openvpn.org/community/releases/openvpn-2.6.14.tar.gz
tar xzf openvpn-2.6.14.tar.gz
cd openvpn-2.6.14

echo "📥 Downloading XOR patch files..."
PATCHES=(
  "02-tunnelblick-openvpn_xorpatch-a.diff"
  "03-tunnelblick-openvpn_xorpatch-b.diff"
  "04-tunnelblick-openvpn_xorpatch-c.diff"
  "05-tunnelblick-openvpn_xorpatch-d.diff"
  "06-tunnelblick-openvpn_xorpatch-e.diff"
)
for PATCH in "${PATCHES[@]}"; do
  wget -q https://raw.githubusercontent.com/Tunnelblick/Tunnelblick/master/third_party/sources/openvpn/openvpn-2.6.14/patches/$PATCH
done

echo "🩹 Applying XOR patches..."
for PATCH in "${PATCHES[@]}"; do
  patch -p1 < "$PATCH"
done

echo "🛠️ Configuring OpenVPN..."
./configure --enable-static --enable-shared --disable-debug --disable-plugin-auth-pam --disable-dependency-tracking

echo "⚙️ Compiling and installing OpenVPN..."
make -j$(nproc)
sudo make install

echo "🔑 Generating XOR scramble key..."
XOR_KEY=$(head -c 20 /dev/urandom | tr -dc 'a-f0-9' | head -c 12)
echo "Generated XOR key: $XOR_KEY"

echo "📄 Updating server and client config templates with XOR scramble key..."
if [ -f /etc/openvpn/server.conf ]; then
  sed -i "s/^scramble .*/scramble xormask $XOR_KEY/" /etc/openvpn/server.conf || echo "scramble xormask $XOR_KEY" >> /etc/openvpn/server.conf
fi

if [ -f /etc/openvpn/client-template.txt ]; then
  sed -i "s/^scramble .*/scramble xormask $XOR_KEY/" /etc/openvpn/client-template.txt || echo "scramble xormask $XOR_KEY" >> /etc/openvpn/client-template.txt
fi

echo "✅ OpenVPN 2.6.14 with XOR scramble installed successfully!"
echo "👉 Remember to update your clients with the new scramble xormask: $XOR_KEY"

read -p "⏰ Do you want to automatically restart OpenVPN every hour? [y/N]: " cron_choice
if [[ "$cron_choice" =~ ^[Yy]$ ]]; then
  echo "🔄 Setting up cron job..."
  (crontab -l 2>/dev/null; echo "0 * * * * systemctl restart openvpn@server") | crontab -
  echo "🛡️ Cron job added: OpenVPN will restart every hour."
else
  echo "ℹ️ Skipping cron job setup."
fi
