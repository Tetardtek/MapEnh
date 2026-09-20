/* casc-tirer — extraction par lot, qui NE S ARRETE PAS sur un bloc chiffre.
 *
 *   casc-tirer "<chemin>:<produit>" < lot.txt
 *   (une ligne par fichier : "#<fileDataId> <destination>")
 *
 * Difference avec `casc-extract getmany` : le drapeau CASC_OVERCOME_ENCRYPTED.
 * Sans lui, CascReadFile s arrete au premier bloc chiffre dont la cle manque et
 * le fichier sort TRONQUE — mesure du 17/09 : 72 tables DB2 sur 1161, dont
 * areatable.db2 coupee a 65536 octets sur 91212, dont la partie en clair.
 * Avec lui, les blocs illisibles sont des zeros et le reste est exploitable.
 *
 * Sortie sur stderr : combien extraits, combien partiellement chiffres.
 */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "CascLib.h"

static int Extraire(HANDLE hStorage, const char* cle, const char* dest, int* partiel)
{
    HANDLE hFile = NULL;
    DWORD flags = CASC_OVERCOME_ENCRYPTED;

    if (cle[0] == '#') {
        DWORD id = (DWORD)strtoul(cle + 1, NULL, 10);
        if (!CascOpenFile(hStorage, (const void*)(uintptr_t)id, 0,
                          CASC_OPEN_BY_FILEID | flags, &hFile)) {
            fprintf(stderr, "ouverture FileDataID %u : erreur %u\n", id, GetCascError());
            return 1;
        }
    } else if (!CascOpenFile(hStorage, cle, 0, CASC_OPEN_BY_NAME | flags, &hFile)) {
        fprintf(stderr, "ouverture '%s' : erreur %u\n", cle, GetCascError());
        return 1;
    }

    FILE* out = fopen(dest, "wb");
    if (!out) { perror(dest); CascCloseFile(hFile); return 1; }

    char tampon[0x10000];
    DWORD lus = 0;
    unsigned long total = 0, zeros = 0;
    while (CascReadFile(hFile, tampon, sizeof(tampon), &lus) && lus > 0) {
        fwrite(tampon, 1, lus, out);
        total += lus;
        /* un bloc entierement nul de 64 Kio trahit un bloc chiffre remplace */
        if (lus == sizeof(tampon)) {
            DWORD k = 0;
            while (k < lus && tampon[k] == 0) k++;
            if (k == lus) zeros += lus;
        }
    }
    fclose(out);
    CascCloseFile(hFile);
    if (zeros) (*partiel)++;
    return 0;
}

int main(int argc, char** argv)
{
    if (argc < 2) {
        fprintf(stderr, "usage: %s \"<chemin>:<produit>\" < lot.txt\n", argv[0]);
        return 1;
    }

    char chemin[1024];
    snprintf(chemin, sizeof(chemin), "%s", argv[1]);
    char* produit = strrchr(chemin, ':');
    if (produit && produit > chemin + 1) *produit++ = '\0'; else produit = NULL;

    CASC_OPEN_STORAGE_ARGS args = {0};
    args.Size = sizeof(args);
    args.szLocalPath = chemin;
    args.szCodeName = produit;

    HANDLE hStorage = NULL;
    if (!CascOpenStorageEx(NULL, &args, false, &hStorage)) {
        fprintf(stderr, "CascOpenStorageEx('%s','%s') : erreur %u\n",
                chemin, produit ? produit : "(premier)", GetCascError());
        return 2;
    }

    char ligne[2048];
    unsigned long ok = 0, echecs = 0;
    int partiel = 0;
    while (fgets(ligne, sizeof(ligne), stdin)) {
        char* p = ligne;
        while (*p == ' ' || *p == '\t') p++;
        char* fin = p + strlen(p);
        while (fin > p && (fin[-1] == '\n' || fin[-1] == '\r')) *--fin = '\0';
        if (!*p || *p == '#' * 0) { }
        if (!*p) continue;

        char* sep = p;
        while (*sep && *sep != ' ' && *sep != '\t') sep++;
        if (!*sep) { echecs++; continue; }
        *sep++ = '\0';
        while (*sep == ' ' || *sep == '\t') sep++;
        if (!*sep) { echecs++; continue; }

        if (Extraire(hStorage, p, sep, &partiel)) echecs++; else ok++;
    }

    CascCloseStorage(hStorage);
    fprintf(stderr, "-- lot : %lu extraits, %lu echecs, %d partiellement chiffres\n",
            ok, echecs, partiel);
    return echecs > 0 && ok == 0;
}
