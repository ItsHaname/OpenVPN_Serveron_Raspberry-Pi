#!/bin/bash
# ============================================================
# add-client.sh — Ajouter un nouveau client VPN
# Auteure : Hanane AIT BAH
# ============================================================

set -e

PROJECT_DIR="$HOME/OpenVPN_Serveron_Raspberry-Pi"
SERVER_IP="192.168.50.2"

if [ -z "$1" ]; then
  echo "Usage : ./add-client.sh <nom_client>"
  echo "Exemple : ./add-client.sh client2"
  exit 1
fi

CLIENT="$1"

echo "================================================"
echo "  Ajout du client : $CLIENT"
echo "  Auteure : Hanane AIT BAH"
echo "================================================"

cd "$PROJECT_DIR"

echo "[1/3] Generation du certificat pour $CLIENT..."
./easyrsa gen-req "$CLIENT" nopass
./easyrsa sign-req client "$CLIENT"

echo "[2/3] Creation du fichier $CLIENT.ovpn..."
OVPN_FILE="$PROJECT_DIR/config/$CLIENT.ovpn"

{
  echo "client"
  echo "dev tun"
  echo "proto udp"
  echo "remote $SERVER_IP 1194"
  echo "resolv-retry infinite"
  echo "nobind"
  echo "persist-key"
  echo "persist-tun"
  echo "data-ciphers AES-256-GCM:AES-256-CBC"
  echo "data-ciphers-fallback AES-256-CBC"
  echo "auth SHA256"
  echo "tls-version-min 1.2"
  echo "key-direction 1"
  echo "verb 3"
  echo "<ca>"
  cat /etc/openvpn/ca.crt
  echo "</ca>"
  echo "<cert>"
  cat "$PROJECT_DIR/pki/issued/$CLIENT.crt"
  echo "</cert>"
  echo "<key>"
  cat "$PROJECT_DIR/pki/private/$CLIENT.key"
  echo "</key>"
  echo "<tls-auth>"
  cat /etc/openvpn/ta.key
  echo "</tls-auth>"
} > "$OVPN_FILE"

echo "[3/3] Fichier pret !"
echo ""
echo "OK Fichier genere : config/$CLIENT.ovpn"
echo "   Transfere-le avec :"
echo "   scp pi@$SERVER_IP:$PROJECT_DIR/config/$CLIENT.ovpn ~/"
