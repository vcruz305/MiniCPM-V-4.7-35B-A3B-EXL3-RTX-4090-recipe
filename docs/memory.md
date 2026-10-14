# Context and memory on a 24 GB RTX 4090

The published 19 target shards total 17,999,304,996 bytes, approximately 16.76 GiB.
This is serialized storage, not the full CUDA allocation. The optional dSparK
weights, tokenizer/index, CUDA workspace, KV and recurrent state are additional.

The publisher reports 20.33 GiB peak CUDA allocation at 8K text context and
18.33 GiB in a separate 4K text-plus-vision smoke on a DGX Spark. Do not subtract
those numbers from a nominal 24 GB device and promise the remainder is usable:
framework allocations, display use, image resolution, batch and kernel support
can differ. A 24 GB Turing Quadro RTX 6000 is not the 96 GB RTX PRO 6000 Blackwell.
This recipe makes no Turing support claim.

Measured device peaks on one RTX 4090 at 262,144 tokens: 19,160 MiB with Q4 KV and
20,428 MiB with Q8 KV (target-only). At 8K context with FP16 KV the loaded server used
17,034 MiB, or 17,902 MiB with the dSparK drafter. Desktop compositors and other GPU
apps share the same 24 GB; close them before long-context runs.

For a second service on the same machine, use a distinct API port and state directory. Both models'
weights, KV/recurrent state, vision buffers, page cache and OS must fit in the same
unified memory. Free memory cannot be calculated from weight-file sizes alone.
Do not automatically evict, unload, kill or restart the primary model.

The optional GPU_LOCK_FILE is cooperative exclusion for workflows requiring
exclusive use. Use the same lock path in other supervisors for it to be effective.
It is not a memory allocator or a way to partition the GPU between servers.
