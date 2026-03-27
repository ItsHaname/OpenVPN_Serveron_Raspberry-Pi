# Benchmark cryptographique — AES-128 vs AES-256

**Auteure :** Hanane AIT BAH
**Plateforme :** Raspberry Pi 5 — ARM Cortex-A76
**Outil :** OpenSSL 3.0.19

---

## Commandes utilisées
```bash
openssl speed -evp aes-128-cbc
openssl speed -evp aes-256-cbc
```

---

## Résultats

| Taille de bloc | AES-128-CBC | AES-256-CBC | Différence |
|---|---|---|---|
| 16 bytes | 600 MB/s | 547 MB/s | -9% |
| 64 bytes | 1 309 MB/s | 1 012 MB/s | -23% |
| 256 bytes | 1 724 MB/s | 1 263 MB/s | -27% |
| 1 024 bytes | 1 851 MB/s | 1 332 MB/s | -28% |
| 8 192 bytes | 1 907 MB/s | 1 365 MB/s | -28% |
| 16 384 bytes | 1 912 MB/s | 1 368 MB/s | -28% |

---

## Analyse

- AES-128-CBC est **28% plus rapide** qu'AES-256-CBC
- Grâce à l'accélération matérielle ARM, AES-256 atteint **1.3 GB/s**
- La différence est négligeable pour un usage VPN personnel

## Conclusion

AES-256-GCM est recommandé pour ce projet :
- Sécurité maximale (clé 256 bits)
- Performance suffisante sur Raspberry Pi 5
- Standard utilisé dans les VPN professionnels
