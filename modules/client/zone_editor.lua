-- ====================================
-- ZONE EDITOR & MANAGEMENT (IMPROVED)
-- ====================================

ZoneEditor = {}
ZoneEditor.CreationMode = false
ZoneEditor.CurrentPoints = {}
ZoneEditor.CurrentZoneType = nil
ZoneEditor.DebugMarkers = {}

function ZoneEditor:OpenMainMenu()
    lib.registerContext({
        id = 'zombie_zone_main',
        title = '🧟 Zombie Zone Editor',
        options = {
            {
                title = 'Kreis-Zone erstellen',
                description = 'Erstelle eine runde Zombie-Zone',
                icon = 'circle',
                onSelect = function()
                    self:CreateCircleZone()
                end
            },
            {
                title = 'Polygon-Zone erstellen',
                description = 'Erstelle eine Zone durch Ablaufen von Eckpunkten',
                icon = 'draw-polygon',
                onSelect = function()
                    self:StartPolygonCreation()
                end
            },
            {
                title = 'Zonen verwalten',
                description = 'Alle Zonen anzeigen und verwalten',
                icon = 'list',
                onSelect = function()
                    self:OpenZoneList()
                end
            }
        }
    })
    
    lib.showContext('zombie_zone_main')
end

-- ====================================
-- CIRCLE ZONE CREATION
-- ====================================

function ZoneEditor:CreateCircleZone()
    local input = lib.inputDialog('Kreis-Zone Konfiguration', {
        {type = 'input', label = 'Name der Zone', required = true, placeholder = 'Sandy Shores'},
        {type = 'number', label = 'Radius (Meter)', min = 10, max = 200, default = 50},
        {type = 'number', label = 'Max. Zombies', min = 1, max = 50, default = 15},
        {
            type = 'select',
            label = 'Gefahr-Level',
            required = true,
            options = {
                {value = 'low', label = 'Niedrig'},
                {value = 'medium', label = 'Mittel'},
                {value = 'high', label = 'Hoch'}
            },
            default = 'medium'
        }
    })
    
    if not input then return end
    
    local coords = GetEntityCoords(PlayerPedId())
    
    local zoneData = {
        type = 'circle',
        coords = {x = coords.x, y = coords.y, z = coords.z},
        radius = input[2],
        maxZombies = input[3],
        dangerLevel = input[4],
        enabled = true
    }
    
    TriggerServerEvent('d4rk_zombies:server:CreateZone', input[1], zoneData)
    lib.notify({
        title = 'Zone erstellt',
        description = input[1] .. ' wurde erfolgreich erstellt',
        type = 'success'
    })
end

-- ====================================
-- POLYGON ZONE CREATION (With /zadd and /zsave)
-- ====================================

function ZoneEditor:StartPolygonCreation()
    local input = lib.inputDialog('Polygon-Zone Konfiguration', {
        {type = 'input', label = 'Name der Zone', required = true},
        {type = 'number', label = 'Max. Zombies', min = 1, max = 50, default = 30},
        {
            type = 'select',
            label = 'Gefahr-Level',
            options = {
                {value = 'low', label = 'Niedrig'},
                {value = 'medium', label = 'Mittel'},
                {value = 'high', label = 'Hoch'}
            },
            default = 'medium'
        }
    })
    
    if not input then return end
    
    self.CreationMode = true
    self.CurrentPoints = {}
    self.CurrentZoneName = input[1]
    self.CurrentMaxZombies = input[2]
    self.CurrentDangerLevel = input[3]
    
    lib.notify({
        title = 'Polygon-Modus AKTIV',
        description = '1. Laufe zu Eckpunkten\n2. Nutze /zadd für jeden Punkt\n3. Nutze /zsave zum Speichern\n(Min. 3 Punkte)',
        type = 'inform',
        duration = 10000
    })
    
    -- Start visual feedback thread
    self:StartDebugVisualization()
end

