-- MapEnh — repose les tuiles de carte absentes du client francais.
--
-- v0.2 — la v0.1 n'a rien affiche. Cause probable : son garde-fou.
--
--   Il posait la premiere texture du client et concluait « le client sait faire »
--   si `GetTexture()` rendait quelque chose. Or RIEN ne prouve que `GetTexture`
--   rende `nil` pour un fichier absent : il rend peut-etre l'identifiant qu'on
--   vient de lui donner, fichier ou pas. Je l'avais suppose sans le mesurer, et
--   l'addon se retirait sans doute a chaque fois.
--
--   Remplace par `GetLocale()` : brut, mais il ne repose sur aucune supposition.
--
-- Cette version DIT ce qu'elle fait a chaque etape. Tant qu'on ne l'a pas vue
-- fonctionner une fois, un addon muet ne se debogue pas.

local nom, ns = ...

-- Temoin : quand il vaut false, nos overlays ne sont PAS poses. Si le rectangle
-- vert survit quand meme, il ne vient pas de nous — et s'il disparait, il en
-- vient. Aucune lecture de code ne repond a ca.
local poser_les_overlays = true

-- Silencieux par defaut. Le chat appartient au joueur : un addon qui repare une
-- carte n'a rien a y raconter quand il fonctionne. `/mapenh` rallume les messages
-- le temps d'un diagnostic.
local bavard = false
-- Un echec qui empeche l'addon de fonctionner se dit TOUJOURS, meme en mode
-- silencieux : un addon qui ne repare rien sans le signaler laisse croire que le
-- defaut vient du jeu.
local function alerter(f, ...)
    print("|cffff4444MapEnh|r " .. (select("#", ...) > 0 and f:format(...) or f))
end

local function dire(f, ...)
    if bavard then
        print("|cff44ff44MapEnh|r " .. (select("#", ...) > 0 and f:format(...) or f))
    end
end

local nos_tuiles = {}
-- Declaree ICI, et pas plus bas : `poser` s'en sert, et en Lua une locale
-- declaree apres la fonction qui la lit vaut nil a l'execution. La v0.4 est
-- tombee exactement la-dessus — « attempt to index a nil value », MapEnh.lua:28.
local nos_overlays = {}

-- ── Masquer les textures du pin d'exploration ───────────────────────────────
--
-- Ses fichiers manquent en francais et ce client peint en vert vif ce qu'il ne
-- trouve pas, au lieu de laisser transparent. Nos tuiles sont posees dessous :
-- il suffit de retirer l'aplat.
--
-- Deux precautions, chacune payee par un essai rate :
--   * en DIFFERE, parce que le pin se rafraichit APRES la couche de detail et
--     re-affiche ce qu'on vient de cacher ;
--   * a CHAQUE OUVERTURE de la carte, et pas seulement au changement de zone :
--     `RefreshDetailTiles` n'est appele que si la carte change, alors que le pin
--     se redessine chaque fois qu'on ouvre. Fermer puis rouvrir ramenait le vert.
local function masquer_pin()
    local carte = WorldMapFrame
    if not (carte and carte.EnumeratePinsByTemplate) then return 0, 0 end
    local trouves, caches = 0, 0
    pcall(function()
        for pin in carte:EnumeratePinsByTemplate("MapExplorationPinTemplate") do
            trouves = trouves + 1
            for _, nom in ipairs({"overlayTexturePool", "highlightRectPool"}) do
                local pool = pin[nom]
                if pool and pool.EnumerateActive then
                    for t in pool:EnumerateActive() do t:Hide(); caches = caches + 1 end
                end
            end
        end
    end)
    return trouves, caches
end

local function masquer_pin_differe()
    if GetLocale() == "enUS" then return end
    masquer_pin()
    C_Timer.After(0.6, masquer_pin)
    -- Un second passage plus tard : le chargement des tuiles peut relancer un
    -- rafraichissement du pin bien apres l'ouverture.
    C_Timer.After(1.8, masquer_pin)
end
local deja_dit = {}

-- Cache tout ce que nous avons pose sur CETTE couche. A appeler avant toute
-- decision : une couche est REUTILISEE d'une carte a l'autre, et ce qui y reste
-- se superpose a la suivante.
local function nettoyer(couche)
    local t = nos_tuiles[couche]
    if t then for _, x in ipairs(t) do x:Hide() end end
    local o = nos_overlays[couche]
    if o then for _, x in ipairs(o) do x:Hide() end end
end

