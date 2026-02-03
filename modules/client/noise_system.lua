-- ====================================
-- NOISE & STEALTH SYSTEM
-- ====================================

NoiseSystem = {}
NoiseSystem.CurrentNoiseRadius = 0.0
NoiseSystem.BlipHandle = nil

function NoiseSystem:Init()
    if not Config.NoiseSystem.Enabled then return end
    
    CreateThread(function()
        while true do
            local sleep = 250
            local ped = PlayerPedId()
            
            if IsPedOnFoot(ped) then
                self.CurrentNoiseRadius = self:CalculateNoiseRadius(ped)
                self:UpdateVisualFeedback(ped)
            else
                self.CurrentNoiseRadius = 0.0
                self:RemoveVisualFeedback()
            end
            
            Wait(sleep)
        end
    end)
end

function NoiseSystem:CalculateNoiseRadius(ped)
    local noise = 0.0
    
    -- Bewegungs-Status
    if GetPedStealthMovement(ped) then
        noise = Config.NoiseSystem.Crouching
    elseif IsPedRunning(ped) or IsPedSprinting(ped) then
        noise = Config.NoiseSystem.Running
    elseif IsPedWalking(ped) then
        noise = Config.NoiseSystem.Walking
    end
    
    -- Schuss-Erkennung
    if IsPedShooting(ped) then
        local weapon = GetSelectedPedWeapon(ped)
        local hasSuppressor = HasPedGotWeaponComponent(ped, weapon, GetHashKey('COMPONENT_AT_PI_SUPP')) or
                              HasPedGotWeaponComponent(ped, weapon, GetHashKey('COMPONENT_AT_AR_SUPP')) or
                              HasPedGotWeaponComponent(ped, weapon, GetHashKey('COMPONENT_AT_AR_SUPP_02'))
        
        if hasSuppressor then
            noise = math.max(noise, Config.NoiseSystem.ShootingWithSuppressor)
        else
            noise = math.max(noise, Config.NoiseSystem.Shooting)
        end
    end
    
    -- Fahrzeug-Lärm
    if IsPedInAnyVehicle(ped, false) then
        local vehicle = GetVehiclePedIsIn(ped, false)
        local speed = GetEntitySpeed(vehicle) * 3.6 -- m/s zu km/h
        noise = speed * Config.NoiseSystem.VehicleMultiplier
    end
    
    return noise
end

function NoiseSystem:UpdateVisualFeedback(ped)
    if not Config.NoiseSystem.ShowBlipOnMap then return end
    
    if self.CurrentNoiseRadius > 0 then
        local coords = GetEntityCoords(ped)
        
        -- Entferne alten Blip
        if self.BlipHandle then
            RemoveBlip(self.BlipHandle)
        end
        
        -- Erstelle neuen Radius-Blip
        self.BlipHandle = AddBlipForRadius(coords.x, coords.y, coords.z, self.CurrentNoiseRadius)
        SetBlipColour(self.BlipHandle, Config.NoiseSystem.BlipColor)
        SetBlipAlpha(self.BlipHandle, Config.NoiseSystem.BlipAlpha)
    else
        self:RemoveVisualFeedback()
    end
end

function NoiseSystem:RemoveVisualFeedback()
    if self.BlipHandle then
        RemoveBlip(self.BlipHandle)
        self.BlipHandle = nil
    end
end

function NoiseSystem:GetCurrentRadius()
    return self.CurrentNoiseRadius
end

function NoiseSystem:IsPlayerMakingNoise(playerCoords, zombieCoords)
    local distance = #(playerCoords - zombieCoords)
    return distance <= self.CurrentNoiseRadius
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
exports('GetCurrentNoiseRadius', function()
    return NoiseSystem.CurrentNoiseRadius
end)

exports('IsPlayerMakingNoise', function(zombieCoords)
    local playerCoords = GetEntityCoords(PlayerPedId())
    return NoiseSystem:IsPlayerMakingNoise(playerCoords, zombieCoords)
end)
