# 🔐 Serveur OpenVPN sur Raspberry Pi 5 — Analyse de Sécurité Cryptographique

<div align="center">

![Raspberry Pi](https://img.shields.io/badge/Raspberry%20Pi%205-A22846?style=for-the-badge&logo=raspberry-pi&logoColor=white)
![OpenVPN](https://img.shields.io/badge/OpenVPN-EA7E20?style=for-the-badge&logo=openvpn&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![TLS](https://img.shields.io/badge/TLS%201.3-005F99?style=for-the-badge&logo=letsencrypt&logoColor=white)
![AES](https://img.shields.io/badge/AES--256-4CAF50?style=for-the-badge&logo=gnupg&logoColor=white)

**Conception et déploiement d'un serveur VPN sécurisé avec infrastructure à clé publique (PKI) et analyse des performances cryptographiques.**

</div>

---

## 📋 Table des Matières

- [Vue d'ensemble](#-vue-densemble)
- [Objectifs](#-objectifs)
- [Architecture du Système](#-architecture-du-système)
- [Technologies Utilisées](#-technologies-utilisées)
- [Infrastructure à Clé Publique (PKI)](#-infrastructure-à-clé-publique-pki)
- [Installation & Configuration](#-installation--configuration)
- [Analyse Cryptographique](#-analyse-cryptographique)
- [Propriétés de Sécurité](#-propriétés-de-sécurité)
- [Comparaison de Performances : AES-128 vs AES-256](#-comparaison-de-performances--aes-128-vs-aes-256)
- [Résultats](#-résultats)
- [Auteur](#-auteur)

---

## 🌐 Vue d'Ensemble

Ce projet présente la **conception et l'implémentation d'un serveur VPN sécurisé** basé sur OpenVPN, déployé sur un **Raspberry Pi 5**. Il va au-delà d'une simple configuration VPN en intégrant une **Infrastructure à Clé Publique (PKI) complète** et en évaluant la sécurité ainsi que les performances de différents algorithmes de chiffrement.

Le système crée un tunnel chiffré entre un client distant (PC ou smartphone) et un réseau local hébergé derrière le Raspberry Pi, garantissant **confidentialité**, **intégrité** et **authentification mutuelle**.

---

## 🎯 Objectifs

- ✅ Déployer un serveur OpenVPN sur Raspberry Pi 5
- ✅ Implémenter une PKI complète avec Easy-RSA
- ✅ Sécuriser toutes les communications via TLS
- ✅ Analyser les propriétés de sécurité du VPN (confidentialité, intégrité, authentification)
- ✅ Comparer les performances d'AES-128 et AES-256 sur matériel embarqué

---

##  Architecture du Système


<img width="1604" height="817" alt="image" src="https://github.com/user-attachments/assets/3632c556-cd55-4985-b864-48adad7d0f74" />


L'architecture repose sur **trois composants principaux** :

| Composant | Rôle |
|---|---|
| 🖥️ Client VPN | PC ou smartphone se connectant via Internet |
| 🍓 Serveur OpenVPN (Raspberry Pi 5) | Gère les tunnels chiffrés et le routage |
| 🔒 Réseau Local Sécurisé | Réseau privé accessible uniquement via le VPN |

---

## 🛠️ Technologies Utilisées

| Technologie | Rôle |
|---|---|
| **OpenVPN** | Gestion du tunnel VPN |
| **Easy-RSA** | Gestion de la PKI et des certificats |
| **TLS 1.3** | Sécurisation du canal de contrôle |
| **AES-128 / AES-256** | Chiffrement des données (canal de données) |
| **Raspberry Pi OS** | Système d'exploitation serveur basé sur Linux (Debian) |
| **HMAC-SHA256** | Intégrité des messages et authentification |

---

## 🔑 Infrastructure à Clé Publique (PKI)

Une PKI complète est implémentée via **Easy-RSA** pour permettre l'authentification mutuelle entre le serveur et tous les clients.

```
Autorité de Certification (CA)  ← Racine de Confiance
        │
        ├──► Certificat Serveur     (signé par la CA)
        │
        ├──► Certificat Client 1    (signé par la CA)
        │
        └──► Certificat Client N    (signé par la CA)
```

### Composants de la PKI

| Composant | Description |
|---|---|
| **CA (Autorité de Certification)** | Racine de confiance ; signe tous les certificats |
| **Certificat Serveur** | Prouve l'identité du serveur aux clients |
| **Certificats Clients** | Uniques par client ; permet la révocation individuelle (CRL) |
| **Paramètres Diffie-Hellman** | Garantit la confidentialité persistante (PFS) |
| **Clé TLS Auth (ta.key)** | Couche HMAC supplémentaire contre les attaques DDoS et connexions non autorisées |

---

## ⚙️ Installation & Configuration

### Prérequis

- Raspberry Pi 5 sous Raspberry Pi OS (64 bits recommandé)
- Adresse IP locale statique ou DNS dynamique configuré
- Redirection de port : `UDP 1194` ouvert sur votre routeur

### 1. Installation des Dépendances

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install openvpn easy-rsa -y
```

### 2. Mise en Place de la PKI avec Easy-RSA

```bash
make-cadir ~/openvpn-ca
cd ~/openvpn-ca

# Initialisation de la PKI
./easyrsa init-pki

# Création de l'Autorité de Certification
./easyrsa build-ca

# Génération du certificat et de la clé serveur
./easyrsa gen-req server nopass
./easyrsa sign-req server server

# Génération des paramètres Diffie-Hellman
./easyrsa gen-dh

# Génération de la clé d'authentification TLS
openvpn --genkey secret ta.key
```

### 3. Génération du Certificat Client

```bash
cd ~/openvpn-ca
./easyrsa gen-req client1 nopass
./easyrsa sign-req client client1
```

### 4. Configuration du Serveur OpenVPN

```bash
sudo cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf /etc/openvpn/
sudo nano /etc/openvpn/server.conf
```

Paramètres de configuration clés :

```ini
port 1194
proto udp
dev tun

ca   /etc/openvpn/ca.crt
cert /etc/openvpn/server.crt
key  /etc/openvpn/server.key
dh   /etc/openvpn/dh.pem

server 10.8.0.0 255.255.255.0
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"

tls-auth ta.key 0
cipher AES-256-CBC        # ou AES-128-CBC pour la comparaison
auth SHA256

keepalive 10 120
user nobody
group nogroup
persist-key
persist-tun

verb 3
```

### 5. Activation du Forwarding IP et Démarrage du Serveur

```bash
# Activation du forwarding IP
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Activation et démarrage d'OpenVPN
sudo systemctl enable openvpn@server
sudo systemctl start openvpn@server
sudo systemctl status openvpn@server
```

---

## 🔬 Analyse Cryptographique

### Chiffrement — AES (Advanced Encryption Standard)

OpenVPN utilise AES pour le **canal de données** (chiffrement du trafic réel) :

| Mode | Taille de Clé | Taille de Bloc | Niveau de Sécurité |
|---|---|---|---|
| AES-128-CBC | 128 bits | 128 bits | Très élevé (~2¹²⁸) |
| AES-256-CBC | 256 bits | 128 bits | Maximum (~2²⁵⁶) |

### Échange de Clés — TLS + Diffie-Hellman

Le **canal de contrôle** utilise TLS 1.3 avec échange de clés Diffie-Hellman, garantissant :

- **Confidentialité Persistante (PFS)** : Les clés de session sont éphémères — compromettre la clé serveur n'expose pas les sessions passées
- **Échange de Clés Authentifié** : Les deux parties se vérifient mutuellement via les certificats PKI

### Intégrité — HMAC-SHA256

Chaque paquet de données est signé avec HMAC-SHA256, assurant :

- Toute altération de paquet est détectée et rejetée
- Protection contre les attaques par rejeu

---

## 🛡️ Propriétés de Sécurité

| Propriété | Mécanisme | Description |
|---|---|---|
| 🔒 **Confidentialité** | AES-256-CBC | Tout le trafic est chiffré ; les paquets interceptés sont illisibles |
| ✅ **Intégrité** | HMAC-SHA256 | Toute modification de paquet est détectée et rejetée |
| 👤 **Authentification** | PKI + Certificats X.509 | Client et serveur prouvent mutuellement leur identité |
| 🔄 **Confidentialité Persistante** | Clés DH Éphémères | Les sessions passées restent sécurisées même si les clés à long terme sont compromises |
| 🚫 **Anti-Rejeu** | Numéros de Séquence TLS | Empêche les attaquants de rejouer des paquets capturés |

---

## 📊 Comparaison de Performances : AES-128 vs AES-256

### Méthodologie de Benchmark

Les tests ont été réalisés avec `openssl speed` sur le Raspberry Pi 5 dans des conditions de charge identiques.

```bash
# Benchmark AES-128
openssl speed -evp aes-128-cbc

# Benchmark AES-256
openssl speed -evp aes-256-cbc
```

### Résultats Attendus sur Raspberry Pi 5

| Algorithme | Débit (approx.) | Utilisation CPU | Cas d'Usage Recommandé |
|---|---|---|---|
| **AES-128-CBC** | ~300 Mo/s | Faible | Scénarios à haut débit |
| **AES-256-CBC** | ~250 Mo/s | Légèrement supérieur | Sécurité maximale requise |

> ⚠️ **Remarque :** Le Raspberry Pi 5 intègre une accélération matérielle AES (ARM Cortex-A76), réduisant significativement l'écart de performances entre AES-128 et AES-256.

### Conclusion

La différence de performances entre AES-128 et AES-256 sur le Raspberry Pi 5 est **minimale** grâce à l'accélération matérielle. Pour la majorité des cas d'usage, **AES-256** est recommandé compte tenu de sa marge de sécurité supérieure à un coût négligeable.

---

## 📈 Résultats

| Indicateur | Valeur |
|---|---|
| ✅ Tunnel VPN Établi | Oui |
| 🔐 Authentification Mutuelle | Certificats PKI (X.509) |
| 🔑 Chiffrement | AES-256-CBC |
| 🔏 Intégrité | HMAC-SHA256 |
| 🔄 Confidentialité Persistante | Oui (DH Éphémère) |
| 📡 Protocole | OpenVPN sur UDP 1194 |
| 🖥️ Matériel | Raspberry Pi 5 (ARM Cortex-A76) |

---

## 👤 Auteur

**Hanane AIT BAH**
🔗 [@ItsHaname](https://github.com/ItsHaname)

---

<div align="center">

⭐ Si ce projet vous a été utile, n'hésitez pas à **mettre une étoile** au dépôt !

</div>
