# Changelog

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
