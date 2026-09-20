# MapEnh

> World maps render blank on non-English WoW clients. MapEnh puts the tiles back.

## The problem

On a `frFR` client (and likely every non-English locale), **every world map renders
as a flat coloured background**. Quest markers, quest log and coordinates all work —
only the terrain is missing.

The cause, measured on build 1.60.1.69893/69913:

- `C_Map.GetMapArtLayerTextures` returns the **correct** FileDataIDs, and the
  **same ones** on `frFR` and `enUS`
- but those files are **not published for `frFR`** — they are absent from the
  storage as a French client sees it
- the client has **no locale fallback**: it lays out the tiles and each one
  resolves to nothing

Of the 143 map-art sets referenced by `uimaparttile`, **53 have no tiles at all**
on `frFR`, and **none are partially present** — which rules out an incomplete
download.

## What MapEnh does

It supplies its own copies of the missing tiles and draws them on the map canvas,
hooking `MapCanvasDetailLayerMixin:RefreshDetailTiles` with `hooksecurefunc`.

Addon files load **by path**, so they bypass the locale filter that hides the
originals. That is the only remaining door, and it is enough.

It does not write to `_G`, does not replace any Blizzard function, and does not
touch protected code.

**It stands down on its own** when the client can already display its tiles —
an English client, or a fixed build. An addon that paints over a working map does
not fix anything, it hides it.

## ⚠️ The tiles are not in this repository

They are Blizzard assets. Shipping them would mean redistributing them.

**You generate your own**, from the installation you already own:

```
tools/extract.py            # reads your local CASC, writes tiles/ and donnees.lua
```

The repository carries the **code** and the **tile map** — which FileDataID goes
where, in what order. Not one byte of Blizzard art travels with it.

## Installing

Unzip `MapEnh` into `Interface/AddOns/`, then get the tiles. **Close the game and
Battle.net first** — the storage is locked while they run.

### The short way — no Python needed

Download the extractor for your platform from the release, and **put it inside the
`MapEnh` folder**. Open a terminal **in that folder** — the paths below are
relative to it.

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

It writes 1566 files into `tuiles/` and takes a couple of minutes. The last line
tells you how many came out:

```
-- lot : 1566 extraits, 0 echecs, 0 partiellement chiffres
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

### No artwork ships with this addon

The tiles are Blizzard's. The release carries the **code** that reads them out of
the copy you already own — never the images themselves.

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

Working. **54 maps, 1566 tiles.** Terrain and exploration overlays both restored,
verified in game across several zones.

Six maps in this build need nothing — Alterac Valley among them, and Mount Hyjal
is only missing 30 tiles out of 42. So this is not a whole locale bundle that went
missing; something finer is going on.
