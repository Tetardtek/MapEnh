-- MapEnh — rend au client francais les tuiles de carte qu'il ne recoit pas.
--
-- Le defaut (beta 1.60.1.69913) : les cartes de Forever n'ont ete publiees
-- qu'en anglais. Mesure du 21/09 sur les 1867 tuiles concernees, en
-- interrogeant le depot CASC locale par locale : introuvables en frFR,
-- presentes en enUS et enGB, aux MEMES FileDataID. Le client les demande
-- correctement, ne les recoit pas, et ce client peint en vert vif ce qu'il ne
-- trouve pas au lieu de laisser transparent. D'ou la carte verte.
--
-- ── v0.3.0 : on remplace, on ne repose plus ───────────────────────────────
--
-- Jusqu'a la v0.2.3, MapEnh creait ses propres textures et les positionnait
-- lui-meme : il fallait connaitre la grille de chaque carte, rogner les tuiles
-- de bord, masquer le pin d'exploration en differe, et nettoyer la couche avant
-- chaque changement de carte — chacune de ces etapes ayant coute son bug.
--
-- Desormais on laisse Blizzard tout placer, et on se contente d'intervenir sur
-- la texture qu'il vient de poser : si son FileDataID est l'un de ceux qui
-- manquent, on lui donne notre copie locale. Aucune position calculee, aucun
-- masque, aucun etat garde entre deux cartes. Les artefacts au changement de
-- zone disparaissent avec le code qui les produisait.
--
-- L'idee vient de MapFixForever (Pirson, MIT), decouvert le 21/09. Elle est
-- meilleure que la notre et nous la reprenons volontiers. Ce que MapEnh garde
-- en propre : il ne redistribue aucune image de Blizzard — les tuiles sont
-- extraites de VOTRE installation par tools/extract.py.

local nom, ns = ...

-- Les tuiles portent le nom de leur FileDataID : le chemin se calcule, il n'y a
-- aucune table de correspondance a tenir.
local DOSSIER = "Interface\\AddOns\\MapEnh\\tuiles\\"
local FILTRE  = "TRILINEAR"

-- enGB autant que enUS : la mesure du 21/09 donne 1867 tuiles sur 1867
-- presentes dans les deux. La v0.2 ne connaissait qu'enUS et se serait donc
-- mise au travail pour rien sur un client britannique.
local ANGLAIS = { enUS = true, enGB = true }

