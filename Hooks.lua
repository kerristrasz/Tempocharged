--- @class Tempocharged
local Tempocharged = select(2, ...)

local Cooldown, SpellCooldownType = Tempocharged.Cooldown, Tempocharged.SpellCooldownType

local GetActionInfo = GetActionInfo
local GetCooldownAuraBySpellID = C_UnitAuras.GetCooldownAuraBySpellID
local GetItemActionOnEquipSpellID = C_ActionBar.GetItemActionOnEquipSpellID
local GetPlayerAuraBySpellID = C_UnitAuras.GetPlayerAuraBySpellID

local Hooks = {}
Tempocharged.Hooks = Hooks

local activeTargetFrameAuras = {}

--- @param self TargetFrameTemplate
local function TargetFrame_OnUpdateAuraFrames(self, auraList)
    -- Note: `UpdateAuraFrames` is called twice (for buffs/debuffs) when we really
    -- only need to run our logic once. However, `UpdateAuras` (which calls this)
    -- might early return if no update is needed, so it's better to hook the former.

    -- skip every other call
    if auraList == self.activeBuffs then return end

    table.wipe(activeTargetFrameAuras)

    for _, child in ipairs({ self:GetChildren() }) do
        if child.Cooldown and child.auraInstanceID then
            activeTargetFrameAuras[child] = true
            -- TODO: cooldown should set this when I tell it it's tracking an aura
            child.Cooldown:SetUseAuraDisplayTime(true)
            Cooldown.TryInit(child.Cooldown)
            Cooldown.ApplyCooldownFromAura(child.Cooldown, self.unit, child.auraInstanceID)
        end
    end
end

local totFrameDebuffCooldowns = {}

local function TargetFrameToT_OnUpdate(totFrame)
    if not totFrame:IsShown() then return end

    local unit = totFrame.unit
    local filter = (
        (C_CVar.GetCVar("showDispelDebuffs") and UnitCanAssist("player", unit))
        and "HARMFUL|RAID" or "HARMFUL"
    )

    local i = 0
    AuraUtil.ForEachAura(unit, filter, MAX_PARTY_DEBUFFS, function(auraData)
        i = i + 1
        local cdFrame = totFrameDebuffCooldowns[i]
        if cdFrame then
            Cooldown.ApplyCooldownFromAura(cdFrame, unit, auraData.auraInstanceID)
        end
    end, true)
end

function Hooks.HookTargetFrame()
    hooksecurefunc(TargetFrame, "UpdateAuraFrames", TargetFrame_OnUpdateAuraFrames)

    for i = 1, MAX_PARTY_DEBUFFS do
        totFrameDebuffCooldowns[i] = _G["TargetFrameToTDebuff" .. i .. "Cooldown"]
        Cooldown.TryInit(totFrameDebuffCooldowns[i])
    end
    hooksecurefunc(TargetFrameToT, "Update", TargetFrameToT_OnUpdate)
end

function Hooks.HookGroupFrames()
    error("Unimplemented!")
end

function Hooks.HookNamePlates()
    hooksecurefunc(NamePlateAuraItemMixin, "OnLoad", function(self)
        --- @cast self NameplateAuraItemTemplate
        Cooldown.TryInit(self.Cooldown)
        self:HookScript("OnShow", function()
            Cooldown.ApplyCooldownFromAura(self.Cooldown, self.unitToken, self.auraInstanceID)
        end)
    end)
end

--- @type { [ActionBarButtonTemplate|SecureActionButtonTemplate]: true }
local hookedActionButtons = {}

--- @param self ActionBarButtonTemplate|SecureActionButtonTemplate
local function ActionButton_OnUpdateCooldown(self)
    if not hookedActionButtons[self] then return end

    local slotID
    if self.CalculateAction then
        slotID = self:CalculateAction()
    else
        slotID = self.action
    end

    -- Here we basically copy Blizzard's logic in ActionButton_UpdateCooldown
    -- to get the durations, just with the addon API. Performant!

    local actionType, actionID = nil, nil
    if slotID then
        actionType, actionID = GetActionInfo(slotID)
    end

    local onEquipPassiveSpellID = nil
    if actionID then
        onEquipPassiveSpellID = GetItemActionOnEquipSpellID(actionID)
    end

    local passiveCooldownSpellID = nil
    if onEquipPassiveSpellID then
        passiveCooldownSpellID = GetCooldownAuraBySpellID(onEquipPassiveSpellID)
    elseif actionType == "spell" and actionID then
        passiveCooldownSpellID = GetCooldownAuraBySpellID(actionID)
    elseif self.spellID then
        passiveCooldownSpellID = GetCooldownAuraBySpellID(self.spellID)
    end

    local auraData = nil
    if passiveCooldownSpellID --[[ and passiveCooldownSpellID ~= 0 ]] then
        auraData = GetPlayerAuraBySpellID(passiveCooldownSpellID)
    end

    if auraData then
        local unit, instanceID = "player", auraData.auraInstanceID
        Cooldown.ApplyCooldownFromAura(self.cooldown, unit, instanceID)
        Cooldown.ApplyCooldownFromAura(self.chargeCooldown, unit, instanceID)
        Cooldown.ApplyCooldownFromAura(self.lossOfControlCooldown, unit, instanceID)
    elseif self.spellID then
        Cooldown.ApplyCooldownFromSpell(self.cooldown, self.spellID)
        Cooldown.ApplyCooldownFromSpell(self.chargeCooldown, self.spellID)
        Cooldown.ApplyCooldownFromSpell(self.lossOfControlCooldown, self.spellID)
    else
        Cooldown.ApplyCooldownFromActionSlot(self.cooldown, slotID)
        Cooldown.ApplyCooldownFromActionSlot(self.chargeCooldown, slotID)
        Cooldown.ApplyCooldownFromActionSlot(self.lossOfControlCooldown, slotID)
    end
end

function Hooks.HookActionBarButtons()
    local actionButtonPrefixes = {
        "ActionButton",
        "MultiBarBottomLeftButton",
        "MultiBarBottomRightButton",
        "MultiBarRightButton",
        "MultiBarLeftButton",
        "MultiBar5Button",
        "MultiBar6Button",
        "MultiBar7Button",
    }
    for _, prefix in ipairs(actionButtonPrefixes) do
        for i = 1, 12 do
            local button = _G[prefix .. i]
            Cooldown.TryInit(button.cooldown, SpellCooldownType.Cooldown)
            Cooldown.TryInit(button.chargeCooldown, SpellCooldownType.Charge)
            Cooldown.TryInit(button.lossOfControlCooldown, SpellCooldownType.LossOfControl)
            hookedActionButtons[button] = true
        end
    end
    hooksecurefunc("ActionButton_UpdateCooldown", ActionButton_OnUpdateCooldown)
end

function Hooks.HookSpellBookActionButtons()
    error("Unimplemented!")
end

function Hooks.HookCooldownManager()
    error("Unimplemented!")
end

function Hooks.HookAll()
    Hooks.HookTargetFrame()
    -- Hooks.HookGroupFrames()
    Hooks.HookNamePlates()
    Hooks.HookActionBarButtons()
    -- Hooks.HookSpellBookActionButtons()
    -- Hooks.HookCooldownManager()
end
