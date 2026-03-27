#!/bin/bash
# ============================================================
# setup.sh — Installation automatique OpenVPN sur Raspberry Pi
# Auteure : Hanane AIT BAH
# ============================================================

set -e

PROJECT_DIR="$HOME/OpenVPN_Serveron_Raspberry-Pi"

echo "================================================"
echo "  OpenVPN Server Setup — Raspberry Pi 5"
echo "  Auteure : Hanane AIT BAH"
echo "================================================"

echo "[1/6] Installation des dependances..."
sudo apt update && sudo apt install -y openvpn easy-rsa

echo "[2/6] Initialisation de la PKI..."
cd "$PROJECT_DIR"
./easyrsa init-pki

echo "[3/6] Creation de la CA..."
./easyrsa build-ca nopass

echo "[4/6] Certificat serveur..."
./easyrsa gen-req server nopass
./easyrsa sign-req server server

echo "[5/6] Diffie-Hellman + TLS Auth..."
./easyrsa gen-dh
openvpn --genkey secret pki/ta.key

echo "[6/6] Copie dans /etc/openvpn..."
sudo cp pki/ca.crt pki/issued/server.crt pki/private/server.key pki/dh.pem pki/ta.key /etc/openvpn/
sudo chmod 644 /etc/openvpn/ta.key
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
sudo systemctl enable openvpn@server
sudo systemctl start openvpn@server

echo ""
echo "OK Serveur OpenVPN demarre !"
echo "   Interface : tun0 | Reseau : 10.8.0.0/24"
echo "   Utilise add-client.sh pour creer un client."
