-- ====================================
-- NOISE & STEALTH SYSTEM (IMPROVED)
-- ====================================

NoiseSystem = {}
NoiseSystem.CurrentNoiseRadius = 0.0
NoiseSystem.BlipHandle = nil
NoiseSystem.LastNoiseType = "none"

function NoiseSystem:Init()
    if not Config.NoiseSystem.Enabled then return end

    CreateThread(function()
        while true do
            local ped = PlayerPedId()
            local targetNoise = self:CalculateNoiseRadius(ped)

            -- Lärm-Nachhall (Decay):
            -- Wenn der neue Lärm leiser ist als der aktuelle, sinkt der Radius nur langsam.
            if targetNoise > self.CurrentNoiseRadius then
                self.CurrentNoiseRadius = targetNoise
            else
                -- Sinkt um 2.0 Einheiten pro Check (ca. 8.0 pro Sekunde)
                self.CurrentNoiseRadius = math.max(0.0, self.CurrentNoiseRadius - 2.0)
            end

            if self.CurrentNoiseRadius > 0.1 then
                self:UpdateVisualFeedback(ped)
            else
                self:RemoveVisualFeedback()
            end

            Wait(250)
        end
    end)
end

function NoiseSystem:CalculateNoiseRadius(ped)
    local noise = 0.0

    -- Fahrzeug-Logik
    if IsPedInAnyVehicle(ped, false) then
        local vehicle = GetVehiclePedIsIn(ped, false)
        local speed = GetEntitySpeed(vehicle) * 3.6 -- km/h
        -- Standgas macht weniger Lärm als Vollgas
        noise = (speed > 5.0) and (speed * (Config.NoiseSystem.VehicleMultiplier or 0.5)) or 5.0
        return noise
    end

    -- Bewegungs-Status zu Fuß
    if GetPedStealthMovement(ped) then
        noise = Config.NoiseSystem.Crouching or 2.0
    elseif IsPedSprinting(ped) or IsPedRunning(ped) then
        noise = Config.NoiseSystem.Running or 15.0
    elseif IsPedWalking(ped) then
        noise = Config.NoiseSystem.Walking or 7.0
    end

    -- Schuss-Erkennung (Priorität vor Bewegung)
    if IsPedShooting(ped) then
        local weapon = GetSelectedPedWeapon(ped)
        local hasSuppressor = HasPedGotWeaponComponent(ped, weapon, `COMPONENT_AT_PI_SUPP`) or
            HasPedGotWeaponComponent(ped, weapon, `COMPONENT_AT_AR_SUPP`) or
            HasPedGotWeaponComponent(ped, weapon, `COMPONENT_AT_AR_SUPP_02`)

        local shootingNoise = hasSuppressor and (Config.NoiseSystem.ShootingWithSuppressor or 15.0) or
            (Config.NoiseSystem.Shooting or 45.0)
        noise = math.max(noise, shootingNoise)
    end

    return noise
end

function NoiseSystem:UpdateVisualFeedback(ped)
    if not Config.NoiseSystem.ShowBlipOnMap then return end
    local coords = GetEntityCoords(ped)

    -- Da man den Radius eines bestehenden Blips nicht ändern kann,
    -- müssen wir ihn entfernen und neu setzen.
    -- Damit es nicht flackert, löschen wir ihn nur, wenn sich der Radius signifikant ändert.

    self:RemoveVisualFeedback() -- Blip löschen

    -- Neuen Blip mit aktuellem Radius erstellen
    self.BlipHandle = AddBlipForRadius(coords.x, coords.y, coords.z, self.CurrentNoiseRadius)
    SetBlipColour(self.BlipHandle, Config.NoiseSystem.BlipColor or 1)
    SetBlipAlpha(self.BlipHandle, Config.NoiseSystem.BlipAlpha or 128)
end

function NoiseSystem:RemoveVisualFeedback()
    if self.BlipHandle then
        RemoveBlip(self.BlipHandle)
        self.BlipHandle = nil
    end
end

-- Vision Check für Zombies
function NoiseSystem:CanZombieSeePlayer(zombieEntity, zombieCoords, playerCoords)
    local distance = #(zombieCoords - playerCoords)

    if distance > Config.NoiseSystem.ZombieVisionRange then
        return false
    end

    -- Sichtlinien-Check
    local hasLineOfSight = HasEntityClearLosToEntity(zombieEntity, PlayerPedId(), 17)
    if not hasLineOfSight then
        return false
    end

    -- Winkel-Check (Zombie muss in Richtung Spieler schauen)
    local zombieHeading = GetEntityHeading(zombieEntity)
    local directionToPlayer = GetHeadingFromVector_2d(
        playerCoords.x - zombieCoords.x,
        playerCoords.y - zombieCoords.y
    )

    local angleDiff = math.abs(zombieHeading - directionToPlayer)
    if angleDiff > 180 then
        angleDiff = 360 - angleDiff
    end

    return angleDiff <= (Config.NoiseSystem.VisionAngle / 2)
end

-- Export für andere Scripts
exports('GetCurrentNoiseRadius', function() return NoiseSystem.CurrentNoiseRadius end)

exports('IsPlayerMakingNoise', function(zombieCoords)
    local playerCoords = GetEntityCoords(PlayerPedId())
    return NoiseSystem:IsPlayerMakingNoise(playerCoords, zombieCoords)
end)
