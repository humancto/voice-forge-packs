# voice-forge-packs

Pre-rendered voice packs for [VoiceForge](https://github.com/humancto/voice-forge).

Each pack is a folder of WAV files keyed by event name (`build_failed.wav`, `tests_passed.wav`, etc.). VoiceForge plays them at runtime in **~50 milliseconds** — no model load, no synth call. The render-once cost is amortized away.

> [!IMPORTANT]
> **Educational, research, and local-testing use only.**
> The packs in this repository are character / public-figure voice clones rendered with [fish-speech S2 Pro](https://github.com/fishaudio/fish-speech). They are made available for personal exploration of voice-cloning technology and as reference material for community contributors who want to render their own packs. **No commercial use. Do not redistribute as part of products. Do not use to deceive.** See [LICENSE-AUDIO.md](LICENSE-AUDIO.md).

> [!WARNING]
> **Takedown-friendly.** If you are a rights holder and want a pack removed, open a GitHub issue (or email the address listed in the repo's About). We will pull the affected pack within 48 hours, no questions asked. Voice-forge itself (the engine) lives in a [separate repository](https://github.com/humancto/voice-forge) and is not affected by per-pack takedowns.

---

## Install a pack

If you have VoiceForge installed (Phase 6.2 ships the subcommand):

```bash
voiceforge pack install peter
```

Until 6.2 lands, install manually:

```bash
mkdir -p ~/.voiceforge/packs
cd ~/.voiceforge/packs
curl -fsSL https://github.com/humancto/voice-forge-packs/releases/latest/download/peter.tar.gz | tar xz
```

Then verify with:

```bash
sha256sum -c ~/.voiceforge/packs/peter/checksums.txt
```

---

## Available packs

| Voice | Source                                              | Phrases | Status   |
| ----- | --------------------------------------------------- | ------- | -------- |
| peter | Peter Griffin (Family Guy, S5 Nike commercial clip) | 13      | shipping |

(Roadmap: stewie, quagmire, trump, obama. Each gated on us finding a clean source clip.)

---

## Pack format

```
packs/<voicename>/
├── manifest.toml          # name, license, attribution, source URL, schema_version
├── reference.wav          # the source clip used for cloning (so anyone can re-render locally)
├── wav/
│   ├── <event>.wav        # one WAV per event, mono, native sample rate
│   └── ...
└── checksums.txt          # sha256 per file, sha256sum -c -compatible
```

`packs.json` at the repo root is a machine-readable index of all packs (consumed by `voiceforge pack list / install`).

---

## Render your own pack

The full pipeline is documented in [voice-forge/docs/PACK_RENDERING.md](https://github.com/humancto/voice-forge/blob/main/docs/PACK_RENDERING.md). TL;DR — anyone with ~16 GB RAM and ~12 GB free disk can clone any character voice locally in under an hour, no GPU required.

If you'd like to contribute a pack:

1. Render it locally (the doc walks through it).
2. Open a PR adding `packs/<yourvoice>/` here, with manifest, reference clip, all WAVs, and checksums.
3. The `voice_source` field in the manifest must include a URL pointing to the original audio (so reviewers can verify provenance).
4. Merging is at maintainer discretion; we will reject impersonations of private individuals without consent and anything that looks intended to deceive.

---

## License

This repository's **code, scripts, and metadata** are MIT-licensed (see [LICENSE](LICENSE)).

The **audio content** (`packs/*/wav/*.wav`, `packs/*/reference.wav`) is shared under the educational-use terms in [LICENSE-AUDIO.md](LICENSE-AUDIO.md). It is _not_ MIT-licensed and is _not_ freely redistributable.

---

## Related

- [github.com/humancto/voice-forge](https://github.com/humancto/voice-forge) — the VoiceForge engine, runtime, and CLI.
- [docs/PACK_RENDERING.md](https://github.com/humancto/voice-forge/blob/main/docs/PACK_RENDERING.md) — render your own pack.
- [fishaudio/fish-speech](https://github.com/fishaudio/fish-speech) — the underlying TTS model.
