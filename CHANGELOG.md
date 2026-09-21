# Changelog

## [0.3.0] — 2026-09-21

**1867 tiles instead of 1566, and a simpler way of putting them back.**

### Changed
- **Tiles are now replaced, not re-laid.** Blizzard lays out the map; MapEnh only
  swaps the texture it just placed, recognised by its FileDataID. No grid maths,
  no cropping of edge tiles, no deferred hiding of the exploration pin, no state
  kept between maps — and the artefacts those steps produced are gone with them.
  The idea comes from **MapFixForever** (Pirson, MIT). It is better than ours.
- `donnees.lua` went from 3058 lines to 382: a set of ids, no path table. The
  file on disk is named after its FileDataID, so the path is computed.

### Added
- **`MapEnh-0.3.0-complet.zip` — the tiles are in the download.** Unzip, play.
  The addon code is unchanged between the two zips: `tuiles/<FileDataID>.blp`
  does not care how the file got there. The extraction route stays, for anyone
  who would rather nothing were redistributed to them.
  No artwork is committed to this repository, and none ever will be — the full
  zip is built locally and attached to the release.
- **+276 tiles in `riverlands` and `hyjal`** that no addon covered — found by
  testing all 76 611 `interface/worldmap/` candidates against the storage.
- **+37 tiles** that MapFixForever covers and we did not.
- **`enGB` now stands down too.** 0.2.x only knew `enUS`, so it would have gone
  to work for nothing on a British client. Measured: `enGB` has all 1867.
- `/mapenh on|off` to toggle the fix, `/mapenh bavard` for diagnostics,
  `/mapenh` alone for status.

### Removed
- **12 `hyjal` tiles that load fine in French.** They were shipped for nothing.

### How the list is built now
Every id is verified in the CASC storage itself — **absent in `frFR`, present in
`enUS`** — by `outils/casc-locale`, which opens files locale by locale instead of
enumerating them.

That distinction mattered: the manifest tool we had trusted until then,
`CascFindFirstFile`, **does not enumerate the whole root**. 1554 of our own 1566
tiles were missing from it, in all four manifests, while extracting without error.
A comparison between a French and an English manifest — the measurement planned
for this release — would have been blind at the same spot in both, and the silence
would have looked like an answer.

## [0.2.3] — 2026-09-20

Documentation only, but the 0.2.2 instructions did not work everywhere.

### Fixed
- **PowerShell** has no `<` redirection, and it is the default shell in Windows
  Terminal. Added the pipe form, tested.
- Said explicitly that the terminal must be opened **inside** the `MapEnh` folder:
  `tiles-batch.txt` holds relative paths.
- Removed a wrong hint: pointing at `Data/` works just as well as pointing at its
  parent. Both were tested.
- Documented the real error line, which prints back the folder and product it
  understood — enough to diagnose a bad path on its own.

## [0.2.2] — 2026-09-20

**Installing no longer needs Python.** It did, and the README never said so —
Python ships with Linux, not with Windows, which is where most players are.

### Added
- `tools/tiles-batch.txt` — the extraction list with **relative** paths, so the
  extractor alone does the job in one command.

### Changed
- README leads with the no-Python route. The Python script stays as the second
  way: it finds the extractor on its own and checks every file afterwards.

## [0.2.1] — 2026-09-20

No change to the addon. This release exists to prove the build chain works
end to end: until now the extractors were attached **by hand**, because the
"attach to release" step had never once succeeded — skipped on manual runs,
403 on the only real release.

A build that has never run unattended is not a build you can rely on.

## [0.2.0] — 2026-09-20

**Download, run one program, play.** No third-party tool.

### Added
- `tools/src/mapenh-extract.c` — reads the local CASC storage directly
- GitHub Actions builds it for Linux and Windows on every release and attaches it
- `extract.py` finds it next to itself; you just point at your game folder

### Why
0.1.1 worked but asked a lot: install wow.export, filter, export 82 MB of images,
run two commands. Too much for someone who only wants their map back in French.

Still no artwork in the repository or the zip. The extractor reads the copy you
already own — shipping a tool is not the same as redistributing assets.

The manual route (`--liste` / `--ranger`) stays, for anyone who would rather not
run a binary they did not build.

## [0.1.1] — 2026-09-20

**0.1.0 was published but not usable in practice.** It handed you 1566
FileDataIDs and left you to extract them one by one. This fixes that.

### Added
- `tools/paths.csv` — the file name behind each FileDataID. Names only, no artwork.
- `--ranger <folder>` — renames what a CASC browser exported into `tuiles/<id>.blp`.
  Exporters name by path, the addon wants ids; this bridges the two.
- `--liste` now also writes `paths.txt`, so you can filter on `interface/worldmap`
  and export in one go.

### Fixed
- The "still missing" message claimed those tiles had no known name. Most simply
  had not been exported. It now tells the two apart, because they send you looking
  in different places.

## [0.1.0] — 2026-09-19

First working version. Maps render again on a French client.

### Added
- Terrain tiles re-laid on the map canvas, hooking
  `MapCanvasDetailLayerMixin:RefreshDetailTiles` with `hooksecurefunc`
- Exploration overlays re-laid from `worldmapoverlay` / `worldmapoverlaytile`
- The stock exploration pin's textures are hidden — the client paints missing
  artwork as a bright flat colour instead of leaving it transparent
- `tools/extract.py` — generates the tiles from your own installation
- `/mapenh` — turns diagnostic messages on, off by default

### Covered
54 maps, 1566 tiles. Six maps in the build need nothing.

### Verified in game
- **Multiple zones** — maps render, no leftovers when switching between them
- **Zoom and panning** — tiles scale and are clipped by the canvas frame, even
  though they do not go through Blizzard's texture pool
- **English client** — the addon stands down: it loads, reports `locale enUS`,
  and posts no hook. The map you see is the client's, not ours.

### Notes
- **Stands down on an English client.** Its tiles work; painting over a working
  map would hide a problem rather than fix one.
- Writes nothing to `_G` beyond `SLASH_MAPENH1` / `SlashCmdList`, replaces no
  Blizzard function, touches no protected code.
