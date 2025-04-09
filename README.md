# openvpn-2.6.14-xor-install
Script to build and install OpenVPN 2.6.14 with XOR scramble patches automatically

# OpenVPN 2.6.14 Installer with XOR Patch

This project provides a fully automated script to download, patch, compile, and install **OpenVPN 2.6.14** with **XOR scramble obfuscation**, optimized for use in highly censored environments like **Turkmenistan**.

## Features

- Downloads and installs OpenVPN 2.6.14
- Applies Tunnelblick's XOR patch for traffic obfuscation
- Randomly generates a strong XOR key (10+ symbols)
- Optionally sets up a cron job to restart OpenVPN every hour (to make DPI harder)
- Suitable for Ubuntu 20.04+ systems

## Usage

```bash
wget https://raw.githubusercontent.com/igaresh/openvpn-2.6.14-xor-installer/main/setup_openvpn_2.6.14_xor.sh
chmod +x setup_openvpn_2.6.14_xor.sh
sudo ./setup_openvpn_2.6.14_xor.sh
