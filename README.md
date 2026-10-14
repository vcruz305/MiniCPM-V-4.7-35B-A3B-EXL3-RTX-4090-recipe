# MiniCPM-V 4.7 35B-A3B SAGE EXL3 on one RTX 4090

Serve the **3.74 bpw SAGE EXL3** release of MiniCPM-V 4.7 on a single 24 GB
**GeForce RTX 4090** through [ExLlamaV3](https://github.com/vcruz305/exllamav3) and
[TabbyAPI](https://github.com/vcruz305/tabbyAPI), at the full **262,144-token** context.

| One RTX 4090, measured 2026-10-13 | Result |
|---|---:|
| Decode at 262,144 tokens, Q4 KV | **88.4 tok/s** |
| Decode, 1,024-token prompts, FP16 KV | 92.1 tok/s |
| Prefill, cold 261,886 tokens, Q4 KV | 1,236 tok/s |
| Needle retrieval at 262K (4 needles) | 4/4 |
| Peak VRAM at 262K, Q4 KV | 19,160 MiB |

Decode speed stays at 84–91 tok/s from 2K to 262K tokens of context.


## Model

| | Hugging Face |
|---|---|
| Checkpoint served (includes the dSparK drafter under `dspark/`) | [vcruz305/MiniCPM-V-4.7-35B-A3B-EXL3-SAGE-3.74bpw](https://huggingface.co/vcruz305/MiniCPM-V-4.7-35B-A3B-EXL3-SAGE-3.74bpw) |
| Base model | [openbmb/MiniCPM-V-4.7-35B-A3B](https://huggingface.co/openbmb/MiniCPM-V-4.7-35B-A3B) |
| Official dSparK drafter | [openbmb/MiniCPM-V-4.7-35B-A3B-DSpark](https://huggingface.co/openbmb/MiniCPM-V-4.7-35B-A3B-DSpark) |

## Quick start

Linux or WSL2 with a CUDA-enabled PyTorch/Triton, CUDA toolkit and a C++ compiler:

```bash
git clone https://github.com/vcruz305/MiniCPM-V-4.7-35B-A3B-EXL3-RTX-4090-recipe.git
cd MiniCPM-V-4.7-35B-A3B-EXL3-RTX-4090-recipe

bash exllamav3-tabby/setup.sh      # build the latest forks (about 7 minutes)
bash exllamav3-tabby/download.sh   # 18 GB model, checksum-verified

PROFILE=long bash exllamav3-tabby/serve.sh   # full 262,144-token context
```

If `python3` is not your CUDA environment:
`BASE_PYTHON=/path/to/cuda-venv/bin/python bash exllamav3-tabby/setup.sh`.
Preview the generated server config: `DRY_RUN=1 PROFILE=long bash exllamav3-tabby/serve.sh`.

**WSL2:** `serve.sh` raises the open-file limit to 65,536. Without it the CUDA driver
fails mid-load with `CUDA driver error: unknown error`.

## Profiles

| Profile | Context | KV cache | Vision | Use |
|---|---:|---|---|---|
| `long` | 262,144 | Q4 | off | Full context, long documents |
| `single` | 8,192 | FP16 | off | Short chat |
| `vision` | 4,096 | FP16 | on | Images |

Overrides: `MODEL_DIR`, `PROFILE`, `PORT`, `HOST`, `MAX_SEQ_LEN`, `CACHE_SIZE`,
`CACHE_MODE` (`FP16`/`Q8`/`Q6`/`Q4`), `CHUNK_SIZE`, `MAX_BATCH_SIZE`, `VISION`,
`DRAFT_MODE` (`disabled`/`dspark`), `DRAFT_TOKENS` (1–7), `RECIPE_HOME`,
`STATE_DIR`, `GPU_LOCK_FILE`.

## Full-context results

One cold 261,886-token request with four passcodes at 10/35/60/90% depth, then three
decode samples that fill the context exactly (261,888 prompt + 256 generated = 262,144).

| KV | Prefill | TTFT | Needles | Decode median (min–max) | Peak VRAM |
|---|---:|---:|---:|---:|---:|
| Q4 | 1,236 tok/s | 214.0 s | 4/4 | **88.42** (83.69–89.82) | 19,160 MiB |
| Q8 | 1,304 tok/s | 202.8 s | 4/4 | **88.87** (88.25–89.05) | 20,428 MiB |

Q8 KV also fits in 24 GB at full context and prefills slightly faster; Q4 leaves more
headroom. FP16 KV at 262K was not tested on this card.

Decode by prompt length (Q4 KV, 256 tokens out, tok/s):

| Prompt tokens | 2,040 | 8,183 | 16,376 | 32,758 | 65,528 | 129,992 |
|---|---:|---:|---:|---:|---:|---:|
| Target-only | 84.9 | 85.7 | 84.4 | 84.1 | 84.8 | 90.7 |

130K row ran with `MAX_SEQ_LEN=131072`; the 262K row above is the full-context test.

## dSparK on the 4090: available, not recommended

The model release bundles OpenBMB's official dSparK drafter. `DRAFT_MODE=dspark` enables
it (8K context cap, text-only, batch 1). Output is **identical** to target-only greedy
decoding in every test, but on this card it is rarely faster:

| Workload | Target-only | dSparK width 7 |
|---|---:|---:|
| 1,024-token prompts, FP16 KV (7 runs, p50) | 92.06 | **103.14** (+12%) |
| 2,040-token essay prompt, Q4 KV | **84.89** | 61.16 |
| 8,183-token prompt, Q4 KV | **85.70** | 53.57 |
| 262,144 tokens, Q4 KV | **88.42** | 38.11 |

Draft acceptance falls quickly as context grows, and the 4090's single-token decode is
already fast, so the verify overhead rarely pays off. Use target-only.

## Quality

On the same runtime family, re-scored against the model card's BF16 final-logit
references (20,480 positions): 93.43% top-1 agreement, 0.0315 mean KL.

## API

Authenticated localhost API at `http://127.0.0.1:8898/v1`. Keys persist under
`$STATE_DIR/api_tokens.yml`; use the **inference** key.

```bash
read -rsp 'TabbyAPI inference key: ' TABBY_API_KEY; echo; export TABBY_API_KEY
curl --fail-with-body http://127.0.0.1:8898/v1/chat/completions \
  -H "Authorization: Bearer $TABBY_API_KEY" -H 'Content-Type: application/json' \
  -d '{"model": "MiniCPM-V-4.7-35B-A3B-EXL3-SAGE-3.74bpw",
       "messages": [{"role": "user", "content": "Explain DNS caching in three sentences."}],
       "temperature": 0, "max_tokens": 256,
       "chat_template_kwargs": {"enable_thinking": false}}'
```

## How these numbers were measured

One RTX 4090 24 GB on WSL2 Ubuntu 22.04 (driver 617.14), connected over a PCIe Gen2 x4
eGPU link; prefill on a full x16 slot may be higher. TabbyAPI over HTTP, streamed,
server-reported `usage` timings, one request at a time, thinking disabled.
ExLlamaV3 fork `master` at `dc778646` (short context, full-context target-only) and
`475461e9` (dSparK with quantized KV, depth sweep). Raw values:
[`bench/measured-results.json`](bench/measured-results.json).
Validation details: [VALIDATION.md](VALIDATION.md).

## Credits and licenses

OpenBMB: MiniCPM-V 4.7 and the official dSparK drafter. turboderp: ExLlamaV3.
The Royal Lab: TabbyAPI. [r0b0tlab](https://github.com/r0b0tlab): MiniCPM-V 4.7
dSparK conversion improvements merged into the fork. Victor Cruz: SAGE EXL3 release,
recipe and measurements.

Recipe code and docs: MIT. Model and runtimes keep their own licenses; see
[third-party notices](THIRD_PARTY_NOTICES.md).

AI agents: read [AGENTS.md](AGENTS.md) before editing.