-- Le pin d'exploration se redessine par des chemins qu'aucun hook ne couvre
-- entierement (changement de zone, fin de chargement d'une tuile, revelation
-- d'une zone). Une relecture periodique tant que la carte est ouverte rattrape
-- ce que les hooks laissent passer. C'est peu couteux : on ne parcourt que les
-- textures actives, et on ne touche que celles qu'on reconnait.
local INTERVALLE = 0.5

local reglages          -- SavedVariables, rempli a PLAYER_LOGIN
local remplacements = 0
local vues = {}         -- FileDataID reconnus au moins une fois

-- Silencieux par defaut : le chat appartient au joueur, un addon qui repare une
-- carte n'a rien a y raconter quand il fonctionne. Un echec qui l'empeche de
-- fonctionner se dit TOUJOURS — sans quoi le joueur croit que le jeu est en
-- cause.
local function alerter(f, ...)
    print("|cffff4444MapEnh|r " .. (select("#", ...) > 0 and f:format(...) or f))
end

local function dire(f, ...)
    if reglages and reglages.bavard then
        print("|cff44ff44MapEnh|r " .. (select("#", ...) > 0 and f:format(...) or f))
    end
end

local function actif()
    return reglages and reglages.actif ~= false and not ANGLAIS[GetLocale()]
end

-- Le FileDataID que Blizzard a demande. Quand le fichier n'a pas pu etre charge,
-- `GetTextureFileID` peut ne rien rendre : `GetTexture` rend alors ce qui a ete
-- passe a `SetTexture`, c'est-a-dire l'identifiant lui-meme.
local function identifiant(texture)
    return texture:GetTextureFileID() or tonumber(texture:GetTexture())
end

local function reparer(texture)
    local id = identifiant(texture)
    if not (id and ns.ART[id]) then return end
    vues[id] = true
    remplacements = remplacements + 1
    texture:SetTexture(DOSSIER .. id, nil, nil, FILTRE)
end

local function reparer_pool(pool)
    if not (pool and pool.EnumerateActive) then return end
    for texture in pool:EnumerateActive() do reparer(texture) end
end

-- ── Les trois chemins par lesquels une tuile apparait ──────────────────────
--
-- 1. les mixins, pour les cadres crees APRES nous ;
-- 2. les cadres deja construits, a l'ouverture et au changement de carte ;
-- 3. la relecture periodique, pour tout le reste.
--
-- Hooker le mixin ne suffit pas a lui seul : les pins de WoW sont construits
-- par `Mixin`, qui COPIE les fonctions dans chaque objet. Un hook pose sur la
-- table du mixin apres la creation d'un pin ne touche pas ce pin-la. D'ou le
-- hook par instance ci-dessous, et la relecture.

local pins_hookes = setmetatable({}, { __mode = "k" })

local function parcourir(cadre)
    if not (cadre and actif()) then return end
    if cadre.detailLayerPool and cadre.detailLayerPool.EnumerateActive then
        for couche in cadre.detailLayerPool:EnumerateActive() do
            reparer_pool(couche.detailTilePool)
        end
    end
    if not cadre.EnumeratePinsByTemplate then return end
    for pin in cadre:EnumeratePinsByTemplate("MapExplorationPinTemplate") do
        if not pins_hookes[pin] and type(pin.RefreshOverlays) == "function" then
            pins_hookes[pin] = true
            hooksecurefunc(pin, "RefreshOverlays", function(self)
                reparer_pool(self.overlayTexturePool)
            end)
        end
        reparer_pool(pin.overlayTexturePool)
    end
end

local cadres_hookes = setmetatable({}, { __mode = "k" })

local function hooker_cadre(cadre)
    if not cadre or cadres_hookes[cadre] or not cadre.EnumeratePinsByTemplate then
        return
    end
    cadres_hookes[cadre] = true

    if type(cadre.OnMapChanged) == "function" then
        hooksecurefunc(cadre, "OnMapChanged", parcourir)
    end
    if cadre.HookScript then
        cadre:HookScript("OnShow", parcourir)
        local ecoule = 0
        cadre:HookScript("OnUpdate", function(self, delta)
            ecoule = ecoule + delta
            if ecoule < INTERVALLE then return end
            ecoule = 0
            parcourir(self)
        end)
    end
end

local mixin_detail, mixin_exploration = false, false

local function poser_les_hooks()
    if not mixin_detail and MapCanvasDetailLayerMixin
       and type(MapCanvasDetailLayerMixin.RefreshDetailTiles) == "function" then
        mixin_detail = true
        hooksecurefunc(MapCanvasDetailLayerMixin, "RefreshDetailTiles", function(self)
            if actif() then reparer_pool(self.detailTilePool) end
        end)
    end
    if not mixin_exploration and MapExplorationPinMixin
       and type(MapExplorationPinMixin.RefreshOverlays) == "function" then
        mixin_exploration = true
        hooksecurefunc(MapExplorationPinMixin, "RefreshOverlays", function(self)
            if actif() then reparer_pool(self.overlayTexturePool) end
        end)
    end
    -- La carte de zone (BattlefieldMapFrame) se charge a la demande : d'ou le
    -- second passage sur ADDON_LOADED.
    hooker_cadre(WorldMapFrame)
    hooker_cadre(BattlefieldMapFrame)
    return mixin_detail
end

-- ── /mapenh ───────────────────────────────────────────────────────────────
--
-- `SLASH_*` et `SlashCmdList` sont les deux seules globales que cet addon
-- touche, et c'est l'interface prevue par le jeu. Rien d'autre n'est ecrit dans
-- `_G` : une ecriture globale a deja souille l'execution et casse la barre de
-- vie le 18/09.

local function fournies()
    local n = 0
    for _ in pairs(ns.ART) do n = n + 1 end
    return n
end

local function etat()
    if ANGLAIS[GetLocale()] then
        print("|cff44ff44MapEnh|r client en anglais : les cartes sont completes, "
              .. "il n'y a rien a corriger.")
        return
    end
    local n = 0
    for _ in pairs(vues) do n = n + 1 end
    print(("|cff44ff44MapEnh|r correction %s · %d tuiles connues · %d reconnues sur la carte, %d remplacements.")
          :format(reglages.actif ~= false and "active" or "coupee",
                  fournies(), n, remplacements))
    if remplacements == 0 then
        print("|cff44ff44MapEnh|r ouvrez la carte ; si rien ne change, les tuiles "
              .. "ne sont pas extraites — voir GUIDE-FR.md.")
    end
end

SLASH_MAPENH1 = "/mapenh"
SlashCmdList["MAPENH"] = function(message)
    local commande = (message or ""):lower():match("^%s*(%S*)")
    if commande == "on" or commande == "off" then
        reglages.actif = (commande == "on")
        print(("|cff44ff44MapEnh|r correction %s. Changez de carte pour voir le resultat.")
              :format(reglages.actif and "activee" or "coupee"))
        return
    elseif commande == "bavard" then
        reglages.bavard = not reglages.bavard
        print(("|cff44ff44MapEnh|r messages %s.")
              :format(reglages.bavard and "actives" or "coupes"))
        return
    end
    etat()
end

local pret = CreateFrame("Frame")
pret:RegisterEvent("PLAYER_LOGIN")
pret:RegisterEvent("ADDON_LOADED")
pret:SetScript("OnEvent", function(self, evenement)
    if evenement == "PLAYER_LOGIN" then
        MapEnhReglages = MapEnhReglages or {}
        reglages = MapEnhReglages
        if reglages.actif  == nil then reglages.actif  = true  end
        if reglages.bavard == nil then reglages.bavard = false end

        if ANGLAIS[GetLocale()] then
            -- Rien a faire sur un client anglais : ses tuiles fonctionnent.
            return
        end
        if not poser_les_hooks() then
            alerter("MapCanvasDetailLayerMixin introuvable — la carte ne sera pas reparee.")
            return
        end
        dire("hooks poses · %d tuiles connues · locale %s. Ouvrez la carte.",
             fournies(), GetLocale())
    elseif reglages and not ANGLAIS[GetLocale()] then
        poser_les_hooks()
    end
end)
