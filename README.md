# MapEnh

> World maps render blank on non-English WoW clients. MapEnh puts the tiles back.

**🇫🇷 Vous jouez en français ? → [Guide d'installation en français](GUIDE-FR.md)**

## The problem

On a `frFR` client (and likely every non-English locale), **every world map renders
as a flat coloured background**. Quest markers, quest log and coordinates all work —
only the terrain is missing.

The cause, measured on build 1.60.1.69913 by opening the CASC storage one locale
at a time:

- `C_Map.GetMapArtLayerTextures` returns the **correct** FileDataIDs, and the
  **same ones** on `frFR` and `enUS`
- those files are **not published for `frFR`**: of the 1867 tiles involved,
  **all 1867 open in `enUS` and `enGB`, none in `frFR`**
- the client has **no locale fallback**: it lays out the tiles and each one
  resolves to nothing, and this client paints what it cannot find as a flat
  bright colour instead of leaving it transparent

**56 zones out of 56 are affected, none partially** — which rules out an
incomplete download. `Logs/AsyncFile.log` says it plainly: *Can't find file in
build manifest*.

## What MapEnh does

Blizzard lays the map out as usual. MapEnh then looks at each texture that was
just placed, and when its FileDataID is one of the missing ones, hands it a local
copy instead.

Addon files load **by path**, so they bypass the locale filter that hides the
originals. That is the only remaining door, and it is enough.

Nothing is positioned by the addon, so nothing can be positioned wrong: no grid
maths, no edge cropping, no state kept between maps.

It does not write to `_G` beyond `SLASH_MAPENH1` / `SlashCmdList`, does not
replace any Blizzard function, and does not touch protected code.

**It stands down by itself on an English client** (`enUS` or `enGB`) — their
tiles work, and painting over a working map hides a problem rather than fixing
one.

## Two ways to get the tiles

The addon code is **the same either way** — `tuiles/<FileDataID>.blp` does not
care how the file got there.

| Download | Size | What you do |
|---|---|---|
| `MapEnh-x.y.z-complet.zip` | ~60 MB | unzip into `Interface/AddOns`, play |
| `MapEnh-x.y.z.zip` + extractor | 50 KB | extract the tiles from your own copy |

### Not in this repository

No artwork is committed here, and none ever will be. The `-complet` zip is built
locally from a real installation and attached to the release; the repository
carries the **code** and the **list of FileDataIDs** to fetch.

## Installing — the short way

Unzip `MapEnh-x.y.z-complet.zip` into `Interface/AddOns/`. Launch the game, tick
MapEnh in the addon list, open your map. Nothing else.

## Installing — extracting the tiles yourself

Take `MapEnh-x.y.z.zip` (not the `-complet` one) and the extractor for your
platform. **Close the game and Battle.net first** — the storage is locked while
they run.

Put the extractor **inside the `MapEnh` folder** and open a terminal **in that
folder** — the paths below are relative to it.

The argument is `<your WoW folder>:wow_classic_beta`, in one piece, quoted. The
colon separates the two; a drive letter like `C:` does not confuse it.

**Windows — Command Prompt (cmd)**
```
mapenh-extract-windows-x86_64.exe "C:\Program Files (x86)\World of Warcraft:wow_classic_beta" < tools\tiles-batch.txt
```

**Windows — PowerShell** (the default in Windows Terminal)

PowerShell has no `<` redirection. Pipe the file instead:
```
Get-Content tools\tiles-batch.txt | .\mapenh-extract-windows-x86_64.exe "C:\Program Files (x86)\World of Warcraft:wow_classic_beta"
```

**Linux**
```
chmod +x mapenh-extract-linux-x86_64
./mapenh-extract-linux-x86_64 "/path/to/World of Warcraft:wow_classic_beta" < tools/tiles-batch.txt
```

It writes 1867 files into `tuiles/` and takes a couple of minutes. The last line
tells you how many came out:

```
-- lot : 1867 extraits, 0 echecs, 0 partiellement chiffres
```

`0 echecs` is what you want.

If instead you get a line like

```
CascOpenStorageEx('C:\Wrong\Path','wow_classic_beta') : erreur 2
```

it did not open your game at all. It prints back exactly what it understood, so
check those two values: the folder on the left (the one holding `Data/` — or
`Data/` itself, both work), and the product on the right, which must be
`wow_classic_beta`.

### If you have Python

`tools/extract.py --wow "<your WoW folder>"` does the same thing, finds the
extractor on its own, and checks every file afterwards.

### Then

Launch the game. `/mapenh` turns on diagnostics if something looks wrong.

### The extractor

The extractor is built from `tools/src/` by GitHub Actions on every release, and
attached to it, for Linux and Windows. It links against
[CascLib](https://github.com/ladislav-zezula/CascLib) (MIT).

### If you would rather not run a binary

Fair enough. There is a route with no compiled code at all:

```
tools/extract.py --liste                    # what it needs, by name
# filter on `interface/worldmap` in wow.export, export the lot, then:
tools/extract.py --ranger <export folder>   # puts them where the addon looks
```

## Status

Working. **1867 tiles across 56 zones**, terrain and exploration overlays alike,
verified in game.

Every id on the list was checked in the storage itself — absent in `frFR`,
present in `enUS` — rather than inferred from a file listing. 12 tiles that load
fine in French were dropped in 0.3.0; 313 that were missing were added, 276 of
which no addon covered.

## Prior art

**[MapFixForever](https://github.com/Pirson-s-Addons/MapFixForever)** by
Pirson (MIT) fixes the same defect and got there first, on 2026-09-19. Its
approach — replacing the texture by its FileDataID rather than laying new ones —
is better than what MapEnh did until 0.3.0, and MapEnh now uses it.

The two differ in what they ship: MapFixForever bundles the 1554 images, MapEnh
extracts them from your own installation. Coverage measured against the storage
on 2026-09-21: 1867 tiles here, 1462 there.

## Licence

MIT — see [LICENSE](LICENSE).

The map tiles are **not** covered by it: they are Blizzard assets, they are not
in this repository, and the `-complet` archive only ships copies pulled from an
installation you already own.
