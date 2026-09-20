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

1. Drop `MapEnh` into `Interface/AddOns/`

2. See what it needs:

   ```
   tools/extract.py --liste
   ```

   Writes `tiles.txt` (FileDataIDs) and `paths.txt` (their file names). All but
   five live under `interface/worldmap/`.

3. In [wow.export](https://github.com/Kruithne/wow.export) or CASCExplorer,
   filter on `interface/worldmap` and export the lot. **One filter, one click** —
   you are not picking 1566 files by hand.

4. Put them where the addon looks for them:

   ```
   tools/extract.py --ranger <your export folder>
   ```

   Exporters name files by path; the addon wants `<id>.blp`. This bridges the two,
   and tells you plainly what is still missing and why.

5. Launch the game. `/mapenh` turns on diagnostics if something looks wrong.

### Why not automatic?

`tools/extract.py` can drive a CASC extraction helper for you (`--wow` and
`--casc-tirer`), but **no such helper ships with this addon**: the one used to
build it is a small C program from the workshop, linked against CascLib, and
shipping a binary you would have to trust is worse than asking you to use a tool
you already know.

The list is the contract. Where you get the files from is your call.

## Status

Working. **54 maps, 1566 tiles.** Terrain and exploration overlays both restored,
verified in game across several zones.

Six maps in this build need nothing — Alterac Valley among them, and Mount Hyjal
is only missing 30 tiles out of 42. So this is not a whole locale bundle that went
missing; something finer is going on.