function ZoneEditor:AddPoint()
    if not self.CreationMode then
        lib.notify({
            title = 'Fehler',
            description = 'Kein Zonen-Erstellungs-Modus aktiv!',
            type = 'error'
        })
        return
    end
    
    local coords = GetEntityCoords(PlayerPedId())
    table.insert(self.CurrentPoints, vector2(coords.x, coords.y))
    
    -- Add debug marker
    table.insert(self.DebugMarkers, {
        coords = coords,
        number = #self.CurrentPoints
    })
    
    lib.notify({
        title = 'Punkt gesetzt',
        description = 'Punkt #' .. #self.CurrentPoints .. ' hinzugefügt',
        type = 'success'
    })
    
    PlaySoundFrontend(-1, "CHECKPOINT_BEHIND", "HUD_MINI_GAME_SOUNDSET", 1)
end

function ZoneEditor:SavePolygon()
    if not self.CreationMode then
        lib.notify({
            title = 'Fehler',
            description = 'Kein Zonen-Erstellungs-Modus aktiv!',
            type = 'error'
        })
        return
    end
    
    if #self.CurrentPoints < 3 then
        lib.notify({
            title = 'Fehler',
            description = 'Du brauchst mindestens 3 Punkte! (Aktuell: ' .. #self.CurrentPoints .. ')',
            type = 'error'
        })
        return
    end
    
    local playerZ = GetEntityCoords(PlayerPedId()).z
    
    local zoneData = {
        type = 'polygon',
        points = self.CurrentPoints,
        maxZombies = self.CurrentMaxZombies,
        dangerLevel = self.CurrentDangerLevel,
        enabled = true,
        minZ = playerZ - 10.0,
        maxZ = playerZ + 20.0
    }
    
    TriggerServerEvent('d4rk_zombies:server:CreateZone', self.CurrentZoneName, zoneData)
    
    lib.notify({
        title = 'Zone gespeichert',
        description = self.CurrentZoneName .. ' wurde erstellt!',
        type = 'success'
    })
    
    -- Cleanup
    self:CancelCreation()
end

function ZoneEditor:CancelCreation()
    self.CreationMode = false
    self.CurrentPoints = {}
    self.DebugMarkers = {}
    self.CurrentZoneName = nil
    self.CurrentMaxZombies = nil
    self.CurrentDangerLevel = nil
end

-- ====================================
-- DEBUG VISUALIZATION
-- ====================================

