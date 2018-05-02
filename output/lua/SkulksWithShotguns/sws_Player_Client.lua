function PlayerUI_GetNumClingedBabblers()
    return 0
end

function PlayerUI_GetCanEarnResources()
    return false
end


--[[
-- Called on the Client only, after OnInitialized(), for a ScriptActor that is controlled by the local player.
-- Ie, the local player is controlling this Marine and wants to intialize local UI, flash, etc.
 ]]
function Player:OnInitLocalClient()

    self.minimapVisible = false

    self.alertBlips = { }
    self.alertMessages = { }

    DisableScreenEffects(self)

    -- Re-enable skybox rendering after commanding
    SetSkyboxDrawState(true)

    -- Show props normally
    SetCommanderPropState(false)

    -- Assume not in overhead mode.
    SetLocalPlayerIsOverhead(false)

    -- Turn on sound occlusion for non-commanders
    Client.SetSoundGeometryEnabled(true)

    self.traceReticle = false

    self.damageIndicators = { }

    -- Set commander geometry visible
    Client.SetGroupIsVisible(kCommanderInvisibleGroupName, true)
    if gSeasonalCommanderInvisibleGroupName then
        Client.SetGroupIsVisible(gSeasonalCommanderInvisibleGroupName, true)
    end

    --Client.SetEnableFog(true)
    self.crossHairText = nil
    self.crossHairTextColor = kFriendlyColor

    -- reset mouse sens in case it hase been forgotten somewhere else
    Client.SetMouseSensitivityScalar(1)

end
function PlayerUI_GetDamageIndicators()

    local drawIndicators = {}
	local player = Client.GetLocalPlayer()
	
	local damageIndicators = player.damageIndicators or {}
	player.damageIndicators = damageIndicators

    if player then

        for index, indicatorTriple in ipairs(player.damageIndicators) do

            local alpha = Clamp(1 - ((Shared.GetTime() - indicatorTriple[3])/Player.kDamageIndicatorDrawTime), 0, 1)
            table.insert(drawIndicators, alpha)

            local worldX = indicatorTriple[1]
            local worldZ = indicatorTriple[2]

            local normDirToDamage = GetNormalizedVector(Vector(player:GetOrigin().x, 0, player:GetOrigin().z) - Vector(worldX, 0, worldZ))
            local worldToView = player:GetViewAngles():GetCoords():GetInverse()

            local damageDirInView = worldToView:TransformVector(normDirToDamage)

            local directionRadians = math.atan2(damageDirInView.x, damageDirInView.z)
            if directionRadians < 0 then
                directionRadians = directionRadians + 2 * math.pi
            end

            table.insert(drawIndicators, directionRadians)

        end

    end

    return drawIndicators

end


function Player:UpdateDamageIndicators()

    local indicesToRemove = {}
	local damageIndicators = self.damageIndicators or {}
	self.damageIndicators = damageIndicators
    -- Expire old damage indicators
    for index, indicatorTriple in ipairs(self.damageIndicators) do

        if Shared.GetTime() > (indicatorTriple[3] + Player.kDamageIndicatorDrawTime) then

            table.insert(indicesToRemove, index)

        end

    end

    for i, index in ipairs(indicesToRemove) do
        table.remove(self.damageIndicators, index)
    end

    -- update damage given
    if self.giveDamageTimeClientCheck ~= self.giveDamageTime then

        self.giveDamageTimeClientCheck = self.giveDamageTime
        self.giveDamageTimeClient = Shared.GetTime()

        self.showDamage = self:GetShowDamageIndicator()
        if self.showDamage then
            self:OnGiveDamage()
        end

    end

end