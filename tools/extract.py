#!/usr/bin/env python3
"""extract.py — generate MapEnh's tiles from YOUR OWN game installation.

    ./extract.py --wow "/path/to/World of Warcraft"

MapEnh ships no artwork. The tiles it draws are Blizzard's, and they are already
on your disk: this script reads them from your local CASC storage and writes them
into the addon folder. Nothing is downloaded, and nothing leaves your machine.

Close the game AND Battle.net first. The CASC storage is locked while they run,
and a half-read tile is worse than a missing one.

Two ways to get the tiles:

  AUTOMATIC — needs a CASC extraction helper on your PATH (see --casc-tirer).
              Anything that reads a FileDataID out of a local CASC storage works.

  MANUAL    — run with --liste. This writes `tiles.txt`, the list of FileDataIDs
              the addon needs. Extract them with any CASC browser (wow.export,
              CASCExplorer, …) and drop them in `tuiles/` named `<id>.blp`.
              No helper, no compiler, nothing to trust.

The manual route is the supported one: the automatic helper is a small C program
from the workshop where this addon was written, and it is not shipped here.
"""
import argparse, os, re, subprocess, sys
from pathlib import Path

ICI = Path(__file__).resolve().parent
ADDON = ICI.parent
TUILES = ADDON / "tuiles"
PRODUIT = "wow_classic_beta"


def encore_ouvert():
    try:
        sortie = subprocess.run(["pgrep", "-f", r"[W]owB\.exe|[B]attle\.net\.exe"],
                                capture_output=True, text=True).stdout.strip()
        return bool(sortie)
    except FileNotFoundError:
        return False


def identifiants_voulus():
    """Les FileDataID que `donnees.lua` reference."""
    lua = ADDON / "donnees.lua"
    if not lua.exists():
        sys.exit("donnees.lua is missing — this addon is incomplete.")
    return sorted({int(x) for x in re.findall(r"tuiles\\\\(\d+)", lua.read_text())})


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--wow", default="", help="your World of Warcraft folder")
    ap.add_argument("--produit", default=PRODUIT)
    ap.add_argument("--casc-tirer", default="casc-tirer",
                    help="path to a CASC extraction helper")
    ap.add_argument("--liste", action="store_true",
                    help="only write tiles.txt, the list of FileDataIDs to extract")
    a = ap.parse_args()

    voulus = identifiants_voulus()

    if a.liste:
        # La voie manuelle ne touche pas au CASC : le jeu peut rester ouvert.
        liste = ICI.parent / "tiles.txt"
        deja = {int(f.stem) for f in TUILES.glob("*.blp") if f.stem.isdigit()}
        manquants = [f for f in voulus if f not in deja]
        liste.write_text("".join(f"{f}\n" for f in manquants))
        print(f"{len(manquants)} FileDataIDs written to {liste}")
        print("Extract them with any CASC browser, then put them in")
        print(f"  {TUILES}/<id>.blp")
        return 0

    if encore_ouvert():
        sys.exit("The game or Battle.net is still running. Close both, then retry.")
    deja = {int(f.stem) for f in TUILES.glob("*.blp") if f.stem.isdigit()}
    manquants = [f for f in voulus if f not in deja]

    print(f"{len(voulus)} tiles referenced · {len(deja)} already here · "
          f"{len(manquants)} to extract")
    if not manquants:
        print("Nothing to do.")
        return 0

    TUILES.mkdir(exist_ok=True)
    lot = ICI / "batch.txt"
    lot.write_text("".join(f"#{f} {TUILES / f'{f}.blp'}\n" for f in manquants))

    import shutil
    if shutil.which(a.casc_tirer) is None and not os.path.exists(a.casc_tirer):
        lot.unlink(missing_ok=True)
        sys.exit(f"No CASC helper found ({a.casc_tirer}).\n"
                 f"Use the manual route instead:  {sys.argv[0]} --liste")

    cible = f"{a.wow}:{a.produit}"
    print(f"Reading {cible} …")
    with open(lot) as f:
        r = subprocess.run([a.casc_tirer, cible], stdin=f)
    lot.unlink(missing_ok=True)
    if r.returncode != 0:
        sys.exit("Extraction failed. Is the path right, and is the game closed?")

    # Un fichier ecrit n'est pas un fichier valide : on verifie la signature.
    bons, mauvais = 0, []
    for f in voulus:
        p = TUILES / f"{f}.blp"
        if not p.exists():
            mauvais.append(f"{f} (missing)")
        elif p.open("rb").read(4) != b"BLP2":
            mauvais.append(f"{f} (not a BLP2 image)")
        else:
            bons += 1
    print(f"\n{bons}/{len(voulus)} tiles valid")
    if mauvais:
        print("Problems:", ", ".join(mauvais[:10]))
        return 1
    print("Done. Launch the game — the maps should be back.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
