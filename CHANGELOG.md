# Changelog

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

### Notes
- **Stands down on an English client.** Its tiles work; painting over a working
  map would hide a problem rather than fix one.
- Writes nothing to `_G` beyond `SLASH_MAPENH1` / `SlashCmdList`, replaces no
  Blizzard function, touches no protected code.
