# Benchmark AES-128 vs AES-256 — Raspberry Pi 5

## Résultats (openssl speed)

| Taille | AES-128-CBC | AES-256-CBC | Différence |
|--------|-------------|-------------|------------|
| 16B    | 600 MB/s    | 547 MB/s    | -9%        |
| 64B    | 1309 MB/s   | 1012 MB/s   | -23%       |
| 256B   | 1724 MB/s   | 1263 MB/s   | -27%       |
| 1KB    | 1851 MB/s   | 1332 MB/s   | -28%       |
| 8KB    | 1907 MB/s   | 1365 MB/s   | -28%       |
| 16KB   | 1912 MB/s   | 1368 MB/s   | -28%       |

## Conclusion
AES-256 est 28% plus lent mais reste largement suffisant (1.3 GB/s).
Recommandation : AES-256-GCM pour la sécurité maximale.
