# 📖 Explication Complète du Projet OpenVPN sur Raspberry Pi 5

> **Auteure du projet original :** Hanane AIT BAH — [@ItsHaname](https://github.com/ItsHaname)
> **Document d'explication :** Ligne par ligne, fichier par fichier, concept par concept.

---

## 📋 Table des Matières

1. [Vue d'ensemble — C'est quoi ce projet ?](#1-vue-densemble)
2. [Structure des fichiers du projet](#2-structure-des-fichiers)
3. [Concepts fondamentaux avant de commencer](#3-concepts-fondamentaux)
4. [Fichier : `scripts/setup.sh` — Ligne par ligne](#4-fichier-scriptssetupsh)
5. [Fichier : `scripts/add-client.sh` — Ligne par ligne](#5-fichier-scriptsadd-clientsh)
6. [Fichier : `config/server.conf` — Ligne par ligne](#6-fichier-configserverconf)
7. [Dossier : `pki/` — Tous les certificats expliqués](#7-dossier-pki)
8. [Dossier : `x509-types/` — Les règles des certificats](#8-dossier-x509-types)
9. [Fichier : `pki/dh.pem` — Le Diffie-Hellman](#9-fichier-pkidhpem)
10. [Fichier : `pki/index.txt` — Le registre des certificats](#10-fichier-pkiindextxt)
11. [Fichier : `easyrsa` — L'outil de gestion PKI](#11-fichier-easyrsa)
12. [Processus complet de connexion — Ce qui se passe réellement](#12-processus-complet-de-connexion)
13. [Analyse cryptographique — AES-128 vs AES-256](#13-analyse-cryptographique)
14. [Guide de dépannage — Problèmes et solutions](#14-guide-de-dépannage)
15. [Résumé visuel de toute l'architecture](#15-résumé-visuel)

---

## 1. Vue d'Ensemble

### C'est quoi ce projet ?

Ce projet transforme un **Raspberry Pi 5** en **serveur VPN personnel**. VPN signifie *Virtual Private Network* (Réseau Privé Virtuel).

**Le problème que ça résout :**
Quand tu te connectes à Internet depuis un café, un hôtel ou n'importe quel réseau Wi-Fi public, tes données voyagent en clair. N'importe qui sur le même réseau peut les espionner.

**La solution :**
Un VPN crée un **tunnel chiffré** entre ton appareil et le Raspberry Pi. Tout ton trafic passe par ce tunnel. Personne ne peut lire ce qui passe à l'intérieur.

```
SANS VPN :
Ton PC ──── [données lisibles] ──── Wi-Fi public ──── Internet

AVEC VPN :
Ton PC ══════════════════════════════════════ Raspberry Pi ──── Internet
       Tunnel chiffré AES-256 (illisible)
```

### Ce que le projet fait en plus d'un simple VPN

Ce projet va plus loin qu'une simple configuration VPN. Il inclut :
- Une **PKI complète** (Infrastructure à Clé Publique) avec des certificats X.509
- Une **analyse cryptographique** comparant AES-128 et AES-256
- Des **scripts automatisés** pour installer et ajouter des clients
- Une **documentation technique** professionnelle

---

## 2. Structure des Fichiers

Voici tous les fichiers du projet avec leur rôle exact :

```
OpenVPN_Serveron_Raspberry-Pi-main/
│
├── README.md                  ← Description générale du projet
│
├── scripts/
│   ├── setup.sh               ← Script d'installation automatique du serveur
│   └── add-client.sh          ← Script pour ajouter un nouveau client VPN
│
├── config/
│   └── server.conf            ← Fichier de configuration du serveur OpenVPN
│
├── docs/
│   ├── architecture.md        ← Schéma technique du système
│   ├── guide.md               ← Guide d'installation étape par étape (avec captures)
│   ├── benchmark.md           ← Résultats des tests de performance AES-128 vs AES-256
│   └── Troubleshooting.md     ← Problèmes rencontrés et solutions
│
├── pki/                       ← Infrastructure à Clé Publique (certificats)
│   ├── ca.crt                 ← Certificat PUBLIC de l'Autorité de Certification
│   ├── dh.pem                 ← Paramètres Diffie-Hellman (2048 bits)
│   ├── index.txt              ← Registre de tous les certificats émis
│   ├── index.txt.attr         ← Configuration du registre
│   ├── serial                 ← Numéro de série du prochain certificat
│   ├── vars                   ← Variables de configuration d'Easy-RSA
│   ├── vars.example           ← Exemple de fichier vars
│   ├── openssl-easyrsa.cnf    ← Configuration OpenSSL pour Easy-RSA
│   ├── safessl-easyrsa.cnf    ← Configuration OpenSSL sécurisée
│   │
│   ├── issued/                ← Certificats signés (côté public)
│   │   ├── server.crt         ← Certificat du serveur VPN
│   │   └── client1.crt        ← Certificat du client 1
│   │
│   ├── reqs/                  ← Requêtes de certificats (avant signature)
│   │   ├── server.req         ← Requête du serveur
│   │   └── client1.req        ← Requête du client 1
│   │
│   └── certs_by_serial/       ← Copies des certificats classées par numéro de série
│       ├── 09F25ADA...pem     ← Certificat server (copie)
│       └── A6526C56...pem     ← Certificat client1 (copie)
│
├── x509-types/                ← Définitions des types de certificats X.509
│   ├── COMMON                 ← Extensions communes à tous les certificats
│   ├── ca                     ← Règles spécifiques aux certificats CA
│   ├── server                 ← Règles spécifiques aux certificats serveur
│   ├── client                 ← Règles spécifiques aux certificats client
│   ├── serverClient           ← Règles pour certificat mixte serveur+client
│   ├── code-signing           ← Règles pour signature de code
│   ├── email                  ← Règles pour certificats email
│   └── kdc                    ← Règles pour Kerberos
│
├── easyrsa                    ← L'outil principal de gestion des certificats (script bash)
├── openssl-easyrsa.cnf        ← Configuration OpenSSL principale d'Easy-RSA
└── vars.example               ← Exemple de configuration Easy-RSA
```

> ⚠️ **Note importante :** Les clés **privées** (`server.key`, `client1.key`, `ca.key`) ne sont **pas** dans ce dépôt. C'est intentionnel et correct — une clé privée ne doit JAMAIS être partagée publiquement.

---

## 3. Concepts Fondamentaux

Avant d'analyser les fichiers ligne par ligne, voici les briques de base qu'il faut comprendre.

### 3.1 — La Paire de Clés (Clé Publique / Clé Privée)

Chaque entité (CA, serveur, client) possède **deux clés mathématiquement liées** :

```
Clé PRIVÉE  🔒  →  fichier .key  →  gardée secrète, jamais partagée
Clé PUBLIQUE 🔓  →  dans le .crt  →  partagée librement
```

**Propriété magique :**
- Ce que la clé privée chiffre → seule la clé publique peut déchiffrer
- Ce que la clé publique chiffre → seule la clé privée peut déchiffrer

C'est ce mécanisme qui permet de **prouver son identité** sans jamais révéler son secret.

**Analogie :** Un cadenas ouvert (clé publique) que tu distribues à tout le monde. Seul toi possèdes la clé (clé privée) pour l'ouvrir.

### 3.2 — Le Certificat X.509

Un certificat est un **fichier texte signé** qui contient :
- Le nom du propriétaire
- Sa clé publique
- La date de validité
- La signature de la CA (ce qui le rend valide)

Format réel du certificat `server.crt` de ce projet :
```
Issuer   : RaspberryPi-CA        ← Qui l'a signé (la CA)
Subject  : server                ← À qui il appartient
Valid from: 27 Mars 2026         ← Début de validité
Valid to  : 29 Juin 2028         ← Fin de validité
Public Key: RSA 2048 bits        ← La clé publique du serveur
```

### 3.3 — La CA (Autorité de Certification)

La CA est la **racine de confiance** du système. C'est elle qui signe les certificats et leur donne leur valeur.

```
CA (RaspberryPi-CA)
    │── signe ──► server.crt  ✅ valide car signé par la CA
    │── signe ──► client1.crt ✅ valide car signé par la CA
    └── refuse ─► faux_cert   ❌ invalide car pas signé par la CA
```

**Analogie :** Le gouvernement qui émet les cartes d'identité. Une carte d'identité sans le sceau du gouvernement est un faux.

### 3.4 — TLS et le Handshake

**TLS** (*Transport Layer Security*) est le protocole qui établit le tunnel sécurisé. Le **handshake** (poignée de main) est la procédure de négociation initiale :

```
Étape 1 : Le client dit "bonjour" et liste les algorithmes qu'il supporte
Étape 2 : Le serveur répond et présente son certificat
Étape 3 : Le client vérifie le certificat (signé par la CA ?)
Étape 4 : Le client présente son certificat
Étape 5 : Le serveur vérifie le certificat du client
Étape 6 : Les deux négocient une clé de session (Diffie-Hellman)
Étape 7 : Le tunnel chiffré est établi
```

### 3.5 — Le Diffie-Hellman et le Perfect Forward Secrecy (PFS)

**Problème :** Si quelqu'un enregistre tout le trafic chiffré aujourd'hui, et vole la clé du serveur dans 5 ans, il pourrait tout déchiffrer rétrospectivement.

**Solution — Diffie-Hellman :** À chaque connexion, une **clé de session éphémère** est créée. Cette clé n'est jamais stockée. Même en volant la clé du serveur, on ne peut pas déchiffrer les anciennes sessions.

C'est ce qu'on appelle **Perfect Forward Secrecy (PFS)** ou Confidentialité Persistante.

### 3.6 — AES (Advanced Encryption Standard)

AES est l'algorithme qui **chiffre les données** qui voyagent dans le tunnel. Il existe en deux versions dans ce projet :

| Version | Taille de clé | Sécurité | Débit sur Raspberry Pi 5 |
|---------|--------------|----------|--------------------------|
| AES-128-CBC | 128 bits | Très élevé (~2¹²⁸) | ~1 900 MB/s |
| AES-256-GCM | 256 bits | Maximum (~2²⁵⁶) | ~1 368 MB/s |

**GCM vs CBC :**
- **CBC** (*Cipher Block Chaining*) : ancien mode, chiffre bloc par bloc en chaîne
- **GCM** (*Galois/Counter Mode*) : mode moderne, chiffre ET authentifie en même temps — plus sûr

### 3.7 — HMAC-SHA256

**HMAC** (*Hash-based Message Authentication Code*) garantit l'**intégrité** des paquets.

Chaque paquet reçoit une "empreinte digitale" calculée avec SHA256. Si le paquet est modifié en transit (même un seul bit), l'empreinte ne correspond plus → le paquet est rejeté.

**Analogie :** Un sceau de cire sur une enveloppe. Si quelqu'un l'a ouverte et refermée, le sceau est cassé.

---

## 4. Fichier : `scripts/setup.sh`

Ce script automatise l'installation complète du serveur. Voici chaque ligne expliquée :

```bash
#!/bin/bash
```
**Ligne 1 :** Le "shebang". Dit au système "exécute ce fichier avec le programme bash". Sans cette ligne, le système ne saurait pas comment interpréter le script.

```bash
set -e
```
**Ligne 2 :** Si **une seule commande échoue**, le script s'arrête immédiatement. Empêche d'exécuter des étapes suivantes sur une base défectueuse. Très important pour un script d'installation critique.

```bash
PROJECT_DIR="$HOME/OpenVPN_Serveron_Raspberry-Pi"
```
**Ligne 3 :** Définit une variable `PROJECT_DIR` qui stocke le chemin vers le projet. `$HOME` est automatiquement remplacé par `/home/pi` (ou l'utilisateur courant). On utilise une variable pour ne pas répéter ce chemin partout.

```bash
echo "[1/6] Installation des dependances..."
sudo apt update && sudo apt install -y openvpn easy-rsa
```
**Étape 1 :**
- `sudo apt update` : Met à jour la liste des paquets disponibles depuis les serveurs Debian/Ubuntu
- `&&` : "Et si ça réussit, exécute la commande suivante"
- `sudo apt install -y openvpn easy-rsa` : Installe OpenVPN (le serveur VPN) et Easy-RSA (l'outil de gestion PKI)
- `-y` : Répond "oui" automatiquement à toutes les questions d'installation (pas d'interruption)

```bash
echo "[2/6] Initialisation de la PKI..."
cd "$PROJECT_DIR"
./easyrsa init-pki
```
**Étape 2 :**
- `cd "$PROJECT_DIR"` : Se déplace dans le dossier du projet
- `./easyrsa init-pki` : Initialise la structure PKI. Crée le dossier `pki/` avec sa structure vide (dossiers `issued/`, `reqs/`, `private/`, etc.)

```bash
echo "[3/6] Creation de la CA..."
./easyrsa build-ca nopass
```
**Étape 3 :**
- `build-ca` : Crée l'Autorité de Certification (la paire de clés + certificat auto-signé)
- `nopass` : Ne protège pas la clé CA par un mot de passe. En production, on omettra ce paramètre pour plus de sécurité (mais ça demande de saisir le mot de passe à chaque signature de certificat)
- Produit : `pki/ca.crt` (certificat public) et `pki/private/ca.key` (clé privée, jamais partagée)

```bash
echo "[4/6] Certificat serveur..."
./easyrsa gen-req server nopass
./easyrsa sign-req server server
```
**Étape 4 :**
- `gen-req server nopass` : Génère une requête de certificat pour "server"
  - Crée `pki/reqs/server.req` (la demande)
  - Crée `pki/private/server.key` (la clé privée du serveur)
- `sign-req server server` :
  - Premier `server` = type de certificat (utilisera les règles de `x509-types/server`)
  - Deuxième `server` = nom de l'entité à certifier
  - La CA signe la requête et produit `pki/issued/server.crt`

```bash
echo "[5/6] Diffie-Hellman + TLS Auth..."
./easyrsa gen-dh
openvpn --genkey secret pki/ta.key
```
**Étape 5 :**
- `gen-dh` : Génère les paramètres Diffie-Hellman 2048 bits. Cette commande est **lente** (2-5 minutes) car elle cherche de grands nombres premiers. Produit `pki/dh.pem`
- `openvpn --genkey secret pki/ta.key` : Génère une clé symétrique aléatoire de 2048 bits utilisée pour l'authentification TLS avant même le handshake. Protège contre les attaques DDoS.

```bash
echo "[6/6] Copie dans /etc/openvpn..."
sudo cp pki/ca.crt pki/issued/server.crt pki/private/server.key pki/dh.pem pki/ta.key /etc/openvpn/
```
**Étape 6a :** Copie tous les fichiers nécessaires dans `/etc/openvpn/`. Le service OpenVPN tourne en tant qu'utilisateur `nobody` et n'a pas accès au dossier `/home/pi/`. Il a besoin de ses fichiers dans `/etc/openvpn/`.

```bash
sudo chmod 644 /etc/openvpn/ta.key
```
**Étape 6b :** Change les permissions de `ta.key` pour qu'il soit lisible. `644` signifie : propriétaire peut lire+écrire, les autres peuvent seulement lire.

```bash
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```
**Étape 6c — IP Forwarding :**
- Par défaut, Linux ne transfère pas les paquets entre interfaces réseau. Le Raspberry Pi doit agir comme un routeur.
- `echo "net.ipv4.ip_forward=1"` : Prépare la ligne de configuration
- `| sudo tee -a /etc/sysctl.conf` : L'ajoute à la fin du fichier de configuration système (`-a` = append)
- `sudo sysctl -p` : Recharge la configuration sans redémarrer

```bash
sudo systemctl enable openvpn@server
sudo systemctl start openvpn@server
```
**Étape 6d :**
- `enable` : Enregistre le service pour qu'il démarre **automatiquement** à chaque redémarrage du Raspberry Pi
- `start` : Démarre le service **maintenant**
- `openvpn@server` : Le `@server` indique à systemd d'utiliser le fichier de configuration `/etc/openvpn/server.conf`

---

## 5. Fichier : `scripts/add-client.sh`

Ce script ajoute un nouveau client VPN. On peut l'exécuter autant de fois qu'on veut pour créer `client2`, `client3`, etc.

```bash
#!/bin/bash
set -e
```
Même chose que dans `setup.sh` : shebang + arrêt en cas d'erreur.

```bash
PROJECT_DIR="$HOME/OpenVPN_Serveron_Raspberry-Pi"
SERVER_IP="192.168.50.2"
```
**Variables de configuration :**
- `PROJECT_DIR` : Chemin vers le projet
- `SERVER_IP` : L'adresse IP du Raspberry Pi sur le réseau local. Cette IP sera inscrite dans le fichier `.ovpn` du client pour qu'il sache où se connecter.

```bash
if [ -z "$1" ]; then
  echo "Usage : ./add-client.sh <nom_client>"
  echo "Exemple : ./add-client.sh client2"
  exit 1
fi
```
**Vérification d'argument :**
- `$1` : Le premier argument passé au script (ex: `./add-client.sh client2` → `$1` = "client2")
- `-z "$1"` : Vrai si la variable est vide (aucun argument fourni)
- Si vide → affiche l'aide et quitte avec code d'erreur `1`

```bash
CLIENT="$1"
```
Stocke le nom du client dans une variable lisible.

```bash
cd "$PROJECT_DIR"
./easyrsa gen-req "$CLIENT" nopass
./easyrsa sign-req client "$CLIENT"
```
**Étape 1/3 — Génération du certificat :**
- `gen-req "$CLIENT" nopass` : Génère la paire de clés + requête de certificat pour ce client
  - Produit `pki/private/client2.key` (clé privée du client)
  - Produit `pki/reqs/client2.req` (requête de certificat)
- `sign-req client "$CLIENT"` : La CA signe la requête
  - `client` = type de certificat (règles de `x509-types/client`)
  - Produit `pki/issued/client2.crt`

```bash
OVPN_FILE="$PROJECT_DIR/config/$CLIENT.ovpn"
```
Définit le chemin de sortie du fichier `.ovpn` qui sera créé.

```bash
{
  echo "client"
  echo "dev tun"
  echo "proto udp"
  echo "remote $SERVER_IP 1194"
  ...
} > "$OVPN_FILE"
```
**Étape 2/3 — Création du fichier `.ovpn` :**
Les accolades `{ }` regroupent toutes les commandes echo. Le `>` redirige toute la sortie vers le fichier `.ovpn`. C'est un **heredoc** simplifié.

Chaque ligne ajoutée dans le `.ovpn` :

```
client              ← Ce fichier configure un CLIENT (pas un serveur)
dev tun             ← Utilise une interface tunnel (couche 3, routage IP)
proto udp           ← Protocole UDP (plus rapide que TCP pour les VPN)
remote 192.168.50.2 1194   ← Adresse IP et port du serveur à contacter
resolv-retry infinite      ← Réessaie indéfiniment si le serveur est injoignable
nobind              ← Ne lie pas à un port local fixe (laisse l'OS choisir)
persist-key         ← Garde les clés en mémoire lors d'un reconnect (évite de relire les fichiers)
persist-tun         ← Garde l'interface tun ouverte lors d'un reconnect
data-ciphers AES-256-GCM:AES-256-CBC   ← Liste des chiffrements acceptés (par ordre de préférence)
data-ciphers-fallback AES-256-CBC      ← Chiffrement de repli si la négociation échoue
auth SHA256         ← Algorithme HMAC pour l'intégrité des paquets
tls-version-min 1.2 ← Refuse les connexions TLS inférieures à la version 1.2
key-direction 1     ← Indique que ce client utilise la direction 1 de ta.key (le serveur utilise 0)
verb 3              ← Niveau de verbosité des logs (3 = informatif sans être trop bavard)
```

```bash
echo "<ca>"
cat /etc/openvpn/ca.crt
echo "</ca>"
```
Incorpore le certificat de la CA **directement dans le fichier `.ovpn`**. Le client n'a pas besoin de fichiers séparés — tout est dans un seul fichier portable.

```bash
echo "<cert>"
cat "$PROJECT_DIR/pki/issued/$CLIENT.crt"
echo "</cert>"
```
Incorpore le certificat du client dans le `.ovpn`.

```bash
echo "<key>"
cat "$PROJECT_DIR/pki/private/$CLIENT.key"
echo "</key>"
```
Incorpore la clé **privée** du client dans le `.ovpn`. C'est pour ça que ce fichier doit être transmis de manière sécurisée (et jamais posté publiquement).

```bash
echo "<tls-auth>"
cat /etc/openvpn/ta.key
echo "</tls-auth>"
```
Incorpore la clé TLS Auth partagée.

```bash
echo "scp pi@$SERVER_IP:$PROJECT_DIR/config/$CLIENT.ovpn ~/"
```
**Étape 3/3 :** Affiche la commande SCP à utiliser pour transférer le fichier `.ovpn` depuis le Raspberry Pi vers le PC client.

---

## 6. Fichier : `config/server.conf`

C'est le fichier de configuration principal du serveur OpenVPN. Chaque directive est expliquée :

```ini
port 1194
```
**Port d'écoute :** OpenVPN écoute sur le port 1194. C'est le port standard officiel d'OpenVPN (assigné par l'IANA). Il faudra ouvrir ce port sur le routeur (redirection de port / port forwarding).

```ini
proto udp
```
**Protocole réseau :** UDP (User Datagram Protocol) plutôt que TCP.
- **UDP** = envoi sans confirmation de réception → plus rapide, moins de latence
- **TCP** = envoi avec confirmation → plus fiable mais plus lent
- Pour un VPN, UDP est préféré car OpenVPN gère lui-même la fiabilité au-dessus

```ini
dev tun
```
**Type d'interface :** Crée une interface de type `tun` (tunnel). Il en existe deux types :
- `tun` = couche 3 (routage IP) → pour connecter des réseaux IP, c'est le cas ici
- `tap` = couche 2 (Ethernet) → pour simuler un réseau local complet, plus lourd

```ini
ca ca.crt
cert server.crt
key server.key
dh dh.pem
```
**Fichiers cryptographiques :**
- `ca ca.crt` : Certificat de la CA pour vérifier les certificats clients
- `cert server.crt` : Certificat du serveur (preuve d'identité)
- `key server.key` : Clé privée du serveur (gardée secrète dans `/etc/openvpn/`)
- `dh dh.pem` : Paramètres Diffie-Hellman pour l'échange de clés

```ini
tls-auth ta.key 0
```
**Clé TLS Auth :**
- `ta.key` : La clé symétrique partagée
- `0` : Direction pour le serveur (le client utilise `1`)
- Tout paquet non signé avec cette clé est rejeté **avant même** le handshake TLS, ce qui protège contre les scans de ports et certaines attaques DDoS

```ini
server 10.8.0.0 255.255.255.0
```
**Réseau VPN :** Définit la plage d'adresses IP du tunnel.
- `10.8.0.0` : Adresse du réseau VPN
- `255.255.255.0` : Masque de sous-réseau (/24 = 254 adresses disponibles)
- Le serveur prend automatiquement `10.8.0.1`
- Les clients reçoivent `10.8.0.2`, `10.8.0.6`, etc.

```ini
push "redirect-gateway def1 bypass-dhcp"
```
**Redirection du trafic :** Force le client à faire passer **tout son trafic Internet** par le VPN.
- `redirect-gateway` : Remplace la route par défaut du client par le tunnel VPN
- `def1` : Méthode plus propre qui ajoute deux routes spécifiques plutôt que de modifier la route par défaut
- `bypass-dhcp` : Exclut le trafic DHCP local du tunnel

```ini
push "dhcp-option DNS 8.8.8.8"
```
**Serveur DNS :** Indique au client d'utiliser `8.8.8.8` (DNS Google) comme résolveur DNS. Cela évite les fuites DNS — sans ça, les requêtes DNS pourraient encore passer par le réseau local non sécurisé.

```ini
data-ciphers AES-256-GCM:AES-256-CBC
data-ciphers-fallback AES-256-CBC
```
**Algorithmes de chiffrement (OpenVPN 2.5+) :**
- Remplace l'ancienne directive `cipher` (dépréciée)
- `AES-256-GCM` : Préféré — plus moderne, authentifie et chiffre en même temps
- `AES-256-CBC` : Fallback si le client ne supporte pas GCM
- `data-ciphers-fallback` : Dernier recours si la négociation `data-ciphers` échoue

```ini
auth SHA256
```
**Algorithme HMAC :** Utilise SHA-256 pour calculer l'empreinte d'intégrité de chaque paquet. SHA-256 produit une empreinte de 256 bits, pratiquement impossible à falsifier.

```ini
tls-version-min 1.2
```
**Version TLS minimale :** Refuse explicitement les connexions TLS 1.0 et 1.1 (qui ont des vulnérabilités connues). Seules TLS 1.2 et 1.3 sont acceptées.

```ini
topology subnet
```
**Topologie réseau :** Mode `subnet` — chaque client reçoit une IP unique dans le sous-réseau `10.8.0.0/24`. C'est le mode recommandé depuis OpenVPN 2.4 (remplace le mode `net30` plus ancien).

```ini
keepalive 10 120
```
**Maintien de la connexion :**
- `10` : Envoie un paquet "ping" toutes les 10 secondes si aucun trafic
- `120` : Considère la connexion morte si aucune réponse après 120 secondes
- Évite que les connexions dormantes soient coupées par les pare-feux NAT

```ini
user nobody
group nogroup
```
**Déclassement de privilèges :** Après le démarrage (qui nécessite root pour créer l'interface tun), OpenVPN abandonne ses privilèges root et s'exécute en tant qu'utilisateur `nobody` (sans droits). Si OpenVPN est compromis, l'attaquant n'a pas les droits root.

```ini
persist-key
persist-tun
```
**Persistance lors des rechargements :**
- `persist-key` : Ne relit pas les fichiers de clés lors d'un SIGUSR1 (rechargement) → utile car le processus n'a plus les droits pour relire ces fichiers après `user nobody`
- `persist-tun` : Ne recrée pas l'interface tun lors d'un rechargement → évite une interruption de connexion

```ini
status /var/log/openvpn-status.log
log /var/log/openvpn.log
verb 3
```
**Journalisation :**
- `status` : Fichier mis à jour régulièrement avec l'état des connexions actives
- `log` : Fichier de logs principal (démarrage, connexions, erreurs)
- `verb 3` : Niveau de détail des logs. Valeurs : 0 = silencieux, 3 = normal, 9 = débogage maximal

---

## 7. Dossier : `pki/`

### `pki/ca.crt` — Le Certificat de la CA

C'est le certificat **public** de l'Autorité de Certification. Il est partagé avec tous les clients (inclus dans les fichiers `.ovpn`). Son rôle : permettre à chacun de vérifier que les autres certificats sont bien signés par la CA de confiance.

Informations réelles de ce certificat :
```
Issuer  : RaspberryPi-CA   ← Auto-signé (la CA se signe elle-même)
Subject : RaspberryPi-CA   ← C'est le certificat de la CA
```

### `pki/issued/server.crt` — Certificat du Serveur

Informations réelles :
```
Issuer  : RaspberryPi-CA   ← Signé par la CA ✅
Subject : server            ← Appartient au serveur VPN
Valid   : 27/03/2026 → 29/06/2028
Key     : RSA 2048 bits
```

### `pki/issued/client1.crt` — Certificat du Client 1

```
Issuer  : RaspberryPi-CA   ← Signé par la CA ✅
Subject : client1           ← Appartient au client 1
Valid   : 27/03/2026 → 29/06/2028
Key     : RSA 2048 bits
```

### `pki/reqs/server.req` et `pki/reqs/client1.req`

Ce sont les **requêtes de certificats** (CSR = Certificate Signing Request). Elles contiennent :
- La clé publique de l'entité
- Le nom demandé
- Une signature prouvant que l'entité possède bien la clé privée correspondante

Le workflow est :
```
gen-req → génère .req + .key
sign-req → CA lit le .req et produit le .crt
```

### `pki/index.txt` — Le Registre

Contenu réel du fichier :
```
V  280629214325Z  09F25ADA61AFDC78CBD282524B23185E  unknown  /CN=server
V  280629215052Z  A6526C56A9739A3995A61973F3AD0266  unknown  /CN=client1
```

Chaque colonne signifie :
- `V` : Validity status — `V` = Valide, `R` = Révoqué, `E` = Expiré
- `280629214325Z` : Date d'expiration (2028-06-29 21:43:25 UTC)
- Colonne vide : Date de révocation (vide si non révoqué)
- `09F25ADA...` : Numéro de série hexadécimal unique du certificat
- `unknown` : Chemin vers le fichier (non renseigné ici)
- `/CN=server` : Common Name du certificat

### `pki/dh.pem` — Paramètres Diffie-Hellman

Contenu du fichier (réel) :
```
-----BEGIN DH PARAMETERS-----
MIIBCAKCAQEA1cwig+OBfcTJ...
-----END DH PARAMETERS-----
```

Ce fichier contient un **grand nombre premier** de 2048 bits utilisé comme base pour l'algorithme Diffie-Hellman. Plus le nombre est grand, plus l'échange de clés est sécurisé. 2048 bits est le minimum recommandé aujourd'hui.

### `pki/serial` — Numéro de Série

Contient le prochain numéro de série à attribuer à un certificat. Chaque certificat signé reçoit un numéro unique et incrémental pour pouvoir être identifié et éventuellement révoqué individuellement.

---

## 8. Dossier : `x509-types/`

Ces fichiers définissent les **extensions X.509** appliquées aux certificats selon leur type. Ce sont des règles qui définissent ce qu'un certificat est autorisé à faire.

### `x509-types/ca`

```ini
basicConstraints = CA:TRUE
```
**Signifie :** Ce certificat EST une CA. Il peut signer d'autres certificats. Sans ce flag, un certificat ne peut pas être utilisé comme CA.

```ini
subjectKeyIdentifier = hash
```
Ajoute un identifiant unique au certificat basé sur le hash de sa clé publique. Facilite la recherche et la vérification.

```ini
authorityKeyIdentifier = keyid:always,issuer:always
```
Identifie la CA qui a signé ce certificat (par l'ID de sa clé et son nom). Permet de construire la chaîne de confiance.

```ini
keyUsage = cRLSign, keyCertSign
```
**Droits accordés :**
- `keyCertSign` : Peut signer des certificats → c'est ce qui fait qu'une CA est une CA
- `cRLSign` : Peut signer des listes de révocation (CRL — pour invalider des certificats compromis)

### `x509-types/server`

```ini
basicConstraints = CA:FALSE
```
Ce certificat n'est PAS une CA. Il ne peut pas signer d'autres certificats.

```ini
extendedKeyUsage = serverAuth
```
Ce certificat est autorisé à **s'authentifier en tant que serveur**. Sans cet usage, un client OpenVPN refusera le certificat d'un serveur.

```ini
keyUsage = digitalSignature, keyEncipherment
```
- `digitalSignature` : Peut signer des données (authentification)
- `keyEncipherment` : Peut chiffrer des clés de session (nécessaire pour TLS)

### `x509-types/client`

```ini
basicConstraints = CA:FALSE
extendedKeyUsage = clientAuth
```
Ce certificat est autorisé à **s'authentifier en tant que client**. Le serveur OpenVPN vérifie ce flag pour s'assurer qu'il parle bien à un client légitime.

```ini
keyUsage = digitalSignature
```
Le client n'a besoin que de signer (s'authentifier). Il n'a pas besoin de chiffrer des clés de session.

### `x509-types/COMMON`

```ini
# crlDistributionPoints = URI:http://example.net/pki/my_ca.crl
# authorityInfoAccess = caIssuers;URI:http://example.net/pki/my_ca.crt
```
Ces lignes sont commentées (désactivées). Elles permettraient d'indiquer une URL où télécharger la liste de révocation (CRL). Pour un usage personnel, c'est optionnel.

---

## 9. Fichier : `pki/dh.pem` — Explication approfondie

### Pourquoi Diffie-Hellman ?

**Problème fondamental :** Comment deux personnes peuvent-elles établir une clé secrète commune sur un canal public, sans que personne d'autre ne puisse la déduire ?

**Solution Diffie-Hellman :**

Imaginons que Alice (client) et Bob (serveur) veulent établir une clé secrète partagée :

```
Données publiques connues de tous : p (grand nombre premier), g (générateur)
                                    ↕ (ces valeurs sont dans dh.pem)

Alice choisit un secret privé a
Alice calcule : A = g^a mod p          → envoie A à Bob

Bob choisit un secret privé b
Bob calcule   : B = g^b mod p          → envoie B à Alice

Alice calcule : K = B^a mod p = g^(ab) mod p
Bob calcule   : K = A^b mod p = g^(ab) mod p

→ Ils ont tous les deux K, sans jamais l'avoir transmis !
Un espion qui voit A et B ne peut pas calculer K sans résoudre le "problème du logarithme discret"
  (mathématiquement pratiquement impossible avec des nombres de 2048 bits)
```

C'est la magie de Diffie-Hellman : la clé de session `K` n'est jamais transmise, donc elle ne peut pas être interceptée.

---

## 10. Fichier : `pki/index.txt` — Le Registre en détail

```
V   280629214325Z   09F25ADA61AFDC78CBD282524B23185E   unknown   /CN=server
V   280629215052Z   A6526C56A9739A3995A61973F3AD0266   unknown   /CN=client1
```

**Décodage du numéro de série :**
- `09F25ADA61AFDC78CBD282524B23185E` = numéro hexadécimal unique du certificat `server.crt`
- Ce même numéro apparaît dans le nom du fichier `pki/certs_by_serial/09F25ADA61AFDC78CBD282524B23185E.pem`

**Utilité :** Si on veut révoquer `client1`, on utilisera son numéro de série `A6526C56...` pour créer une entrée dans la CRL (Certificate Revocation List). Tout serveur qui consulte la CRL refusera automatiquement ce certificat.

---

## 11. Fichier : `easyrsa` — L'outil PKI

C'est un **script bash** de ~3000 lignes qui automatise toutes les opérations PKI via OpenSSL. Il évite d'avoir à taper des commandes OpenSSL complexes.

**Commandes utilisées dans ce projet :**

| Commande | Action |
|----------|--------|
| `./easyrsa init-pki` | Crée la structure de dossiers PKI vide |
| `./easyrsa build-ca [nopass]` | Crée la CA (paire de clés + certificat auto-signé) |
| `./easyrsa gen-req <name> [nopass]` | Génère une requête de certificat + clé privée |
| `./easyrsa sign-req <type> <name>` | Signe une requête avec la CA → produit un .crt |
| `./easyrsa gen-dh` | Génère les paramètres Diffie-Hellman |
| `./easyrsa revoke <name>` | Révoque un certificat |
| `./easyrsa gen-crl` | Génère la liste de révocation mise à jour |

---

## 12. Processus Complet de Connexion

Voici exactement ce qui se passe, milliseconde par milliseconde, quand le client se connecte :

### Phase 1 — Pré-authentification TLS Auth (ta.key)

```
Client                                    Serveur (Raspberry Pi)
  │                                              │
  │── Paquet UDP signé avec ta.key ────────────►│
  │                                              │
  │                          [Serveur vérifie la signature HMAC avec ta.key]
  │                          [Signature valide ? → continuer]
  │                          [Signature invalide ? → paquet rejeté silencieusement]
```

Cette étape protège le serveur : un attaquant qui ne possède pas `ta.key` ne peut même pas initier un handshake TLS.

### Phase 2 — Handshake TLS 1.3

```
Client                                    Serveur
  │                                              │
  │── ClientHello (liste des algos supportés) ──►│
  │                                              │
  │◄── ServerHello + server.crt ─────────────────│
  │                                              │
  │  [Client vérifie server.crt :               │
  │   1. Signé par RaspberryPi-CA ? OUI ✅      │
  │   2. CN = "server" ? OUI ✅                 │
  │   3. Date valide ? OUI ✅                   │
  │   4. extendedKeyUsage = serverAuth ? OUI ✅ │
  │                                              │
  │── client1.crt ──────────────────────────────►│
  │                                              │
  │          [Serveur vérifie client1.crt :      │
  │           1. Signé par RaspberryPi-CA ? OUI ✅│
  │           2. Pas révoqué ? OUI ✅           │
  │           3. extendedKeyUsage = clientAuth ? OUI ✅]│
```

### Phase 3 — Échange de Clés Diffie-Hellman

```
Client                                    Serveur
  │                                              │
  │  Choisit secret aléatoire a                 │
  │  Calcule A = g^a mod p                      │
  │── envoie A ─────────────────────────────────►│
  │                                              │  Choisit secret aléatoire b
  │                                              │  Calcule B = g^b mod p
  │◄── reçoit B ─────────────────────────────────│
  │                                              │
  │  Calcule clé K = B^a mod p                  │  Calcule clé K = A^b mod p
  │                    └─── même K ────────────┘│
```

La clé de session K n'a jamais circulé sur le réseau.

### Phase 4 — Tunnel Chiffré Opérationnel

```
Client                                    Serveur
  │                                              │
  │══ Données chiffrées AES-256-GCM + HMAC ════►│
  │◄═ Données chiffrées AES-256-GCM + HMAC ══════│
  │                                              │
  │  IP attribuée : 10.8.0.6                    │
  │  IP serveur  : 10.8.0.1                     │
  │  Tout le trafic passe par le tunnel          │
```

**Résultat final observé dans les logs :**
```
VERIFY OK: CN=RaspberryPi-CA
VERIFY OK: CN=server
TLS: Initial packet from ... using cipher: TLS_AES_256_GCM_SHA384
Initialization Sequence Completed ✅
```

---

## 13. Analyse Cryptographique

### Benchmark réel sur Raspberry Pi 5

Tests effectués avec `openssl speed` sur ARM Cortex-A76 avec accélération matérielle AES :

| Taille de bloc | AES-128-CBC | AES-256-CBC | Différence |
|----------------|------------|-------------|------------|
| 16 bytes | 600 MB/s | 547 MB/s | -9% |
| 64 bytes | 1 309 MB/s | 1 012 MB/s | -23% |
| 256 bytes | 1 724 MB/s | 1 263 MB/s | -27% |
| 1 024 bytes | 1 851 MB/s | 1 332 MB/s | -28% |
| 8 192 bytes | 1 907 MB/s | 1 365 MB/s | -28% |
| 16 384 bytes | 1 912 MB/s | 1 368 MB/s | -28% |

### Pourquoi AES-256 est plus lent ?

AES effectue des "tours" de transformation sur les données :
- AES-128 : **10 tours**
- AES-256 : **14 tours**

Plus de tours = plus de sécurité = légèrement plus lent.

### Pourquoi la différence est-elle si faible ?

Le ARM Cortex-A76 (dans le Raspberry Pi 5) intègre des **instructions matérielles AES** (`aes` extensions ARM). Ces instructions exécutent un tour AES en un seul cycle CPU. La différence de 4 tours supplémentaires est minime.

### Conclusion du benchmark

- **AES-256-CBC** est 28% plus lent que AES-128-CBC
- Mais AES-256 atteint encore **1 368 MB/s** — bien plus que la bande passante Internet maximale d'une connexion domestique (~1 000 Mb/s = 125 MB/s)
- **Recommandation :** Utiliser AES-256-GCM pour la sécurité maximale sans compromis pratique de performance

---

## 14. Guide de Dépannage

### Problème : Le service OpenVPN ne démarre pas

**Symptôme :**
```
Job for openvpn@server.service failed
```

**Diagnostic :**
```bash
sudo cat /var/log/openvpn.log
```

**Erreurs possibles et solutions :**

| Erreur dans les logs | Cause | Solution |
|---------------------|-------|----------|
| `Cannot pre-load keyfile (ta.key)` | ta.key inaccessible par `nobody` | `sudo cp ta.key /etc/openvpn/ && sudo chmod 644 /etc/openvpn/ta.key` |
| `DEPRECATED OPTION: --cipher` | Option obsolète dans OpenVPN 2.5+ | Remplacer `cipher AES-256-CBC` par `data-ciphers AES-256-GCM:AES-256-CBC` |
| `No such file or directory` | Chemin vers un fichier incorrect | Vérifier que tous les fichiers sont dans `/etc/openvpn/` et utiliser des chemins relatifs |
| `TLS Error: TLS key negotiation failed` | Problème avec ta.key côté client | Vérifier que le client utilise `key-direction 1` et le serveur `0` |

### Problème : Le client se connecte mais n'a pas Internet

**Cause probable :** L'IP Forwarding n'est pas activé ou les règles iptables manquent.

**Solution :**
```bash
# Vérifier l'IP Forwarding
cat /proc/sys/net/ipv4/ip_forward
# Doit afficher 1

# Ajouter les règles NAT iptables
sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
```

### Problème : Connexion lente

**Solutions :**
1. Utiliser `AES-256-GCM` plutôt que `AES-256-CBC` (GCM est plus rapide)
2. Augmenter le MTU dans le fichier `.ovpn` : `tun-mtu 1500`
3. Activer la compression (attention : vulnérabilité VORACLE) :  `compress lz4-v2`

---

## 15. Résumé Visuel

### Architecture complète

```
Internet
    │
    │ Trafic chiffré AES-256-GCM
    │ Port UDP 1194
    │
    ▼
┌─────────────────────────────────────────────┐
│         Raspberry Pi 5 (Serveur VPN)        │
│         IP locale : 192.168.50.2            │
│         IP tunnel : 10.8.0.1                │
│                                             │
│  OpenVPN  ←→  Interface tun0               │
│               ↓ IP Forwarding activé        │
│  /etc/openvpn/                              │
│  ├── ca.crt      (certificat CA)            │
│  ├── server.crt  (certificat serveur)       │
│  ├── server.key  (clé privée serveur 🔒)   │
│  ├── dh.pem      (params Diffie-Hellman)    │
│  ├── ta.key      (clé TLS Auth)            │
│  └── server.conf (configuration)           │
└─────────────────────────────────────────────┘
    │
    │ Réseau local (192.168.50.x)
    ▼
┌─────────────────────────────────────────────┐
│         Réseau local sécurisé               │
│         Accessible uniquement via VPN       │
└─────────────────────────────────────────────┘
```

### Chaîne de confiance PKI

```
RaspberryPi-CA (ca.crt + ca.key)
    │ signe
    ├──────────► server.crt  [extendedKeyUsage: serverAuth]
    │             └── clé privée : server.key (dans /etc/openvpn/)
    │
    └──────────► client1.crt [extendedKeyUsage: clientAuth]
                  └── clé privée : client1.key (dans le .ovpn)
```

### Couches de sécurité empilées

```
┌──────────────────────────────────────────────┐
│  Couche 1 : ta.key (HMAC pré-TLS)           │
│  → Bloque tout paquet sans signature valide  │
├──────────────────────────────────────────────┤
│  Couche 2 : TLS 1.3 + Certificats X.509      │
│  → Authentification mutuelle serveur/client  │
├──────────────────────────────────────────────┤
│  Couche 3 : Diffie-Hellman (PFS)             │
│  → Clé de session éphémère, jamais transmise │
├──────────────────────────────────────────────┤
│  Couche 4 : AES-256-GCM                      │
│  → Chiffrement + intégrité des données       │
├──────────────────────────────────────────────┤
│  Couche 5 : HMAC-SHA256                      │
│  → Intégrité de chaque paquet                │
└──────────────────────────────────────────────┘
```

---

## Glossaire

| Terme | Définition |
|-------|-----------|
| **VPN** | Virtual Private Network — réseau privé virtuel via un tunnel chiffré |
| **PKI** | Public Key Infrastructure — système de gestion des certificats et clés |
| **CA** | Certificate Authority — autorité qui signe et valide les certificats |
| **TLS** | Transport Layer Security — protocole d'établissement de connexion sécurisée |
| **X.509** | Standard définissant le format des certificats numériques |
| **AES** | Advanced Encryption Standard — algorithme de chiffrement symétrique |
| **GCM** | Galois/Counter Mode — mode d'AES qui chiffre ET authentifie simultanément |
| **CBC** | Cipher Block Chaining — mode d'AES, plus ancien, chiffrement seul |
| **HMAC** | Hash-based Message Authentication Code — empreinte d'intégrité d'un message |
| **SHA-256** | Secure Hash Algorithm 256 bits — fonction de hachage cryptographique |
| **DH** | Diffie-Hellman — protocole d'échange de clés sur canal public |
| **PFS** | Perfect Forward Secrecy — garantit que les sessions passées restent sécurisées |
| **CSR** | Certificate Signing Request — requête de certificat avant signature CA |
| **CRL** | Certificate Revocation List — liste des certificats révoqués |
| **tun** | Interface réseau virtuelle de type tunnel (couche 3) |
| **UDP** | User Datagram Protocol — protocole réseau sans garantie de livraison, rapide |
| **RSA** | Algorithme de cryptographie asymétrique (clé publique/privée) |
| **MASQUERADE** | Règle NAT qui traduit l'IP source des paquets VPN → permet l'accès Internet |
| **IP Forwarding** | Capacité du noyau Linux à transférer des paquets entre interfaces réseau |
| **systemd** | Gestionnaire de services Linux — gère le démarrage/arrêt des services |
| **SCP** | Secure Copy — copie de fichiers via SSH entre machines |

---

*Document rédigé pour l'explication détaillée du projet OpenVPN sur Raspberry Pi 5 de **Hanane AIT BAH**.*
