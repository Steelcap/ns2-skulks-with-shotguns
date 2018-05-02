
local kBurningViewMaterial = PrecacheAsset("cinematics/vfx_materials/burning_view.material")
local kBurningMaterial = PrecacheAsset("cinematics/vfx_materials/burning.material")
local kBurnBigCinematic = PrecacheAsset("cinematics/marine/flamethrower/burn_big.cinematic")
local kBurnHugeCinematic = PrecacheAsset("cinematics/marine/flamethrower/burn_huge.cinematic")
local kBurnMedCinematic = PrecacheAsset("cinematics/marine/flamethrower/burn_med.cinematic")
local kBurnSmallCinematic = PrecacheAsset("cinematics/marine/flamethrower/burn_small.cinematic")
local kBurn1PCinematic = PrecacheAsset("cinematics/marine/flamethrower/burn_1p.cinematic")

local kFireCinematicTable = { }
kFireCinematicTable["Hive"] = kBurnHugeCinematic
kFireCinematicTable["CommandStation"] = kBurnHugeCinematic
kFireCinematicTable["Clog"] = kBurnSmallCinematic
kFireCinematicTable["Onos"] = kBurnBigCinematic
kFireCinematicTable["MAC"] = kBurnSmallCinematic
kFireCinematicTable["Drifter"] = kBurnSmallCinematic
kFireCinematicTable["Sentry"] = kBurnSmallCinematic
kFireCinematicTable["Egg"] = kBurnSmallCinematic
kFireCinematicTable["Embryo"] = kBurnSmallCinematic

local function GetOnFireCinematic(ent, firstPerson)

    if firstPerson then
        return kBurn1PCinematic
    end
    
    return kFireCinematicTable[ent:GetClassName()] or kBurnMedCinematic
    
end

-- like the regular mixin SharedUpdate, except stripped out all damage.
local function SharedUpdate(self, deltaTime)

    if Client then
        self:UpdateFireMaterial()
        self:_UpdateClientFireEffects()
    end

    if not self:GetIsOnFire() then
        return
    end
    
    if Server then
        
        // See if we put ourselves out
        if Shared.GetTime() - self.timeBurnInit > kFlamethrowerBurnDuration then
            self:SetGameEffectMask(kGameEffect.OnFire, false)
        end
        
    end
    
end


if Client then

    function FireMixin:UpdateFireMaterial()

        if self._renderModel then

            if self.isOnFire and not self.fireMaterial then

                self.fireMaterial = Client.CreateRenderMaterial()
                self.fireMaterial:SetMaterial(kBurningMaterial)
                self._renderModel:AddMaterial(self.fireMaterial)

            elseif not self.isOnFire and self.fireMaterial then

                self._renderModel:RemoveMaterial(self.fireMaterial)
                Client.DestroyRenderMaterial(self.fireMaterial)
                self.fireMaterial = nil

            end

        end

        if self:isa("Player") and self:GetIsLocalPlayer() then

            local viewModelEntity = self:GetViewModelEntity()
            if viewModelEntity then

                local viewModel = self:GetViewModelEntity():GetRenderModel()
                if viewModel and (self.isOnFire and not self.viewFireMaterial) then

                    self.viewFireMaterial = Client.CreateRenderMaterial()
                    self.viewFireMaterial:SetMaterial(kBurningViewMaterial)
                    viewModel:AddMaterial(self.viewFireMaterial)

                elseif viewModel and (not self.isOnFire and self.viewFireMaterial) then

                    viewModel:RemoveMaterial(self.viewFireMaterial)
                    Client.DestroyRenderMaterial(self.viewFireMaterial)
                    self.viewFireMaterial = nil

                end

            end

        end

    end
    
    function FireMixin:_UpdateClientFireEffects()

        -- Play on-fire cinematic every so often if we're on fire
        if self:GetGameEffectMask(kGameEffect.OnFire) and self:GetIsAlive() and self:GetIsVisible() then
        
            -- If we haven't played effect for a bit
            local time = Shared.GetTime()
            
            if not self.timeOfLastFireEffect or (time > (self.timeOfLastFireEffect + .5)) then
            
                local firstPerson = (Client.GetLocalPlayer() == self)
                local cinematicName = GetOnFireCinematic(self, firstPerson)
                
                if firstPerson then
                    local viewModel = self:GetViewModelEntity()
                    if viewModel then
                        Shared.CreateAttachedEffect(self, cinematicName, viewModel, Coords.GetTranslation(Vector(0, 0, 0)), "", true, false)
                    end
                else
                    Shared.CreateEffect(self, cinematicName, self, self:GetAngles():GetCoords())
                end
                
                self.timeOfLastFireEffect = time
                
            end
            
        end
        
    end

end


function FireMixin:OnUpdate(deltaTime)   
    SharedUpdate(self, deltaTime)
end

function FireMixin:OnProcessMove(input)   
    SharedUpdate(self, input.time)
end
