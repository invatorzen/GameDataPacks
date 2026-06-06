# Manifest tool

Generates per-pack `manifest.json` files (one in every `Gen N/<version>/` folder) and a top-level `manifests.json`.

## What it produces

### `Gen N/<version>/manifest.json`

Summarises a single pack:

```json
{
  "schema_version": 1,
  "generated_at": "...",
  "gen": 4,
  "version": "heartgold-soulsilver",
  "categories": {
    "pokemon": {
      "data_dir": "Data/Studio/pokemon",
      "count": 493,
      "max_id": 493,
      "max_form_text_id_name": 562,
      "max_form_text_id_description": 70,
      "symbols": ["abomasnow", "abra", ...]
    },
    "moves":     { "data_dir": "...", "count": ..., "max_id": ..., "symbols": [...] },
    "items":     { "data_dir": "...", "count": ..., "max_id": ..., "symbols": [...] },
    "abilities": { "data_dir": "...", "count": ..., "max_id": ..., "max_text_id": ..., "symbols": [...] },
    "types":     { "data_dir": "...", "count": ..., "max_id": ..., "max_text_id": ..., "symbols": [...] }
  },
  "csv_rows": {
    "100000": 495,
    "100067": 564,
    ...
  }
}
```

### `manifests.json` (repo root)

Union of every pack's symbols (the canonical list of "official" dbSymbols across every gen) plus a list of all packs and their manifest paths.

## Why

Tools that apply or merge packs into a Pokémon Studio / PSDK project (e.g. `tools/apply_data_pack.rb` in PSDK projects) need to:

1. **Know what's official** so they can correctly identify project-custom entries (Pokémon, moves, items, etc. the user added themselves).
2. **Know the pack's max id / textId / formTextId** so they can renumber custom entries to safe positions beyond the pack's range without colliding with pack data.
3. **Know each shipped CSV's row count** so they can pick safe CSV row indices for custom entries (a renumbered custom Pokémon's name needs to live at a row that the pack overlay won't clobber).

Without manifests, tools have to scan every JSON in every pack at runtime — slow and wasteful. With manifests, all of this is one file read.

## Running the generator

From the repo root:

```
ruby "Manifest tool/generate.rb"
```

Or double-click `Manifest tool/launch.bat` on Windows.

## When to regenerate

Re-run any time:

- A pack's `Data/Studio/<category>/` contents change (new/removed Pokémon, moves, etc.)
- A pack's `Data/Text/Dialogs/*.csv` rows are added or removed
- A new generation or version folder is added

A CI check that runs the generator and fails if `manifest.json` / `manifests.json` are out of date would catch missed regenerations on every PR.
