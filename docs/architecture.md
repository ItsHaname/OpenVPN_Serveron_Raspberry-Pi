# Architecture du système — OpenVPN sur Raspberry Pi 5

**Auteure :** Hanane AIT BAH

---

## Vue d'ensemble

Le système est composé de trois éléments principaux connectés via Internet :
```
[ PC Client / Smartphone ]
          |
          |  Tunnel chiffré (TLS + AES-256-GCM)
          |  UDP port 1194
          |
[ OpenVPN Server — Raspberry Pi 5 ]
     IP locale  : 192.168.50.2
     IP tunnel  : 10.8.0.1
          |
          |
[ Réseau local sécurisé ]
     Plage VPN  : 10.8.0.0/24
```

---

## Composants

### 1. Serveur VPN (Raspberry Pi 5)
- OS : Raspberry Pi OS 64-bit
- CPU : ARM Cortex-A76 avec accélération AES matérielle
- Logiciel : OpenVPN 2.x
- IP locale : 192.168.50.2
- Interface VPN : tun0 — 10.8.0.1

### 2. Client VPN (PC Arch Linux)
- Logiciel : OpenVPN 2.7.0
- IP reçue sur le tunnel : 10.8.0.6
- Fichier de connexion : client1.ovpn

### 3. Infrastructure PKI (Easy-RSA)
- Autorité de Certification : RaspberryPi-CA
- Certificat serveur : server.crt (signé par la CA)
- Certificat client : client1.crt (signé par la CA)
- Diffie-Hellman : dh.pem (2048 bits)
- TLS Auth : ta.key

---

## Flux de connexion

1. Le client envoie un paquet UDP signé avec ta.key
2. Le serveur vérifie la signature TLS Auth
3. Handshake TLS 1.3 — échange de clés via Diffie-Hellman
4. Vérification mutuelle des certificats X.509
5. Tunnel chiffré établi avec AES-256-GCM
6. Le trafic du client est routé via 10.8.0.1

---

## Propriétés de sécurité

| Propriété | Mécanisme |
|---|---|
| Confidentialité | AES-256-GCM |
| Intégrité | HMAC-SHA256 |
| Authentification | Certificats X.509 (PKI) |
| Forward Secrecy | Diffie-Hellman éphémère |
| Anti-rejeu | Numéros de séquence TLS |
