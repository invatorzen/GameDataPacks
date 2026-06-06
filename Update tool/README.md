# Data Pack Installer

`apply_data_pack.rb` installs a generation/version data pack from the
[PokemonWorkshop/GameDataPacks](https://github.com/PokemonWorkshop/GameDataPacks)
repository into your Pokemon Studio / PSDK project.

Two ways to apply a pack:

- **Overwrite all data** — wipe the relevant project folders and replace them with the pack. Best for fresh projects.
- **Switch current data with another data pack** — pick a "FROM" pack (the gen your project currently uses) and a "TO" pack (the gen you want to switch to). Anything in your project that the FROM pack didn't ship is treated as your **custom content**, kept, and renumbered into the TO pack's id space (Pokémon, moves, items, abilities, types, and custom Pokémon forms). The script shows a preview of what will be carried over before applying.

A timestamped backup is created before any file is touched, so a bad run can always be rolled back.

## Requirements

- Place `apply_data_pack.rb` in a subfolder in your **project's root folder** (the folder containing `project.studio`) like 'tools'
- [Ruby](https://rubyinstaller.org/)
- For remote source mode: `git` on your PATH + internet access. (The script uses a sparse partial clone so only the chosen version folder is downloaded, not the full ~340 MB repo.)
- OR for local source mode: a clone or extracted copy of the GameDataPacks repository.

## Generations and versions

| Gen | Versions |
| --- | --- |
| 1 | `red-green-blue-yellow` |
| 2 | `gold-silver`, `crystal` |
| 3 | `ruby-sapphire`, `firered-leafgreen`, `emerald` |
| 4 | `diamond-pearl`, `platinum`, `heartgold-soulsilver` |
| 5 | `black-white`, `black-2-white-2` |
| 6 | `x-y`, `omega-ruby-alpha-sapphire` |
| 7 | `sun-moon`, `ultra-sun-ultra-moon` |
| 8 | `sword-shield` |
| 9 | `scarlet-violet`, `Legends Z-A` |

Each pack contains everything **up to and including** its generation — you only need to pick one. (E.g. the Gen 9 pack already includes Gens 1–8 data.)

## Interactive use

From your project's root folder, or in a subfolder like `tools`:

Move `apply_data_pack.rb` and double click it.

You'll be prompted for:

1. **How to apply the pack** — GitHub sparse-clone, or a local version you already downloaded.
2. **Generation / version** — for the TO pack (and the FROM pack, if switching).
3. **Scope** — which categories to update: everything, or something specific like: `pokemon` / `moves` / `items` / `abilities` / `types`.

## Non-interactive use

All prompts can be answered with flags. Add `--yes` to skip the confirmation.

```
# Overwrite, local clone
ruby tools/apply_data_pack.rb --local "C:\path\to\GameDataPacks" \
  --strategy overwrite --gen 3 --version emerald --yes

# Overwrite, remote, Pokémon + moves only
ruby tools/apply_data_pack.rb --remote --strategy overwrite \
  --gen 9 --version scarlet-violet --scope pokemon,moves --yes

# Switch: migrate from Gen 5 BW2 to Gen 4 HGSS, keeping custom content
ruby tools/apply_data_pack.rb --local "C:\path\to\GameDataPacks" --strategy switch \
  --from-gen 5 --from-version black-2-white-2 \
  --gen 4 --version heartgold-soulsilver --yes
```

### Flags

| Flag | Description |
| --- | --- |
| `--local PATH` | Use a local clone of GameDataPacks at `PATH`. Quoted, mixed-slash, and trailing-whitespace paths are accepted. |
| `--remote` | Sparse-clone the chosen version folder from GitHub `main` (requires `git`). |
| `--strategy NAME` | `overwrite` (default) or `switch`. |
| `--gen N` | Target generation number (1–9). For switch, this is the TO gen. |
| `--version NAME` | Target version folder name (see table above). For switch, this is the TO version. |
| `--from-gen N` | Switch only: the gen the project currently tracks. |
| `--from-version NAME` | Switch only: the version the project currently tracks. |
| `--scope LIST` | Comma-separated categories. Use `all` or any of: `pokemon`, `moves`, `items`, `abilities`, `types`. Defaults to prompting. |
| `--yes` | Skip the confirmation prompt. |
| `-h`, `--help` | Show usage. |

If neither `--local` nor `--remote` is given, you'll be asked which to use.

## Troubleshooting

- **"could not find a Pokemon Studio project root"** — `apply_data_pack.rb` should be placed in a subfolder in your project's root folder (the folder containing `project.studio`), like a folder named 'tools'.
- **"git is not installed or not on PATH"** — install Git, or clone the repo locally and give it as a filepath.
- **`git clone failed`** — check your internet connection and that you can reach `github.com`. Behind a proxy you may need to configure Git's `http.proxy` setting.
- **"FROM pack has no manifest.json"** — your local clone of GameDataPacks predates the `Manifest tool/` PR. Pull the latest, or run the generator yourself.