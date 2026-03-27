# 🔐 OpenVPN Server on Raspberry Pi 5 — Cryptographic Security Analysis

<div align="center">

![Raspberry Pi](https://img.shields.io/badge/Raspberry%20Pi%205-A22846?style=for-the-badge&logo=raspberry-pi&logoColor=white)
![OpenVPN](https://img.shields.io/badge/OpenVPN-EA7E20?style=for-the-badge&logo=openvpn&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![TLS](https://img.shields.io/badge/TLS%201.3-005F99?style=for-the-badge&logo=letsencrypt&logoColor=white)
![AES](https://img.shields.io/badge/AES--256-4CAF50?style=for-the-badge&logo=gnupg&logoColor=white)

**Design and deployment of a secure VPN server with PKI and cryptographic performance analysis.**

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Objectives](#-objectives)
- [System Architecture](#-system-architecture)
- [Technologies Used](#-technologies-used)
- [Public Key Infrastructure (PKI)](#-public-key-infrastructure-pki)
- [Installation & Configuration](#-installation--configuration)
- [Cryptographic Analysis](#-cryptographic-analysis)
- [Security Properties](#-security-properties)
- [Performance Comparison: AES-128 vs AES-256](#-performance-comparison-aes-128-vs-aes-256)
- [Results](#-results)
- [Author](#-author)

---

## 🌐 Overview

This project presents the **design and implementation of a secure VPN server** using OpenVPN deployed on a **Raspberry Pi 5**. It goes beyond a basic VPN setup by integrating a full **Public Key Infrastructure (PKI)** and evaluating the security and performance of different encryption algorithms.

The system creates an encrypted tunnel between a remote client (PC or smartphone) and a local network hosted behind the Raspberry Pi, ensuring **confidentiality**, **integrity**, and **mutual authentication**.

---

## 🎯 Objectives

- ✅ Deploy an OpenVPN server on a Raspberry Pi 5
- ✅ Implement a complete Public Key Infrastructure (PKI) with Easy-RSA
- ✅ Secure all communications using TLS
- ✅ Analyze VPN security properties (confidentiality, integrity, authentication)
- ✅ Compare performance of AES-128 and AES-256 encryption on constrained hardware

---

## 🏗️ System Architecture

```
                          Internet
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
  ┌─────▼──────┐     ┌───────▼────────┐          │
  │ VPN Client │◄───►│ OpenVPN Server │          │
  │  (PC / 📱) │     │ Raspberry Pi 5 │          │
  └────────────┘     └───────┬────────┘          │
   Encrypted Tunnel          │                   │
   (TLS + AES)        ┌──────▼──────┐            │
                      │  Secure LAN  │            │
                      │  (Private    │            │
                      │   Network)   │            │
                      └─────────────┘            │
        └──────────────────────────────────────────┘
```

The architecture is composed of **three main components**:

| Component | Role |
|---|---|
| 🖥️ VPN Client | PC or smartphone connecting over the Internet |
| 🍓 OpenVPN Server (Raspberry Pi 5) | Handles encrypted tunnels and routing |
| 🔒 Secure Local Network | Private network accessible only through the VPN |

---

## 🛠️ Technologies Used

| Technology | Purpose |
|---|---|
| **OpenVPN** | VPN tunnel management |
| **Easy-RSA** | PKI and certificate management |
| **TLS 1.3** | Transport Layer Security for the control channel |
| **AES-128 / AES-256** | Data encryption (data channel) |
| **Raspberry Pi OS** | Linux-based server OS (Debian) |
| **HMAC-SHA256** | Message integrity and authentication |

---

## 🔑 Public Key Infrastructure (PKI)

A full PKI is implemented using **Easy-RSA** to enable mutual authentication between the server and all clients.

```
Certificate Authority (CA)  ← Root of Trust
        │
        ├──► Server Certificate    (signed by CA)
        │
        ├──► Client Certificate 1  (signed by CA)
        │
        └──► Client Certificate N  (signed by CA)
```

### PKI Components

- **CA (Certificate Authority)** — The root of trust; signs all certificates
- **Server Certificate** — Proves the server's identity to connecting clients
- **Client Certificates** — Unique per client; enables individual revocation (CRL)
- **Diffie-Hellman Parameters** — Ensures Perfect Forward Secrecy (PFS)
- **TLS Auth Key (ta.key)** — Additional HMAC layer against DDoS and unauthorized connections

---

## ⚙️ Installation & Configuration

### Prerequisites

- Raspberry Pi 5 running Raspberry Pi OS (64-bit recommended)
- Static local IP or dynamic DNS configured
- Port forwarding: `UDP 1194` opened on your router

### 1. Install Dependencies

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install openvpn easy-rsa -y
```

### 2. Set Up Easy-RSA PKI

```bash
make-cadir ~/openvpn-ca
cd ~/openvpn-ca

# Initialize the PKI
./easyrsa init-pki

# Build the Certificate Authority
./easyrsa build-ca

# Generate server certificate and key
./easyrsa gen-req server nopass
./easyrsa sign-req server server

# Generate Diffie-Hellman parameters
./easyrsa gen-dh

# Generate TLS authentication key
openvpn --genkey secret ta.key
```

### 3. Generate Client Certificate

```bash
cd ~/openvpn-ca
./easyrsa gen-req client1 nopass
./easyrsa sign-req client client1
```

### 4. Configure the OpenVPN Server

```bash
sudo cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf /etc/openvpn/
sudo nano /etc/openvpn/server.conf
```

Key configuration parameters:

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
cipher AES-256-CBC        # or AES-128-CBC for comparison
auth SHA256

keepalive 10 120
user nobody
group nogroup
persist-key
persist-tun

verb 3
```

### 5. Enable IP Forwarding & Start the Server

```bash
# Enable IP forwarding
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Enable and start OpenVPN
sudo systemctl enable openvpn@server
sudo systemctl start openvpn@server
sudo systemctl status openvpn@server
```

---

## 🔬 Cryptographic Analysis

### Encryption — AES (Advanced Encryption Standard)

OpenVPN uses AES for the **data channel** (encrypting actual traffic):

| Mode | Key Size | Block Size | Security Level |
|---|---|---|---|
| AES-128-CBC | 128 bits | 128 bits | Very High (~2¹²⁸) |
| AES-256-CBC | 256 bits | 128 bits | Maximum (~2²⁵⁶) |

### Key Exchange — TLS + Diffie-Hellman

The **control channel** uses TLS 1.3 with Diffie-Hellman key exchange, ensuring:
- **Perfect Forward Secrecy (PFS)**: Session keys are ephemeral — compromising the server key does not expose past sessions
- **Authenticated Key Exchange**: Both parties verify each other via PKI certificates

### Integrity — HMAC-SHA256

Each data packet is signed with HMAC-SHA256, ensuring:
- No packet tampering goes undetected
- Protection against replay attacks

---

## 🛡️ Security Properties

| Property | Mechanism | Description |
|---|---|---|
| 🔒 **Confidentiality** | AES-256-CBC | All traffic is encrypted; intercepted packets are unreadable |
| ✅ **Integrity** | HMAC-SHA256 | Any modification to packets is detected and rejected |
| 👤 **Authentication** | PKI + X.509 Certificates | Both client and server prove their identity mutually |
| 🔄 **Perfect Forward Secrecy** | Ephemeral DH Keys | Past sessions remain secure even if long-term keys are compromised |
| 🚫 **Anti-Replay** | TLS Sequence Numbers | Prevents attackers from replaying captured packets |

---

## 📊 Performance Comparison: AES-128 vs AES-256

### Benchmark Methodology

Tests were conducted using `openssl speed` on the Raspberry Pi 5 under identical load conditions.

```bash
# Benchmark AES-128
openssl speed -evp aes-128-cbc

# Benchmark AES-256
openssl speed -evp aes-256-cbc
```

### Expected Results on Raspberry Pi 5

| Algorithm | Throughput (approx.) | CPU Usage | Recommended Use |
|---|---|---|---|
| **AES-128-CBC** | ~300 MB/s | Lower | High-throughput scenarios |
| **AES-256-CBC** | ~250 MB/s | Slightly higher | Maximum security required |

> ⚠️ **Note:** The Raspberry Pi 5 includes hardware AES acceleration (ARM Cortex-A76), significantly reducing the performance gap between AES-128 and AES-256.

### Conclusion

The performance difference between AES-128 and AES-256 on the Raspberry Pi 5 is **minimal** due to hardware acceleration. For most use cases, **AES-256** is recommended given its superior security margin at negligible cost.

---

## 📈 Results

| Metric | Value |
|---|---|
| ✅ VPN Tunnel Established | Yes |
| 🔐 Mutual Authentication | PKI Certificates (X.509) |
| 🔑 Encryption | AES-256-CBC |
| 🔏 Integrity | HMAC-SHA256 |
| 🔄 Forward Secrecy | Yes (Ephemeral DH) |
| 📡 Protocol | OpenVPN over UDP 1194 |
| 🖥️ Hardware | Raspberry Pi 5 (ARM Cortex-A76) |

---

## 👤 Author

**Hanane AIT BAH**  
🔗 [@ItsHaname](https://github.com/ItsHaname)

---

<div align="center">

⭐ If you found this project useful, feel free to **star** the repository!

</div>
