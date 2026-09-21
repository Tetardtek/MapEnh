# MapEnh — guide d'installation

> **Votre carte du monde est vide, verte ou beige sur WoW: Forever en français ?**
> Ce guide vous la rend. Comptez deux minutes.

---

## Ce qui se passe, en trois lignes

Les images des cartes existent en anglais, mais **n'ont pas été publiées en
français**. Le jeu les demande quand même, ne les trouve pas, et n'a aucun
remplacement prévu : il affiche du vide.

Mesuré le 21/09 sur la bêta 1.60.1.69913 : **1867 images, 56 zones. Toutes
présentes en anglais, aucune en français.**

Ce n'est pas votre installation qui est abîmée. Rien à réparer chez vous.

---

# La méthode simple

## 1. Télécharger

Sur la page des releases, prenez **`MapEnh-0.3.0-complet.zip`** (environ 60 Mo).

C'est le seul fichier dont vous avez besoin. Les images des cartes sont dedans.

## 2. Décompresser

Décompressez-le dans le dossier `Interface/AddOns` de votre jeu.

Vous devez obtenir un dossier `MapEnh` contenant `MapEnh.toc`, `MapEnh.lua` et un
dossier `tuiles` bien rempli.

> Où est ce dossier ? À côté de votre `World of Warcraft`, dans
> `_classic_beta_/Interface/AddOns`. S'il n'existe pas, créez-le.

## 3. Jouer

Lancez le jeu, vérifiez que **MapEnh est coché** dans la liste des addons
(bouton **AddOns** à l'écran de sélection de personnage), et ouvrez votre carte.

C'est tout.

---

# La méthode sans images fournies

Si vous préférez que rien ne vous soit distribué — parce que ces images
appartiennent à Blizzard et que vous en avez déjà une copie —, vous pouvez les
sortir vous-même de votre propre installation. Le résultat est identique,
fichier pour fichier.

Comptez cinq minutes et un terminal.

## 1. Télécharger

Sur la page des releases, prenez **deux fichiers** :

| Fichier | À quoi il sert |
|---|---|
| `MapEnh-0.3.0.zip` | l'addon **sans les images** (50 Ko) |
| `mapenh-extract-…` | l'outil qui sort les images de votre jeu |

⚠️ Pas le zip `-complet` : celui-là contient déjà les images.

Prenez l'outil qui correspond à votre machine :

- **Windows** → `mapenh-extract-windows-x86_64.exe`
- **Linux** → `mapenh-extract-linux-x86_64`
- **Mac** → `mapenh-extract-macos-arm64` (Mac récent, puce M1/M2/M3/M4)
  ou `mapenh-extract-macos-x86_64` (Mac Intel, avant 2021)

---

## 2. Installer l'addon

Décompressez le zip dans le dossier `Interface/AddOns` de votre jeu.

Vous devez obtenir un dossier `MapEnh` contenant `MapEnh.toc`, `MapEnh.lua` et un
dossier `tools`.

**Placez l'outil téléchargé à l'étape 1 directement dans ce dossier `MapEnh`.**

---

## 3. Sortir les images

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

## 4. Vérifier

L'outil travaille une à deux minutes, puis affiche :

```
-- lot : 1867 extraits, 0 echecs, 0 partiellement chiffres
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

- Vérifiez que le dossier `MapEnh/tuiles/` contient bien 1867 fichiers. S'il est
  vide, c'est que vous avez pris le zip sans les images — reprenez le
  `-complet`, ou faites l'extraction.
- Vérifiez que MapEnh est coché dans la liste des addons (bouton **AddOns** à
  l'écran de sélection de personnage).
- Tapez `/mapenh` en jeu : l'addon dira ce qu'il fait.

### Je suis sur un client anglais

**C'est normal, et voulu.** Vos cartes fonctionnent déjà : l'addon se retire tout
seul plutôt que de repeindre par-dessus. Cela vaut pour `enUS` **et** `enGB`.

---

## Les commandes en jeu

| Commande | Effet |
|---|---|
| `/mapenh` | où en est la correction : combien de tuiles connues, combien remplacées |
| `/mapenh off` | couper la correction (pour comparer, ou en cas de souci) |
| `/mapenh on` | la remettre |
| `/mapenh bavard` | afficher les messages de diagnostic (coupés par défaut) |

Votre choix est retenu d'une session à l'autre.

---

## Questions

**Est-ce que ça peut abîmer mon jeu ?**
Il ne modifie rien dans le jeu. Il pose des images par-dessus la carte, c'est
tout. Pour l'enlever : supprimez le dossier `MapEnh`.

**Quelle différence entre les deux zips ?**
Aucune, côté addon : c'est le même code. Le `-complet` porte les images déjà
sorties, l'autre vous laisse les sortir de votre propre copie du jeu. Prenez le
premier si vous voulez juste jouer.

**Ça prend combien de place ?**
Environ 96 Mo d'images, sorties chez vous.

**Et quand Blizzard corrigera ?**
L'addon deviendra inutile, et c'est le but. Il sait déjà se retirer quand les
cartes fonctionnent.

---

*Un souci, une question : ouvrez un ticket sur le dépôt.*
