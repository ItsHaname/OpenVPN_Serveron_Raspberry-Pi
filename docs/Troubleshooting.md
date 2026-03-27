# Troubleshooting — OpenVPN Server sur Raspberry Pi 5

**Auteure :** Hanane AIT BAH  
**Projet :** OpenVPN Server on Raspberry Pi 5

---

## Problème 1 — Échec au démarrage du service OpenVPN

### Symptôme

Le service OpenVPN refuse de démarrer avec le message :

```
Job for openvpn@server.service failed because the control process exited with error code.
```

![Erreur démarrage OpenVPN](https://github.com/user-attachments/assets/2ca4b81f-7e01-4c34-b2c6-13eb81b19836)

---

### Diagnostic

Consultation des logs pour identifier la cause exacte :

```bash
sudo cat /var/log/openvpn.log
```

**Erreurs identifiées :**

```
Cannot pre-load keyfile (/home/pi/.../pki/ta.key)
Exiting due to fatal error
DEPRECATED OPTION: --cipher set to 'AES-256-CBC' but missing in --data-ciphers
```

Deux problèmes distincts :
- Le fichier `ta.key` n'est pas accessible par le service (permissions insuffisantes)
- L'option `--cipher` est dépréciée dans OpenVPN 2.5+ et doit être remplacée par `--data-ciphers`

---

### Solution

**Étape 1 — Copier les fichiers dans `/etc/openvpn/`**

Le service OpenVPN tourne en tant que `nobody` et ne peut pas accéder aux fichiers dans `/home/pi/`. La solution est de copier tous les fichiers nécessaires directement dans `/etc/openvpn/` :

```bash
sudo cp pki/ca.crt pki/issued/server.crt pki/private/server.key \
        pki/dh.pem pki/ta.key /etc/openvpn/
sudo chmod 644 /etc/openvpn/ta.key
```

**Étape 2 — Mettre à jour `server.conf`**

Remplacer les chemins absolus par des chemins relatifs et corriger les options dépréciées :

```bash
sudo nano /etc/openvpn/server.conf
```

Contenu corrigé :

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

![Configuration corrigée](https://github.com/user-attachments/assets/674ea707-05af-4a04-886b-3ec6d7233014)

**Étape 3 — Redémarrer le service**

```bash
sudo systemctl restart openvpn@server
sudo systemctl status openvpn@server
```

---

### Résultat

![Service actif](https://github.com/user-attachments/assets/108edd53-e3bd-4084-bb5d-8deca5b780eb)

✅ `Active: active (running)` — le serveur OpenVPN est opérationnel.

---

### Causes et solutions résumées

| Erreur | Cause | Solution |
|---|---|---|
| `Cannot pre-load keyfile` | `ta.key` inaccessible par `nobody` | Copier dans `/etc/openvpn/` et `chmod 644` |
| `DEPRECATED OPTION: --cipher` | Option obsolète depuis OpenVPN 2.5 | Remplacer par `data-ciphers` |
| Chemins absolus `/home/pi/...` | Service sans accès au home | Utiliser chemins relatifs dans `/etc/openvpn/` |

---

### Conseil

> Si le service échoue au démarrage, toujours consulter `/var/log/openvpn.log` en premier — il contient le message d'erreur exact et évite de chercher au mauvais endroit.

```bash
sudo cat /var/log/openvpn.log
# ou en temps réel :
sudo journalctl -fu openvpn@server
```

---

*Rédigé par **Hanane AIT BAH** — [@ItsHaname](https://github.com/ItsHaname)*
