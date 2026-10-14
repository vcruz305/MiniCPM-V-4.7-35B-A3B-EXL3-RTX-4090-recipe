# Validation status

Updated 2026-10-13 on one RTX 4090 24 GB (WSL2 Ubuntu 22.04).

| Item | Status |
|---|---|
| Full 262,144-token context, Q4 and Q8 KV | Measured, 4/4 needles, fits in 24 GB |
| Decode vs prompt length 2K-130K | Flat 84-91 tok/s (target-only) |
| dSparK output vs target-only | Identical at every tested depth |
| dSparK speed | +12% at 1K prompts only; slower from 2K up |
| Clean `setup.sh` (WSL2) | Exit 0 in 7 min 10 s on fork `475461e9` |
| Fidelity | 93.43% top-1, 0.0315 KL (20,480 positions) |
| Vision API on this card | Not measured |
| FP16 KV at 262K | Not tested |

CPU helper checks: [recipe tests](docs/recipe-tests.md).
