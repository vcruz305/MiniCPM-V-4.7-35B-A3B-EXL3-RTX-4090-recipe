# Agent instructions

Read README.md, VALIDATION.md, runtime.json, model.lock.json
and docs/runtime-status.md before editing.

- Run both forks from their **latest default branches**; never add
  fixed engine versions, tags, or Git SHA pins. Use SHAs only for
  diagnostic receipts and explaining benchmark conditions.
- Native MiniCPM text/vision and Qwen3DSparkModel are now merged
  into the fork. Do not reintroduce the obsolete missing-code warning.
- This README stands alone. Do not compare its layout with unrelated
  model recipes or call it a derivative of another recipe.
- Keep the MiniCPM-native architecture, vision insertion, canvas
  M-RoPE, tokenizer, original template, and EOS metadata.
- The weight manifest identifies this EXL3 *model release*, not
  an inference-runtime software version.
- Keep target-only decoding as the default. dSparK is opt-in
  (`DRAFT_MODE=dspark`), exact, faster only for short prompts and capped at
  `MAX_SEQ_LEN <= 8192`; its acceptance collapses with long prompts.
- Never invent GPU benchmarks. Distinguish published model-card data
  from helper tests and downstream OpenBMB baseline results.
- Do not kill existing services, hot-upgrade workloads, modify existing
  code checkouts, expose credentials or auto-rent hardware.
- Full 262K context was measured with Q4/Q8 KV on one RTX 4090 24 GB
  (see bench/measured-results.json). FP16 KV at 262K was not tested.
- dSparK is not recommended on the 4090: faster only at ~1K prompts.
- CI is CPU-only: it checks helper behavior, not native CUDA inference.

## Tests

python3 -m unittest discover -s tests -v
python3 -m compileall -q tools bench tests
for f in exllamav3-tabby/*.sh; do bash -n "$f"; done
