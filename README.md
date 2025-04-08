# openvpn-2.6.14-xor-install
Script to build and install OpenVPN 2.6.14 with XOR scramble patches automatically

# OpenVPN 2.6.14 XOR Installer

This script automatically builds and installs OpenVPN 2.6.14 from source, applying Tunnelblick XOR scramble patches, and configuring a random XOR key for obfuscation.

## Features
- Automatic download of OpenVPN 2.6.14
- Apply XOR patches from Tunnelblick
- Random 16-character XOR scramble key generated on install
- Automatic config updates (`server.conf`, `client-template.txt`, `client.ovpn`)
- Full install from source on Ubuntu 20.04+

## Usage

```bash
wget https://raw.githubusercontent.com/igaresh/openvpn-2.6.14-xor-install/main/setup_openvpn_2.6.14_xor.sh
chmod +x setup_openvpn_2.6.14_xor.sh
sudo ./setup_openvpn_2.6.14_xor.sh
