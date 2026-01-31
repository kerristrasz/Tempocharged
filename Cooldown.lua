--- @class Tempocharged
local Tempocharged = select(2, ...)

local SpellCooldownType, Options = Tempocharged.SpellCooldownType, Tempocharged.Options

local GetActionChargeDuration = C_ActionBar.GetActionChargeDuration
local GetActionCooldownDuration = C_ActionBar.GetActionCooldownDuration
local GetActionLoCDuration = C_ActionBar.GetActionLossOfControlCooldownDuration
local GetAuraDuration = C_UnitAuras.GetAuraDuration
local GetSpellChargeDuration = C_Spell.GetSpellChargeDuration
local GetSpellCooldownDuration = C_Spell.GetSpellCooldownDuration
local GetSpellLoCDuration = C_Spell.GetSpellLossOfControlCooldownDuration

--- @class Tempocharged.Cooldown
local Cooldown = {}
Tempocharged.Cooldown = Cooldown

--- @class Tempocharged.CooldownExt
--- @field spellType? Tempocharged.SpellCooldownType
--- @field countdowns FontString[] all `FontStrings` used by this `Cooldown`, including the default one (i=1)
--- @field colorCurves ColorCurveObject[] color curves to apply normally
--- @field auraColorCurves ColorCurveObject[] color curves to apply to aura display times
--- @field duration DurationObject? the computed duration

--- @type { [Cooldown]: Tempocharged.CooldownExt }
local hookedCooldowns = setmetatable({}, { __mode = "k" --[[ weak key refs ]] })

local function CountdownFontString_OnShow(cd)
    local ext = hookedCooldowns[cd:GetParent()]
    if not ext then return end
    for i = 2, #ext.countdowns do
        ext.countdowns[i]:Show()
    end
end

local function CountdownFontString_OnHide(cd)
    local ext = hookedCooldowns[cd:GetParent()]
    if not ext then return end
    for i = 2, #ext.countdowns do
        ext.countdowns[i]:Hide()
    end
end

--- @param self Cooldown
local function Cooldown_OnUpdate(self)
    local ext = hookedCooldowns[self]
    if not ext then return end

    local useAuraDisplayTime = self:GetUseAuraDisplayTime()
    if issecretvalue(useAuraDisplayTime) then
        useAuraDisplayTime = ext.spellType == nil
    end
    local curves = useAuraDisplayTime and ext.auraColorCurves or ext.colorCurves
    local duration, cds = ext.duration, ext.countdowns

    if duration then
        local text = cds[1]:GetText()
        for i = 1, #cds do
            local color = duration:EvaluateRemainingDuration(curves[i])
            cds[i]:SetTextColor(color:GetRGBA())
            if i > 1 then
                cds[i]:SetText(text)
            end
        end
    else
        for i = 1, #cds do
            cds[i]:SetAlpha(0)
        end
    end
end


--- Tries to set up a `Cooldown` widget. Hooks are only applied if this
--- widget was not previously hooked.
---
--- @param self? Cooldown
--- @param spellType? Tempocharged.SpellCooldownType the kind of spell to track
--- @param style? Tempocharged.CooldownStyle the style to apply
function Cooldown.TryInit(self, spellType, style)
    -- Prevent hooking the same Cooldown multiple times
    if not self then
        return
    end

    if hookedCooldowns[self] then
        hookedCooldowns[self].spellType = spellType
    else
        local ext = {
            spellType = spellType,
            countdowns = { self:GetCountdownFontString() },
            colorCurves = {},
            auraColorCurves = {},
        }
        hookedCooldowns[self] = ext

        ext.countdowns[1]:HookScript("OnShow", CountdownFontString_OnShow)
        ext.countdowns[1]:HookScript("OnHide", CountdownFontString_OnHide)
        self:HookScript("OnUpdate", Cooldown_OnUpdate)
    end

    Cooldown.SetStyle(self, style)
end

--- Applies the style to this `Cooldown` frame, creating and removing
--- countdowns as needed. If `style` is `nil`, then the default style
--- for this type of cooldown is used.
---
--- @param self Cooldown
--- @param style? Tempocharged.CooldownStyle
function Cooldown.SetStyle(self, style)
    local ext = hookedCooldowns[self]
    if not ext then return end

    if not style then
        style = Options.GetCooldownStyle(ext.spellType)
    end

    -- Remove excess countdowns
    for i = #style.countdowns + 1, #ext.countdowns do
        ext.countdowns[i]:Hide()
        ext.countdowns[i] = nil
        ext.colorCurves[i] = nil
        ext.auraColorCurves[i] = nil
    end

    for i, s in ipairs(style.countdowns) do
        local fs = ext.countdowns[i]
        if not fs then
            if i == 1 then
                fs = self:GetCountdownFontString()
            else
                fs = self:CreateFontString()
            end
            ext.countdowns[i] = fs
        end

        -- TODO: adjust size based on the size of the Cooldown
        fs:SetFont(s.fontFile, s.fontHeight * s.scale, s.fontFlags)
        fs:SetPoint(s.anchor, s.offsetX, s.offsetY)
        fs:SetShadowColor(s.shadowColor:GetRGBA())
        fs:SetShadowOffset(s.shadowOffsetX, s.shadowOffsetY)
        fs:SetAlpha(0)

        ext.colorCurves[i] = s.colorCurve
        ext.auraColorCurves[i] = s.auraColorCurve
    end

    -- TODO: make this a config option?
    self:SetHideCountdownNumbers(false)
    self:SetCountdownAbbrevThreshold(60)
end

--- Updates the tracked aura. Set to `nil` to untrack.
---
--- @param self Cooldown
--- @param unit UnitToken?
--- @param auraInstanceID number?
function Cooldown.ApplyCooldownFromAura(self, unit, auraInstanceID)
    local ext = hookedCooldowns[self]
    if not ext then return end

    if unit and auraInstanceID then
        ext.duration = GetAuraDuration(unit, auraInstanceID)
    else
        ext.duration = nil
    end
end

--- Updates the tracked spell. Set to `nil` to untrack.
---
--- @param self Cooldown
--- @param spellID SpellIdentifier?
function Cooldown.ApplyCooldownFromSpell(self, spellID)
    local ext = hookedCooldowns[self]
    if not ext then return end

    local newDuration = nil
    if spellID then
        if ext.spellType == SpellCooldownType.Charge then
            newDuration = GetSpellChargeDuration(spellID)
        elseif ext.spellType == SpellCooldownType.LossOfControl then
            newDuration = GetSpellLoCDuration(spellID)
        else
            newDuration = GetSpellCooldownDuration(spellID)
        end
    end
    ext.duration = newDuration
end

--- Updates the tracked spell using an action bar slot. Set to `nil` to untrack.
---
--- @param self Cooldown
--- @param slotID number?
function Cooldown.ApplyCooldownFromActionSlot(self, slotID)
    local ext = hookedCooldowns[self]
    if not ext then return end

    local newDuration = nil
    if slotID then
        if ext.spellType == SpellCooldownType.Charge then
            newDuration = GetActionChargeDuration(slotID)
        elseif ext.spellType == SpellCooldownType.LossOfControl then
            newDuration = GetActionLoCDuration(slotID)
        else
            newDuration = GetActionCooldownDuration(slotID)
        end
    end
    ext.duration = newDuration
end
