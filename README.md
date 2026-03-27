# OpenVPN Server on Raspberry Pi 5 with Cryptographic Security Analysis

## Project Overview

This project presents the design and implementation of a secure VPN server using OpenVPN deployed on a Raspberry Pi 5. It also includes an analysis of the underlying cryptographic mechanisms and a performance comparison of encryption algorithms.

The objective is to go beyond basic VPN setup by integrating a Public Key Infrastructure (PKI) and evaluating security and performance aspects.

---

## Objectives

- Deploy an OpenVPN server on Raspberry Pi 5
- Implement a Public Key Infrastructure (PKI)
- Secure communications using TLS
- Analyze VPN security (confidentiality, integrity, authentication)
- Compare AES-128 and AES-256 encryption performance

---

## System Architecture

The system is composed of three main components:

- VPN Client (PC or smartphone)
- OpenVPN Server hosted on Raspberry Pi 5
- Secure Local Network

Communication between client and server is established through an encrypted tunnel over the Internet.

---

## Technologies Used

- OpenVPN
- Easy-RSA (PKI management)
- TLS (Transport Layer Security)
- AES (Advanced Encryption Standard)
- Raspberry Pi OS (Linux-based)

---

## Public Key Infrastructure (PKI)

The VPN relies on a PKI for authentication:

- Certificate Authority (CA)
- Server certificate
- Client certificates

This ensures mutual authentication between client and server.

---

## Installation and Configuration

### 1. Install dependencies

```bash
sudo apt update
sudo apt install openvpn easy-rsa
