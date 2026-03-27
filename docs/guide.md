## Étape 1 — Initialiser la PKI

C'est la première chose à faire : initialiser l'infrastructure de clés avec Easy-RSA.

<img width="1040" height="828" alt="image" src="https://github.com/user-attachments/assets/6bc7d4e5-c280-4275-a791-1d1d2fb5ed65" />

## Etape 3 — Créer le certificat du serveur

<img width="1040" height="828" alt="image" src="https://github.com/user-attachments/assets/327758d2-0c4b-4254-8727-e3bc50428fac" />

## Étape 4 — Signer le certificat du serveur avec la CA
Pourquoi ? La requête .req créée à l'étape précédente n'est pas encore un certificat valide. La CA doit la signer pour lui donner sa valeur. C'est comme un tampon officiel.

<img width="1040" height="828" alt="image" src="https://github.com/user-attachments/assets/73c1f1ca-de3e-44de-9098-dc024b3d4897" />

## Étape 5 — Générer les paramètres Diffie-Hellman

Pourquoi ? Ces paramètres permettent d'établir une clé de session unique à chaque connexion. Même si quelqu'un enregistre le trafic aujourd'hui et vole la clé du serveur demain, il ne pourra pas déchiffrer les anciennes sessions. C'est ce qu'on appelle le Perfect Forward Secrecy.
⚠️ Cette commande est lente (2-5 minutes sur Raspberry Pi), c'est normal !

<img width="1296" height="294" alt="image" src="https://github.com/user-attachments/assets/cd7616f1-7fea-4882-b446-0a915d77b753" />
## Étape 6 — Générer la clé TLS Auth
Pourquoi ? Cette clé ajoute une couche de sécurité supplémentaire. Elle protège le serveur contre les attaques DDoS et les scans de port. Tout paquet qui n'est pas signé avec cette clé est rejeté immédiatement, avant même le handshake TLS.

<img width="1250" height="76" alt="image" src="https://github.com/user-attachments/assets/471e05fa-2fa2-447a-94c2-b4af99ef2478" />
## Etape 7 — Créer le certificat client
Pourquoi ? Chaque client qui se connecte au VPN a besoin de son propre certificat pour s'authentifier. On va créer un certificat pour client1.

<img width="1296" height="774" alt="image" src="https://github.com/user-attachments/assets/5c068a5d-f2e4-4a2d-8199-028c4db8f964" />
## Étape 8 — Signer le certificat client avec la CA
Pourquoi ? Même chose que pour le serveur — la CA doit tamponner le certificat du client pour le rendre valide et de confiance.

<img width="1064" height="837" alt="image" src="https://github.com/user-attachments/assets/fd086b8a-3623-47e4-82cc-c1b829a427d4" />
 Le certificat client client1.crt est signé et valide jusqu'en 2028.
## Étape 9 — Vérifier que tous les fichiers PKI sont bien là
Pourquoi ? Avant de configurer OpenVPN, on vérifie qu'on a bien tous les fichiers nécessaires.

<img width="1290" height="132" alt="image" src="https://github.com/user-attachments/assets/0fc27459-32ee-45a7-aa93-4f34f7b18382" />

<img width="1004" height="466" alt="image" src="https://github.com/user-attachments/assets/58a28444-67c6-41e5-bef8-97316d38d033" />
## Étape 10 — Configurer le serveur OpenVPN
Pourquoi ? On va maintenant écrire le fichier de configuration qui dit à OpenVPN comment fonctionner : quel port, quel chiffrement, quels certificats utiliser.
sudo nano /etc/openvpn/server.conf
```
port 1194
proto udp
dev tun

ca /home/pi/OpenVPN_Serveron_Raspberry-Pi/pki/ca.crt
cert /home/pi/OpenVPN_Serveron_Raspberry-Pi/pki/issued/server.crt
key /home/pi/OpenVPN_Serveron_Raspberry-Pi/pki/private/server.key
dh /home/pi/OpenVPN_Serveron_Raspberry-Pi/pki/dh.pem
tls-auth /home/pi/OpenVPN_Serveron_Raspberry-Pi/pki/ta.key 0

server 10.8.0.0 255.255.255.0
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"

cipher AES-256-CBC
auth SHA256
tls-version-min 1.2

keepalive 10 120
user nobody
group nogroup
persist-key
persist-tun

status /var/log/openvpn-status.log
log /var/log/openvpn.log
verb 3
```

<img width="1114" height="662" alt="image" src="https://github.com/user-attachments/assets/205b0da6-232e-4145-a7b2-fc57f4e662d2" />
## Étape 11 — Activer l'IP Forwarding
Pourquoi ? Par défaut, le Raspberry Pi ne transfère pas les paquets entre les interfaces réseau. On doit l'activer pour que le trafic VPN puisse circuler entre le client et le réseau local.

<img width="1184" height="119" alt="image" src="https://github.com/user-attachments/assets/53a9e01b-d0d2-4438-a4ed-8a2445582147" />
## Étape 12 — Démarrer le serveur OpenVPN

Pourquoi ? On lance maintenant le service OpenVPN et on l'active au démarrage automatique du Raspberry Pi.
```
sudo systemctl enable openvpn@server
sudo systemctl start openvpn@server
sudo systemctl status openvpn@server
```






