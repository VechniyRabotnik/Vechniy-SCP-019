AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "SCP 019"
ENT.Category = "Vechniy SCP"
ENT.Spawnable = true

CreateConVar("scp019_maxheadcrabs", 10, {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Max Headcrabs")
CreateConVar("scp019_autospawn", 0, {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Autospawn (0/1)")
CreateConVar("scp019_autospawn_interval", 20, {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Interval AutoSpawn (сек)")

function ENT:Initialize()
    self:SetModel("/models/SCP_019.mdl")
    self:SetModelScale(15, 0)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:EnableGravity(true)
        phys:SetMass(25)
    end

    self.NextSpawnTime = CurTime() + 10
    self.HeadcrabCount = 0
    self.HeadcrabEntities = {}
    self.TargetPlayer = nil 
end

function ENT:SpawnHeadcrab()
    if self.HeadcrabCount >= GetConVar("scp019_maxheadcrabs"):GetInt() then return end

    local choices = {
        {class = "npc_headcrab", chance = 60, sound = "ambient/levels/canals/headcrab_canister_ambient2.wav"},
        {class = "npc_headcrab_fast", chance = 20, sound = "ambient/levels/canals/headcrab_canister_ambient2.wav"},
        {class = "npc_headcrab_black", chance = 20, sound = "ambient/levels/canals/headcrab_canister_ambient2.wav"}
    }

    local roll = math.random(1, 100)
    local selected = choices[1]
    local cumulative = 0
    for _, data in ipairs(choices) do
        cumulative = cumulative + data.chance
        if roll <= cumulative then
            selected = data
            break
        end
    end


    local spawnPos = self:GetPos() + Vector(math.random(-100, 100), math.random(-100, 100), 20)


    local headcrab = ents.Create(selected.class)
    if not IsValid(headcrab) then return end
    headcrab:SetPos(spawnPos)
    headcrab:Spawn()
    headcrab:SetOwner(self)

    if IsValid(self.TargetPlayer) then
        headcrab:AddEntityRelationship(self.TargetPlayer, D_HT, 99)
    end

    local effectData = EffectData()
    effectData:SetOrigin(spawnPos)
    util.Effect("ElectricSpark", effectData, true, true)

    headcrab:EmitSound(selected.sound)

    table.insert(self.HeadcrabEntities, headcrab)
    self.HeadcrabCount = self.HeadcrabCount + 1

    headcrab:CallOnRemove(function()
        for i, v in ipairs(self.HeadcrabEntities) do
            if v == headcrab then
                table.remove(self.HeadcrabEntities, i)
                break
            end
        end
        self.HeadcrabCount = math.max(0, self.HeadcrabCount - 1)
    end)

end

function ENT:Use(activator, caller)
    if activator:IsPlayer() then
        self.TargetPlayer = activator
        self:SpawnHeadcrab()
    end
end

function ENT:Think()
    if GetConVar("scp019_autospawn"):GetBool() then
        if CurTime() >= self.NextSpawnTime then
            self:SpawnHeadcrab()
            self.NextSpawnTime = CurTime() + GetConVar("scp019_autospawn_interval"):GetInt()
        end
    end
    self:NextThink(CurTime() + 1)
    return true
end

hook.Add("PlayerDeath", "ResetHeadcrabCountOnDeath", function(ply)
    for _, ent in ipairs(ents.FindByClass("vechn_scp019")) do
        if IsValid(ent) then
            ent.HeadcrabCount = 0
            ent.HeadcrabEntities = {}
            ent.TargetPlayer = nil
        end
    end
end)