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

  MANUAL    — the supported route, and it is three steps:

                1. ./extract.py --liste
                   writes tiles.txt (the FileDataIDs) and paths.txt (their file
                   names). All but five live under `interface/worldmap/`.

                2. In wow.export or CASCExplorer, filter on `interface/worldmap`
                   and export the lot. One filter, one click — not 1566 files
                   picked by hand.

                3. ./extract.py --ranger <the folder you exported to>
                   renames what you exported into `tuiles/<id>.blp`, which is
                   what the addon looks for.

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
                    help="write tiles.txt and paths.txt, then stop")
    ap.add_argument("--ranger", metavar="DOSSIER",
                    help="rename files exported by a CASC browser into tuiles/<id>.blp")
    a = ap.parse_args()

    voulus = identifiants_voulus()

    if a.ranger:
        # wow.export et CASCExplorer nomment les fichiers par leur CHEMIN, pas par
        # leur identifiant. L'addon, lui, cherche `<id>.blp`. C'est tout l'ecart
        # entre « techniquement possible » et « utilisable », et il se comble ici.
        carte = {}
        csv = ICI / "paths.csv"
        if csv.exists():
            for l in csv.read_text().splitlines():
                if l.startswith("#") or ";" not in l: continue
                fd, chemin = l.split(";", 1)
                if chemin: carte[chemin.strip().lower()] = int(fd)
        # `carte` va du chemin vers l'identifiant ; on aura besoin de l'inverse
        # pour distinguer « pas exporte » de « pas de nom connu ».

        source = Path(a.ranger)
        if not source.is_dir():
            sys.exit(f"Not a folder: {source}")
        TUILES.mkdir(exist_ok=True)

        trouves, copies = 0, 0
        for f in source.rglob("*.blp"):
            # On compare sur la fin du chemin : peu importe ou l'export a ete range.
            rel = f.as_posix().lower()
            fd = next((i for c, i in carte.items() if rel.endswith(c)), None)
            if fd is None:
                continue
            trouves += 1
            cible = TUILES / f"{fd}.blp"
            if not cible.exists():
                cible.write_bytes(f.read_bytes())
                copies += 1

        voulus_n = len(identifiants_voulus())
        presents = len([x for x in TUILES.glob("*.blp") if x.stem.isdigit()])
        print(f"{trouves} exported files recognised · {copies} copied")
        print(f"{presents}/{voulus_n} tiles now in place")
        if presents < voulus_n:
            # Deux raisons tres differentes de manquer, et les confondre envoie
            # l'utilisateur chercher au mauvais endroit.
            deja = {int(x.stem) for x in TUILES.glob("*.blp") if x.stem.isdigit()}
            restants = [f for f in identifiants_voulus() if f not in deja]
            sans_nom = [f for f in restants if f not in carte.values()]
            pas_exportes = len(restants) - len(sans_nom)
            print()
            if pas_exportes:
                print(f"{pas_exportes} tiles are still missing but DO have a known name —")
                print("they were simply not in what you exported. Widen the filter to")
                print("  interface/worldmap")
                print("and run --ranger again.")
            if sans_nom:
                print(f"{len(sans_nom)} tiles have no known file name; they can only be")
                print("pulled by FileDataID (see tiles.txt). The map works without them.")
        return 0

    if a.liste:
        # La voie manuelle ne touche pas au CASC : le jeu peut rester ouvert.
        liste = ICI.parent / "tiles.txt"
        deja = {int(f.stem) for f in TUILES.glob("*.blp") if f.stem.isdigit()}
        manquants = [f for f in voulus if f not in deja]
        liste.write_text("".join(f"{f}\n" for f in manquants))

        # La liste des NOMS aussi : c'est elle qu'on donne au navigateur CASC.
        carte = {}
        csv = ICI / "paths.csv"
        if csv.exists():
            for l in csv.read_text().splitlines():
                if l.startswith("#") or ";" not in l: continue
                fd, chemin = l.split(";", 1)
                if chemin: carte[int(fd)] = chemin.strip()
        noms = ICI.parent / "paths.txt"
        connus = [carte[f] for f in manquants if f in carte]
        noms.write_text("".join(c + "\n" for c in connus))

        print(f"{len(manquants)} tiles needed")
        print(f"  {liste.name}  — their FileDataIDs")
        print(f"  {noms.name}  — their file names ({len(connus)} known)")
        print()
        print("In wow.export or CASCExplorer, filter on  interface/worldmap  and")
        print("export everything. Then:")
        print(f"  {sys.argv[0]} --ranger <your export folder>")
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
