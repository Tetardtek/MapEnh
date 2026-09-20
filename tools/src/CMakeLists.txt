# Compiler l'extracteur avec CMake plutot qu'en pilotant cc et cl a la main.
#
# Quatre passages de CI ont echoue sur des differences de shell : `\` avale par
# PowerShell, `cl` absent du bash de Git, options MSVC melangees par MSYS au
# point d'inventer un fichier `CascLibRAS.lib`. Aucune de ces erreurs ne parlait
# du programme : toutes parlaient de la facon de l'appeler.
#
# CMake connait ces differences. On lui donne la source et la bibliotheque, il
# s'occupe du reste, et la meme commande marche des deux cotes.

cmake_minimum_required(VERSION 3.16)
project(mapenh_extract C)

set(CMAKE_C_STANDARD 11)

if(NOT DEFINED CASC_LIB)
    message(FATAL_ERROR "Passer -DCASC_LIB=<chemin de la bibliotheque CascLib>")
endif()
if(NOT DEFINED CASC_INCLUDE)
    message(FATAL_ERROR "Passer -DCASC_INCLUDE=<dossier des en-tetes CascLib>")
endif()

add_executable(mapenh-extract mapenh-extract.c)

# CascLib.h contient des `#pragma comment(lib, "CascLibRAD.lib")` : sous MSVC,
# elle demande d'elle-meme une bibliotheque dont le nom depend de la
# configuration (Release/Debug, Ansi/Unicode, CRT statique ou DLL). CMake, lui,
# produit `casc.lib`. Le lieur reclamait donc un fichier que personne ne
# construit — et son nom changeait d'un passage a l'autre, ce qui m'a fait
# chercher un chemin abime pendant deux tours.
#
# La macro est prevue par CascLib exactement pour ce cas.
target_compile_definitions(mapenh-extract PRIVATE CASCLIB_NO_AUTO_LINK_LIBRARY)
target_include_directories(mapenh-extract PRIVATE ${CASC_INCLUDE})
target_link_libraries(mapenh-extract PRIVATE ${CASC_LIB})

# CascLib est du C++ : sans la bibliotheque standard C++, l'edition de liens
# echoue sur des symboles absents. MSVC la lie tout seul, pas gcc.
if(NOT MSVC)
    target_link_libraries(mapenh-extract PRIVATE stdc++ z)
endif()