local function poser(couche, mapCanvas)
    local mapID, layer = couche.mapID, couche.layerIndex
    local cle = tostring(mapID) .. ":" .. tostring(layer)

    -- ⚠️ D'ABORD nettoyer, ENSUITE voir si on a quelque chose a poser.
    --
    -- La version precedente rangeait ses textures par carte et sortait sans rien
    -- cacher quand la nouvelle carte n'etait pas fournie. Resultat, mesure le
    -- 19/09 a 3h49 : les tuiles de l'Ile de Zephras restaient affichees sur la
    -- carte du Monde, « THENDAL VILLAGE » compris, par-dessus Kalimdor. Un
    -- `/reload` les faisait disparaitre — et elles revenaient au changement
    -- suivant, ce qui designait bien un etat garde entre deux cartes.
    nettoyer(couche)

    local parCarte = ns.tuiles[mapID]
    local chemins = parCarte and parCarte[layer]
    if not chemins then
        if not deja_dit[cle] then
            deja_dit[cle] = true
            dire("carte %s couche %s — pas de tuiles fournies pour celle-ci",
                 tostring(mapID), tostring(layer))
        end
        return
    end

    -- Garde-fou : sur un client anglais les tuiles d'origine fonctionnent, on ne
    -- repeint rien par-dessus.
    if GetLocale() == "enUS" then
        if not deja_dit[cle] then
            deja_dit[cle] = true
            dire("client enUS — les tuiles d'origine fonctionnent, je me retire")
        end
        return
    end

    local ok, couches = pcall(C_Map.GetMapArtLayers, mapID)
    if not ok or type(couches) ~= "table" then
        dire("GetMapArtLayers a echoue sur la carte %s", tostring(mapID)); return
    end
    local info = couches[layer]
    if not info then dire("pas d'info pour la couche %s", tostring(layer)); return end

    local colonnes = math.ceil(info.layerWidth  / info.tileWidth)
    local lignes   = math.ceil(info.layerHeight / info.tileHeight)

    local lot = nos_tuiles[couche]
    if not lot then lot = {}; nos_tuiles[couche] = lot end

    local posees, manquantes = 0, 0
    for ligne = 1, lignes do
        for colonne = 1, colonnes do
            local index = (ligne - 1) * colonnes + colonne
            local chemin = chemins[index]
            if chemin then
                local t = lot[index]
                if not t then
                    t = couche:CreateTexture(nil, "ARTWORK")
                    lot[index] = t
                    if mapCanvas and mapCanvas.AddMaskableTexture then
                        pcall(mapCanvas.AddMaskableTexture, mapCanvas, t)
                    end
                end
                t:SetSize(info.tileWidth, info.tileHeight)
                t:ClearAllPoints()
                t:SetPoint("TOPLEFT", couche, "TOPLEFT",
                           (colonne - 1) * info.tileWidth,
                           -(ligne - 1) * info.tileHeight)
                t:SetTexture(chemin, nil, nil, "TRILINEAR")
                t:Show()

                if t:GetTexture() then posees = posees + 1 else manquantes = manquantes + 1 end
            end
        end
    end

    for i = lignes * colonnes + 1, #lot do
        if lot[i] then lot[i]:Hide() end
    end

    -- ── Second etage : les zones explorees ──────────────────────────────────
    --
    -- On le pose ICI, depuis le hook du terrain, et pas en hookant
    -- `MapExplorationPinMixin:RefreshOverlays`. Ce hook-la a ete essaye et n'a
    -- JAMAIS ete appele : les pins de WoW sont construits par `Mixin`, qui COPIE
    -- les fonctions dans chaque objet. Hooker la table du mixin apres coup ne
    -- touche aucune instance. (`MapCanvasDetailLayerMixin` s'y prete, lui — d'ou
    -- la confusion.)
    --
    -- Le repere est le meme : `worldmapoverlay` donne x/y en unites de couche,
    -- comme les tuiles de terrain. Le sous-niveau 1 les place au-dessus.
    local par_carte = poser_les_overlays and ns.overlays and ns.overlays[mapID]
    if par_carte then
        local oklot = nos_overlays[couche]
        if not oklot then oklot = {}; nos_overlays[couche] = oklot end
        for _, t in ipairs(oklot) do t:Hide() end

        local okz, zones = pcall(C_MapExplorationInfo.GetExploredMapTextures, mapID)
        local n = 0
        if okz and type(zones) == "table" then
            for _, zone in ipairs(zones) do
                for _, o in pairs(par_carte) do
                    if o.w == zone.textureWidth and o.h == zone.textureHeight
                       and o.x == zone.offsetX and o.y == zone.offsetY then
                        local cols = math.max(1, math.ceil(o.w / 256))
                        for k, chemin in ipairs(o.tuiles) do
                            n = n + 1
                            local t = oklot[n]
                            if not t then
                                t = couche:CreateTexture(nil, "ARTWORK", nil, 1)
                                oklot[n] = t
                                if mapCanvas and mapCanvas.AddMaskableTexture then
                                    pcall(mapCanvas.AddMaskableTexture, mapCanvas, t)
                                end
                            end
                            local li = math.floor((k - 1) / cols)
                            local co = (k - 1) % cols
                            -- Les tuiles de bord sont rognees : on ne montre que
                            -- la part utile du fichier, sinon elles debordent.
                            local l = math.min(256, o.w - co * 256)
                            local h = math.min(256, o.h - li * 256)
                            t:SetSize(l, h)
                            t:SetTexCoord(0, l / 256, 0, h / 256)
                            t:ClearAllPoints()
                            t:SetPoint("TOPLEFT", couche, "TOPLEFT",
                                       o.x + co * 256, -(o.y + li * 256))
                            t:SetTexture(chemin, nil, nil, "TRILINEAR")
                            t:Show()
                        end
                        break
                    end
                end
            end
        end
        -- Nos tuiles sont posees et comptees, et le rectangle reste. Elles sont
        -- donc SOUS quelque chose : le pin d'exploration de Blizzard, un cadre
        -- distinct dessine au-dessus de la couche de detail. Ses textures ne se
        -- resolvent pas — et ce client peint en vert vif ce qu'il ne trouve pas,
        -- au lieu de laisser transparent. D'ou l'aplat.
        --
        -- On masque donc les textures de ce cadre. Les notres, posees juste
        -- dessous aux memes coordonnees, prennent le relais.
        -- Le pin d'exploration range ses textures dans un POOL
        -- (`overlayTexturePool`, cf. `MapExplorationPinMixin:OnAcquired`), pas
        -- dans ses regions directes. Le premier essai parcourait `GetRegions()`
        -- et ne trouvait donc rien — sans le dire, faute de compteur.
        -- Le diagnostic est HORS de la condition : la version precedente ne
        -- disait rien du tout, et un silence ne distingue pas « mapCanvas est
        -- nil » de « aucun pin trouve ». Deja vu deux fois ce soir.
        masquer_pin_differe()
        if carte and carte.GetAllPinsByTemplate then
            local okp, pins = pcall(carte.GetAllPinsByTemplate, carte,
                                    "MapExplorationPinTemplate")
            local trouves, caches = 0, 0
            if okp and type(pins) == "table" then
                for pin in pairs(pins) do
                    trouves = trouves + 1
                    if type(pin) == "table" and pin.overlayTexturePool
                       and pin.overlayTexturePool.EnumerateActive then
                        for t in pin.overlayTexturePool:EnumerateActive() do
                            t:Hide(); caches = caches + 1
                        end
                    end
                end
            end
            dire("  pin d'exploration : %d trouvé(s), %d texture(s) masquée(s)%s",
                 trouves, caches, okp and "" or " — appel refusé")
        end

        dire("exploration : %d zone(s) explorée(s), %d tuile(s) reposée(s)",
             (okz and type(zones) == "table") and #zones or -1, n)
    end

    dire("carte %s : %dx%d = %d cases · %d posées, %d refusées",
         tostring(mapID), colonnes, lignes, colonnes * lignes, posees, manquantes)

    if manquantes > 0 then
        dire("  |cffff8800chemin testé :|r %s", tostring(chemins[1]))
    end
end

-- ── Second etage : les zones explorees ──────────────────────────────────────
--
-- `MapExplorationDataProvider` dessine PAR-DESSUS le terrain les portions de
-- carte que le joueur a decouvertes, avec ses propres fichiers. Ils manquent
-- eux aussi en francais : corriger le terrain seul laissait un rectangle de
-- couleur a l'endroit explore — mesure le 18/09 a 19h44, overlay 5529,
-- 325x267 en (250,22), exactement la tache qui restait.
--
-- On ne remplace pas le fournisseur de Blizzard : on repose nos textures apres
-- lui, aux coordonnees que `worldmapoverlay` declare.


-- `SLASH_*` et `SlashCmdList` sont les deux seules globales que cet addon touche,
-- et c'est l'interface prevue par le jeu pour ca. Rien d'autre n'est ecrit dans
-- `_G` : une ecriture globale a deja souille l'execution et casse la barre de vie
-- le 18/09.
SLASH_MAPENH1 = "/mapenh"
SlashCmdList["MAPENH"] = function()
    bavard = not bavard
    print(("|cff44ff44MapEnh|r messages %s."):format(bavard and "activés" or "coupés"))
    if bavard then
        local n = 0
        for _ in pairs(ns.tuiles) do n = n + 1 end
        print(("|cff44ff44MapEnh|r %d carte(s) fournie(s) · locale %s. Ouvre la carte.")
              :format(n, GetLocale()))
    end
end

local pret = CreateFrame("Frame")
pret:RegisterEvent("PLAYER_LOGIN")
pret:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    if GetLocale() == "enUS" then
        -- Rien a faire sur un client anglais : ses tuiles fonctionnent.
        return
    end
    if not MapCanvasDetailLayerMixin then
        alerter("MapCanvasDetailLayerMixin introuvable — la carte ne sera pas réparée.")
        return
    end
    if type(MapCanvasDetailLayerMixin.RefreshDetailTiles) ~= "function" then
        alerter("RefreshDetailTiles n'est pas une fonction — la carte ne sera pas réparée.")
        return
    end
    hooksecurefunc(MapCanvasDetailLayerMixin, "RefreshDetailTiles", poser)

    -- Chaque ouverture de la carte, pas seulement chaque changement de zone.
    if WorldMapFrame and WorldMapFrame.HookScript then
        WorldMapFrame:HookScript("OnShow", masquer_pin_differe)
    else
        alerter("WorldMapFrame introuvable — l'aplat reviendra à chaque réouverture.")
    end

    local n = 0; for _ in pairs(ns.tuiles) do n = n + 1 end
    dire("hook posé · %d carte(s) fournie(s). Ouvre la carte pour voir la suite.", n)
end)
