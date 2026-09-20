# MapEnh — guide d'installation

> **Votre carte du monde est vide, verte ou beige sur WoW: Forever en français ?**
> Ce guide vous la rend. Comptez cinq minutes.

---

## Ce qui se passe, en trois lignes

Les images des cartes existent en anglais, mais **n'ont pas été publiées en
français**. Le jeu les demande quand même, ne les trouve pas, et n'a aucun
remplacement prévu : il affiche du vide.

Ce n'est pas votre installation qui est abîmée. Rien à réparer chez vous.

MapEnh remet les images. Elles ne sont **pas** fournies avec l'addon — vous les
sortez de **votre propre copie du jeu**, avec l'outil qui accompagne la release.

---

## Ce qu'il vous faut

- WoW: Forever installé
- Cinq minutes
- **Rien d'autre.** Pas de Python, pas de logiciel tiers à installer.

---

## Étape 1 — Télécharger

Sur la page des releases, prenez **deux fichiers** :

| Fichier | À quoi il sert |
|---|---|
| `MapEnh-x.y.z.zip` | l'addon |
| `mapenh-extract-…` | l'outil qui sort les images de votre jeu |

Prenez l'outil qui correspond à votre machine :

- **Windows** → `mapenh-extract-windows-x86_64.exe`
- **Linux** → `mapenh-extract-linux-x86_64`
- **Mac** → `mapenh-extract-macos-arm64` (Mac récent, puce M1/M2/M3/M4)
  ou `mapenh-extract-macos-x86_64` (Mac Intel, avant 2021)

---

## Étape 2 — Installer l'addon

Décompressez le zip dans le dossier `Interface/AddOns` de votre jeu.

Vous devez obtenir un dossier `MapEnh` contenant `MapEnh.toc`, `MapEnh.lua` et un
dossier `tools`.

**Placez l'outil téléchargé à l'étape 1 directement dans ce dossier `MapEnh`.**

---

## Étape 3 — Sortir les images

**Fermez le jeu ET Battle.net.** Tant qu'ils tournent, les données du jeu sont
verrouillées et l'outil ne pourra rien lire.

Ouvrez un terminal **dans le dossier `MapEnh`** :

- **Windows** : dans l'explorateur, tapez `cmd` dans la barre d'adresse du
  dossier, puis Entrée.
- **Mac** : clic droit sur le dossier → Services → « Nouveau terminal au dossier ».
- **Linux** : clic droit → « Ouvrir un terminal ici ».

Puis lancez la commande correspondant à votre système.

### Windows — Invite de commandes (cmd)

```
mapenh-extract-windows-x86_64.exe "C:\Program Files (x86)\World of Warcraft:wow_classic_beta" < tools\tiles-batch.txt
```

### Windows — PowerShell

PowerShell ne comprend pas le `<`. Utilisez plutôt :

```
Get-Content tools\tiles-batch.txt | .\mapenh-extract-windows-x86_64.exe "C:\Program Files (x86)\World of Warcraft:wow_classic_beta"
```

### Mac

```
chmod +x mapenh-extract-macos-arm64
./mapenh-extract-macos-arm64 "/Applications/World of Warcraft:wow_classic_beta" < tools/tiles-batch.txt
```

> **macOS bloque les programmes téléchargés.** Si vous voyez « impossible de
> vérifier le développeur », allez dans **Réglages → Confidentialité et sécurité**,
> et cliquez sur **Ouvrir quand même**. Ou bien, en une commande :
> `xattr -d com.apple.quarantine mapenh-extract-macos-arm64`

### Linux

```
chmod +x mapenh-extract-linux-x86_64
./mapenh-extract-linux-x86_64 "/chemin/vers/World of Warcraft:wow_classic_beta" < tools/tiles-batch.txt
```

---

## La commande, décortiquée

```
   "C:\Program Files (x86)\World of Warcraft : wow_classic_beta"
    └──────────── votre dossier de jeu ────┘   └── le produit ──┘
```

Le tout **entre guillemets, en un seul morceau**, avec un deux-points au milieu.
Le `C:` du début ne pose pas de problème : seul le **dernier** deux-points compte.

Le dossier à indiquer est celui qui **contient** `Data/` — généralement
`World of Warcraft`. Viser `Data/` directement fonctionne aussi.

---

## Étape 4 — Vérifier

L'outil travaille une à deux minutes, puis affiche :

```
-- lot : 1566 extraits, 0 echecs, 0 partiellement chiffres
```

**`0 echecs`, c'est gagné.** Lancez le jeu, ouvrez votre carte.

---

## Si ça ne marche pas

### « erreur 2 » avec un chemin affiché

```
CascOpenStorageEx('C:\Mauvais\Chemin','wow_classic_beta') : erreur 2
```

L'outil vous réaffiche **ce qu'il a compris**. Relisez les deux valeurs : le
dossier à gauche, et `wow_classic_beta` à droite. En général le dossier est
faux, ou les guillemets manquent.

### Beaucoup d'échecs

Le jeu ou Battle.net tournent encore. Fermez-les complètement et recommencez.

### La carte est toujours vide en jeu

- Vérifiez que le dossier `MapEnh/tuiles/` contient bien 1566 fichiers.
- Vérifiez que MapEnh est coché dans la liste des addons (bouton **AddOns** à
  l'écran de sélection de personnage).
- Tapez `/mapenh` en jeu : l'addon dira ce qu'il fait.

### Je suis sur un client anglais

**C'est normal, et voulu.** Vos cartes fonctionnent déjà : l'addon se retire tout
seul plutôt que de repeindre par-dessus.

---

## Questions

**Est-ce que ça peut abîmer mon jeu ?**
Il ne modifie rien dans le jeu. Il pose des images par-dessus la carte, c'est
tout. Pour l'enlever : supprimez le dossier `MapEnh`.

**Pourquoi les images ne sont-elles pas dans le zip ?**
Ce sont des images de Blizzard. Les redistribuer ne serait pas correct. Vous les
sortez de votre propre copie du jeu — celle que vous possédez déjà.

**Ça prend combien de place ?**
Environ 82 Mo d'images, sorties chez vous.

**Et quand Blizzard corrigera ?**
L'addon deviendra inutile, et c'est le but. Il sait déjà se retirer quand les
cartes fonctionnent.

---

*Un souci, une question : ouvrez un ticket sur le dépôt.*
