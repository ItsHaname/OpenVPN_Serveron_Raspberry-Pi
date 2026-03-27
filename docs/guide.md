# 🔐 Guide d'installation — OpenVPN Server sur Raspberry Pi 5

> **Auteure :** Hanane AIT BAH  
> **Projet :** Serveur VPN sécurisé avec analyse cryptographique  
> **Plateforme :** Raspberry Pi 5 — Raspberry Pi OS 64-bit  
> **Date :** Mars 2026

---

## 📋 Prérequis

- Raspberry Pi 5 avec Raspberry Pi OS installé
- Accès SSH ou terminal direct
- OpenVPN et Easy-RSA installés (`sudo apt install openvpn easy-rsa`)
- Un PC client (ici : Arch Linux)

---

## Étape 1 — Initialiser la PKI

La première étape consiste à initialiser l'infrastructure de clés publiques (PKI) avec Easy-RSA. C'est le répertoire qui contiendra tous les certificats et clés du projet.

```bash
cd ~/OpenVPN_Serveron_Raspberry-Pi
./easyrsa init-pki
```

![Étape 1 — Init PKI](https://github.com/user-attachments/assets/6bc7d4e5-c280-4275-a791-1d1d2fb5ed65)

✅ Easy-RSA crée automatiquement le dossier `pki/` avec la structure nécessaire.

---

## Étape 2 — Créer l'Autorité de Certification (CA)

La CA est la racine de confiance de tout le système. Elle signe tous les certificats du serveur et des clients.

```bash
./easyrsa build-ca nopass
```

> Quand le Common Name est demandé, entrer : `RaspberryPi-CA`

✅ Le fichier `pki/ca.crt` est généré — c'est le certificat public de la CA.

---

## Étape 3 — Créer le certificat du serveur

Ce certificat prouve l'identité du serveur VPN auprès des clients qui se connectent.

```bash
./easyrsa gen-req server nopass
```

> Common Name : `server`

![Étape 3 — Certificat serveur](https://github.com/user-attachments/assets/327758d2-0c4b-4254-8727-e3bc50428fac)

✅ Deux fichiers sont créés :
- `pki/reqs/server.req` — la requête de certificat
- `pki/private/server.key` — la clé privée du serveur

---

## Étape 4 — Signer le certificat du serveur avec la CA

La requête `.req` n'est pas encore un certificat valide. La CA doit la signer pour lui donner sa valeur — c'est comme apposer un tampon officiel.

```bash
./easyrsa sign-req server server
```

> Confirmer en tapant : `yes`

![Étape 4 — Signature certificat serveur](https://github.com/user-attachments/assets/73c1f1ca-de3e-44de-9098-dc024b3d4897)

✅ Le fichier `pki/issued/server.crt` est généré et valide jusqu'en **2028**.

---

## Étape 5 — Générer les paramètres Diffie-Hellman

Ces paramètres permettent d'établir une clé de session unique à chaque connexion. C'est ce qui garantit le **Perfect Forward Secrecy** : même si la clé du serveur est compromise un jour, les sessions passées restent protégées.

> ⚠️ Cette commande est lente (2 à 5 minutes sur Raspberry Pi) — c'est tout à fait normal.

```bash
./easyrsa gen-dh
```

![Étape 5 — Diffie-Hellman](https://github.com/user-attachments/assets/cd7616f1-7fea-4882-b446-0a915d77b753)

✅ Le fichier `pki/dh.pem` est généré (paramètres 2048 bits).

---

## Étape 6 — Générer la clé TLS Auth

Cette clé ajoute une couche de sécurité supplémentaire : tout paquet non signé avec cette clé est rejeté immédiatement, avant même le handshake TLS. Cela protège le serveur contre les attaques DDoS et les scans de port.

```bash
openvpn --genkey secret pki/ta.key
```

![Étape 6 — TLS Auth](https://github.com/user-attachments/assets/471e05fa-2fa2-447a-94c2-b4af99ef2478)

✅ Aucun message = succès sur Linux. Le fichier `pki/ta.key` est créé.

---

## Étape 7 — Créer le certificat client

Chaque client qui se connecte au VPN a besoin de son propre certificat pour s'authentifier. On crée ici le certificat pour `client1`.

```bash
./easyrsa gen-req client1 nopass
```

> Common Name : `client1`

![Étape 7 — Certificat client](https://github.com/user-attachments/assets/5c068a5d-f2e4-4a2d-8199-028c4db8f964)

✅ La clé `pki/private/client1.key` et la requête `pki/reqs/client1.req` sont créées.

---

## Étape 8 — Signer le certificat client avec la CA

Comme pour le serveur, la CA doit valider le certificat du client pour qu'il soit reconnu comme de confiance.

```bash
./easyrsa sign-req client client1
```

> Confirmer en tapant : `yes`

![Étape 8 — Signature certificat client](https://github.com/user-attachments/assets/fd086b8a-3623-47e4-82cc-c1b829a427d4)

✅ Le fichier `pki/issued/client1.crt` est signé et valide jusqu'en **2028**.

---

## Étape 9 — Vérifier tous les fichiers PKI

Avant de configurer OpenVPN, on s'assure que tous les fichiers nécessaires sont bien présents.

```bash
ls pki/ca.crt pki/issued/server.crt pki/private/server.key \
   pki/dh.pem pki/ta.key pki/issued/client1.crt pki/private/client1.key
```

![Étape 9 — Vérification PKI](https://github.com/user-attachments/assets/0fc27459-32ee-45a7-aa93-4f34f7b18382)

| Fichier | Rôle |
|---|---|
| `pki/ca.crt` | Certificat de l'Autorité de Certification |
| `pki/issued/server.crt` | Certificat du serveur VPN |
| `pki/private/server.key` | Clé privée du serveur |
| `pki/dh.pem` | Paramètres Diffie-Hellman |
| `pki/ta.key` | Clé TLS Auth |
| `pki/issued/client1.crt` | Certificat du client |
| `pki/private/client1.key` | Clé privée du client |

✅ Tous les fichiers sont présents — la PKI est complète.

---

## Étape 10 — Configurer le serveur OpenVPN

On copie les fichiers dans `/etc/openvpn/` puis on écrit le fichier de configuration principal.

```bash
sudo cp pki/ca.crt pki/issued/server.crt pki/private/server.key \
        pki/dh.pem pki/ta.key /etc/openvpn/

sudo nano /etc/openvpn/server.conf
```

Contenu du fichier `server.conf` :

```ini
port 1194
proto udp
dev tun

ca ca.crt
cert server.crt
key server.key
dh dh.pem
tls-auth ta.key 0

server 10.8.0.0 255.255.255.0
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"

data-ciphers AES-256-GCM:AES-256-CBC
data-ciphers-fallback AES-256-CBC
auth SHA256
tls-version-min 1.2
topology subnet

keepalive 10 120
user nobody
group nogroup
persist-key
persist-tun

status /var/log/openvpn-status.log
log /var/log/openvpn.log
verb 3
```

![Étape 10 — Configuration serveur](https://github.com/user-attachments/assets/205b0da6-232e-4145-a7b2-fc57f4e662d2)

---

## Étape 11 — Activer l'IP Forwarding

Par défaut, le Raspberry Pi ne transfère pas les paquets entre les interfaces réseau. Cette activation est indispensable pour que le trafic VPN puisse circuler vers le réseau local.

```bash
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

![Étape 11 — IP Forwarding](https://github.com/user-attachments/assets/53a9e01b-d0d2-4438-a4ed-8a2445582147)

✅ `net.ipv4.ip_forward = 1` confirme l'activation.

---

## Étape 12 — Démarrer le serveur OpenVPN

On active le service pour qu'il démarre automatiquement au reboot, puis on le lance.

```bash
sudo systemctl enable openvpn@server
sudo systemctl start openvpn@server
sudo systemctl status openvpn@server
```

![Étape 12 — Démarrage OpenVPN](https://github.com/user-attachments/assets/d1bca22e-61f3-4bf8-b4ea-79a27f8a5082)

✅ `Active: active (running)` — le serveur OpenVPN est opérationnel.

---

## Étape 13 — Vérifier l'interface tunnel TUN

On vérifie que l'interface réseau virtuelle `tun0` a bien été créée par OpenVPN.

```bash
ip addr show tun0
```

![Étape 13 — Interface tun0](https://github.com/user-attachments/assets/04514c6f-e458-4271-89a2-26844778e3ee)

✅ Résultats confirmés :
- Interface `tun0` active
- IP serveur VPN : `10.8.0.1`
- Les clients reçoivent des IPs dans la plage `10.8.0.x`

---

## Étape 14 — Créer le fichier client `.ovpn`

Ce fichier regroupe toute la configuration et les certificats nécessaires au client. C'est le seul fichier à transmettre au client pour qu'il puisse se connecter.

```bash
hostname -I
```

![Étape 14 — IP du Raspberry Pi](https://github.com/user-attachments/assets/f14173b6-abfe-4dc6-9ccb-740f4b5c24cc)

IP utilisée : `192.168.50.2`

```bash
sudo bash -c 'cat > /home/pi/OpenVPN_Serveron_Raspberry-Pi/config/client1.ovpn << EOF
client
dev tun
proto udp
remote 192.168.50.2 1194
resolv-retry infinite
nobind
persist-key
persist-tun

data-ciphers AES-256-GCM:AES-256-CBC
data-ciphers-fallback AES-256-CBC
auth SHA256
tls-version-min 1.2
key-direction 1
verb 3
<ca>
'"$(cat /etc/openvpn/ca.crt)"'
</ca>
<cert>
'"$(cat /home/pi/OpenVPN_Serveron_Raspberry-Pi/pki/issued/client1.crt)"'
</cert>
<key>
'"$(cat /home/pi/OpenVPN_Serveron_Raspberry-Pi/pki/private/client1.key)"'
</key>
<tls-auth>
'"$(cat /etc/openvpn/ta.key)"'
</tls-auth>
EOF'
```

![Étape 14 — Fichier ovpn créé](https://github.com/user-attachments/assets/ec7ff5cd-bbd2-44e1-bd31-3405de3d985f)

✅ Le fichier `config/client1.ovpn` est généré avec tous les certificats intégrés.

---

## Étape 15 — Transférer le fichier client vers le PC

On copie le fichier `.ovpn` depuis le Raspberry Pi vers le PC client via SCP.

```bash
scp pi@192.168.50.2:/home/pi/OpenVPN_Serveron_Raspberry-Pi/config/client1.ovpn ~/
```

![Étape 15 — Transfert SCP](https://github.com/user-attachments/assets/4974efb2-6615-4ad6-ac83-a02b4d153ac7)

✅ `100% 8357 bytes` — transfert réussi en moins d'une seconde.

---

## Étape 16 — Installer OpenVPN sur le PC client (Arch Linux)

```bash
sudo pacman -S openvpn
```

![Étape 16 — Installation OpenVPN Arch](https://github.com/user-attachments/assets/d8764088-3f78-43d2-bdfb-85b0cdb53a5f)

✅ OpenVPN 2.7.0 installé avec succès.

---

## Étape 17 — Se connecter au VPN

On lance la connexion depuis le PC client avec le fichier `.ovpn`.

```bash
sudo openvpn --config ~/client1.ovpn
```
<img width="936" height="986" alt="image" src="https://github.com/user-attachments/assets/e05c6a85-3d74-481a-8697-b84ca6373c93" />

![Étape 17 — Connexion VPN](https://github.com/user-attachments/assets/352100af-0ee6-4485-8a20-3c1bc4116da4)

✅ La ligne `Initialization Sequence Completed` confirme la connexion établie.

Détails de la session :

| Paramètre | Valeur |
|---|---|
| Chiffrement | AES-256-GCM |
| Protocole TLS | TLSv1.3 — TLS_AES_256_GCM_SHA384 |
| CA vérifiée | `VERIFY OK: CN=RaspberryPi-CA` |
| Serveur vérifié | `VERIFY OK: CN=server` |
| IP client VPN | `10.8.0.6` |
| IP serveur VPN | `10.8.0.5` |

---

## Étape 18 — Tester la connectivité VPN

Depuis un second terminal sur le PC client, on ping le serveur VPN.

```bash
ping 10.8.0.1
```

![Étape 18 — Test ping](https://github.com/user-attachments/assets/ecfc77e1-317d-4a0c-9d71-4c50149e99df)

✅ Résultats :
- **0% packet loss** — aucune perte de paquets
- **Latence moyenne : 1.35 ms** — connexion très rapide
- Le tunnel chiffré fonctionne parfaitement

---

## Étape 19 — Benchmark cryptographique : AES-128 vs AES-256

C'est la partie analyse de performance du projet. On mesure le débit des deux algorithmes directement sur le Raspberry Pi 5 avec OpenSSL.

```bash
openssl speed -evp aes-128-cbc
openssl speed -evp aes-256-cbc
```

![Étape 19 — Benchmark AES-128](https://github.com/user-attachments/assets/57afed29-0b1d-454e-b782-6b7f189a26a5)

![Étape 19 — Benchmark AES-256](https://github.com/user-attachments/assets/14cd6959-c7f0-4c16-83a1-d4afcb88abef)

### Résultats comparatifs

| Taille de bloc | AES-128-CBC | AES-256-CBC | Différence |
|---|---|---|---|
| 16 bytes | 600 MB/s | 547 MB/s | -9% |
| 64 bytes | 1 309 MB/s | 1 012 MB/s | -23% |
| 256 bytes | 1 724 MB/s | 1 263 MB/s | -27% |
| 1 024 bytes | 1 851 MB/s | 1 332 MB/s | -28% |
| 8 192 bytes | 1 907 MB/s | 1 365 MB/s | -28% |
| 16 384 bytes | 1 912 MB/s | 1 368 MB/s | -28% |

![Étape 19 — Résultats benchmark](https://github.com/user-attachments/assets/47fd11a2-9390-4194-bb0e-5d3bee015e84)

### Analyse

AES-128-CBC est environ **28% plus rapide** qu'AES-256-CBC sur le Raspberry Pi 5. Cependant, même AES-256 atteint **1.3 GB/s** grâce à l'accélération matérielle ARM Cortex-A76, ce qui est largement suffisant pour un usage VPN personnel.

> **Recommandation :** Utiliser **AES-256-GCM** pour la sécurité maximale — la différence de performance est négligeable en conditions réelles d'utilisation VPN.

---

## 🏁 Récapitulatif

| Composant | Statut | Détail |
|---|---|---|
| PKI | ✅ | CA + certificats serveur et client |
| Serveur OpenVPN | ✅ | Actif sur UDP 1194 |
| Tunnel TUN | ✅ | Interface `tun0` — IP `10.8.0.1` |
| Chiffrement | ✅ | AES-256-GCM |
| Authentification | ✅ | Certificats X.509 mutuels |
| Forward Secrecy | ✅ | Diffie-Hellman 2048 bits |
| Connexion client | ✅ | PC Arch Linux — IP `10.8.0.6` |
| Latence VPN | ✅ | ~1.35 ms — 0% perte |

---

*Guide rédigé par **Hanane AIT BAH** — [@ItsHaname](https://github.com/ItsHaname)*