function ZoneEditor:StartDebugVisualization()
    CreateThread(function()
        while self.CreationMode do
            Wait(0)
            
            -- Draw markers at each point
            for i, marker in ipairs(self.DebugMarkers) do
                DrawMarker(
                    1, -- Cylinder
                    marker.coords.x, marker.coords.y, marker.coords.z - 1.0,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    1.0, 1.0, 2.0,
                    0, 255, 0, 150,
                    false, true, 2, false, nil, nil, false
                )
                
                -- Draw text label
                DrawText3D(marker.coords.x, marker.coords.y, marker.coords.z + 1.0, '#' .. marker.number)
            end
            
            -- Draw lines between points
            if #self.DebugMarkers > 1 then
                for i = 1, #self.DebugMarkers - 1 do
                    local p1 = self.DebugMarkers[i].coords
                    local p2 = self.DebugMarkers[i + 1].coords
                    DrawLine(p1.x, p1.y, p1.z, p2.x, p2.y, p2.z, 0, 255, 0, 255)
                end
                
                -- Draw closing line
                if #self.DebugMarkers >= 3 then
                    local first = self.DebugMarkers[1].coords
                    local last = self.DebugMarkers[#self.DebugMarkers].coords
                    DrawLine(first.x, first.y, first.z, last.x, last.y, last.z, 0, 255, 0, 150)
                end
            end
            
            -- Draw help text
            BeginTextCommandDisplayHelp("STRING")
            AddTextComponentSubstringPlayerName("~g~/zadd~w~ - Punkt hinzufügen | ~g~/zsave~w~ - Speichern | ~r~BACKSPACE~w~ - Abbrechen")
            EndTextCommandDisplayHelp(0, false, true, -1)
            
            -- Cancel with backspace
            if IsControlJustPressed(0, 177) then
                lib.notify({
                    title = 'Abgebrochen',
                    description = 'Zonen-Erstellung abgebrochen',
                    type = 'error'
                })
                self:CancelCreation()
            end
        end
    end)
end

function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
end

-- ====================================
-- ZONE MANAGEMENT
-- ====================================

function ZoneEditor:OpenZoneList()
    lib.callback('d4rk_zombies:server:GetZones', false, function(zones)
        local options = {}
        
        for zoneName, zoneData in pairs(zones) do
            local dangerColor = zoneData.dangerLevel == 'high' and 'red' or zoneData.dangerLevel == 'low' and 'green' or 'yellow'
            
            table.insert(options, {
                title = zoneName,
                description = ('Typ: %s | Max: %s | Gefahr: %s'):format(
                    zoneData.type,
                    zoneData.maxZombies,
                    zoneData.dangerLevel or 'medium'
                ),
                icon = zoneData.enabled and 'check-circle' or 'times-circle',
                iconColor = zoneData.enabled and 'green' or 'red',
                onSelect = function()
                    self:OpenZoneManagement(zoneName, zoneData)
                end
            })
        end
        
        if #options == 0 then
            options = {{
                title = 'Keine Zonen vorhanden',
                description = 'Erstelle deine erste Zone',
                icon = 'info-circle'
            }}
        end
        
        lib.registerContext({
            id = 'zombie_zone_list',
            title = 'Zonen Liste',
            menu = 'zombie_zone_main',
            options = options
        })
        
        lib.showContext('zombie_zone_list')
    end)
end

function ZoneEditor:OpenZoneManagement(name, data)
    lib.registerContext({
        id = 'zombie_zone_manage',
        title = name,
        menu = 'zombie_zone_list',
        options = {
            {
                title = 'Teleportieren',
                description = 'Teleportiere zur Zone',
                icon = 'location-arrow',
                onSelect = function()
                    local coords = data.coords or (data.points and data.points[1]) or vector3(0, 0, 0)
                    if data.coords then
                        SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z)
                    else
                        SetEntityCoords(PlayerPedId(), coords.x, coords.y, GetEntityCoords(PlayerPedId()).z)
                    end
                    lib.notify({title = 'Teleportiert', type = 'success'})
                end
            },
            {
                title = 'Bearbeiten',
                description = 'Max Zombies ändern',
                icon = 'edit',
                onSelect = function()
                    local input = lib.inputDialog('Zone bearbeiten', {
                        {type = 'number', label = 'Max Zombies', default = data.maxZombies, min = 1, max = 50}
                    })
                    
                    if input then
                        TriggerServerEvent('d4rk_zombies:server:UpdateZone', name, {maxZombies = input[1]})
                        lib.notify({title = 'Aktualisiert', description = name, type = 'success'})
                    end
                end
            },
            {
                title = data.enabled and 'Deaktivieren' or 'Aktivieren',
                description = 'Zone ein/ausschalten',
                icon = data.enabled and 'toggle-off' or 'toggle-on',
                onSelect = function()
                    TriggerServerEvent('d4rk_zombies:server:UpdateZone', name, {enabled = not data.enabled})
                    lib.notify({title = 'Status geändert', type = 'success'})
                end
            },
            {
                title = 'Löschen',
                description = 'Zone permanent entfernen',
                icon = 'trash',
                iconColor = 'red',
                onSelect = function()
                    local confirm = lib.alertDialog({
                        header = 'Zone löschen?',
                        content = ('Zone "%s" wirklich löschen?'):format(name),
                        centered = true,
                        cancel = true
                    })
                    
                    if confirm == 'confirm' then
                        TriggerServerEvent('d4rk_zombies:server:DeleteZone', name)
                        lib.notify({title = 'Gelöscht', description = name, type = 'success'})
                        lib.hideContext()
                    end
                end
            }
        }
    })
    
    lib.showContext('zombie_zone_manage')
end

-- ====================================
-- COMMANDS
-- ====================================

RegisterCommand(Config.Commands.ZoneMenu, function()
    lib.callback('d4rk_zombies:server:CheckPermission', false, function(hasPermission)
        if hasPermission then
            ZoneEditor:OpenMainMenu()
        else
            lib.notify({title = 'Keine Berechtigung', type = 'error'})
        end
    end)
end)

RegisterCommand(Config.Commands.AddZonePoint, function()
    ZoneEditor:AddPoint()
end)

RegisterCommand(Config.Commands.SaveZone, function()
    ZoneEditor:SavePolygon()
end)
