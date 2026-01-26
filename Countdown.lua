--- @class Tempocharged
local Tempocharged = select(2, ...)

local module = {}

--- @class CountdownMixin
--- @field _cooldownStrings CountdownFontString[]
local CountdownMixin = {}

--- @class Countdown : Frame, CountdownMixin

--- @class CountdownFontString : FontString
--- @field _alphaCurve CurveObject

--- @type { [Frame]: Countdown }
local countdowns = {}

--- Gets the `Countdown` for the `parent` if one exists, or creates a new one if not.
---
--- @param parent Frame? the countdown's parent
--- @return Countdown countdown
function CountdownMixin:GetOrCreate(parent)
    if parent ~= nil and countdowns[parent] ~= nil then
        return countdowns[parent]
    end

    -- TODO: check some config option
    -- if parent.SetHideCountdownNumbers ~= nil then
    --     parent:SetHideCountdownNumbers(true)
    -- end

    local frame = Mixin(CreateFrame("Frame", nil, parent), self) --[[@as Countdown]]
    frame:Initialize()
    if parent ~= nil then
        countdowns[parent] = frame
    end
    return frame
end

--- @param self Countdown
--- @param theme Tempocharged.Options.Theme
--- @param style Tempocharged.Options.Style
--- @return CountdownFontString fontString
local function CreateCountdownFontString(self, theme, style)
    local fs = self:CreateFontString() --[[@as CountdownFontString]]
    fs:SetPoint(theme.point.anchor, theme.point.offsetX, theme.point.offsetY)

    fs:SetFont(theme.font.file, theme.font.height, theme.font.flags)
    fs:SetShadowColor(theme.shadow.r, theme.shadow.g, theme.shadow.b, theme.shadow.a)
    fs:SetShadowOffset(theme.shadow.offsetX, theme.shadow.offsetY)
    fs:SetTextColor(style.r, style.g, style.b)
    fs:SetScale(style.scale * self:GetScaleFactorOverride())

    fs._alphaCurve = C_CurveUtil.CreateCurve()
    fs._alphaCurve:SetType(Enum.LuaCurveType.Step)

    return fs
end

--- @param self Countdown
function CountdownMixin:Initialize()
    self:SetAllPoints()

    local theme = Tempocharged.Options.GetTheme()

    self._cooldownStrings = {}
    for i, textStyle in ipairs(theme.durationStyles) do
        local fontString = CreateCountdownFontString(self, theme, textStyle)
        if i > 1 then
            fontString._alphaCurve:AddPoint(theme.durationStyles[i - 1].minDuration, 0)
        else
            fontString._alphaCurve:AddPoint(-100, 0)
        end
        fontString._alphaCurve:AddPoint(textStyle.minDuration, textStyle.a or 1)
        if i < #theme.durationStyles then
            fontString._alphaCurve:AddPoint(theme.durationStyles[i + 1].minDuration, 0)
        end

        tinsert(self._cooldownStrings, fontString)
    end

    self:SetScript("OnUpdate", self.OnUpdate)
end

--- @param self Countdown
function CountdownMixin:OnUpdate()
    local duration = self:GetDuration()
    if duration ~= nil --[[and not duration:IsZero()]] then
        local text = Tempocharged.Options.FormatDuration(duration:GetRemainingDuration())

        for _, fontString in ipairs(self._cooldownStrings) do
            fontString:Show()
            fontString:SetText(text)
            fontString:SetAlpha(duration:EvaluateRemainingDuration(fontString._alphaCurve))
        end
    else
        for _, fontString in ipairs(self._cooldownStrings) do
            fontString:Hide()
        end
    end
end

--- Gets the duration to display on this countdown.
---
--- @param self Countdown
--- @return DurationObject? cooldownDuration
function CountdownMixin:GetDuration() end

--- Gets the scale factor to apply based on the size of the widget.
---
--- @param self Countdown
--- @return number scale
function CountdownMixin:GetScaleFactorOverride()
    -- TODO: this should be replaced with a SecureHandler function, somehow
    return 1
end

--- @class TargetAuraFrameCountdownMixin : CountdownMixin
local TargetAuraFrameCountdownMixin = Mixin({}, CountdownMixin)

--- @class TargetAuraFrameCountdown : Frame, Countdown, TargetAuraFrameCountdownMixin

--- @param self TargetAuraFrameCountdown
--- @return DurationObject? duration
function TargetAuraFrameCountdownMixin:GetDuration()
    local auraFrame = self:GetParent():GetParent() --[[@as Frame]]
    local unit = auraFrame["unit"]
    local auraInstanceID = auraFrame["auraInstanceID"]
    if unit ~= nil and auraInstanceID ~= nil then
        return C_UnitAuras.GetAuraDuration(unit, auraInstanceID)
    end
    return nil
end

--- @param self TargetAuraFrameCountdown
--- @return number scale
function TargetAuraFrameCountdownMixin:GetScaleFactorOverride()
    -- Size = min(self:GetSize()) / 36
    return 21 / 36
end

--- @class TargetOfTargetDebuffCountdownMixin : CountdownMixin
--- @field _duration DurationObject?
--- @field GetOrCreate fun(self: self, parent: Frame): TargetOfTargetDebuffCountdown
local TargetOfTargetDebuffCountdownMixin = Mixin({}, CountdownMixin)

--- @class TargetOfTargetDebuffCountdown : Frame, Countdown, TargetOfTargetDebuffCountdownMixin

--- @param self TargetOfTargetDebuffCountdown
--- @return DurationObject? duration
function TargetOfTargetDebuffCountdownMixin:GetDuration()
    return self._duration
end

function TargetOfTargetDebuffCountdownMixin:GetScaleFactorOverride()
    -- size: 12 x 12
    return 12 / 36
end

--- @class ActionButtonCountdownMixin : CountdownMixin
--- @field _chargingString CountdownFontString
--- @field _lossOfControlString CountdownFontString
local ActionButtonCountdownMixin = Mixin({}, CountdownMixin)

--- @class ActionButtonCountdown : ActionButtonCountdownMixin, Frame, Countdown

--- @param self ActionButtonCountdown
function ActionButtonCountdownMixin:Initialize()
    CountdownMixin.Initialize(self)
    -- TODO: these don't need curves
    local theme = Tempocharged.Options.GetTheme()
    self._chargingString = CreateCountdownFontString(self, theme, theme.rechargingStyle)
    self._lossOfControlString = CreateCountdownFontString(self, theme, theme.lossOfControlStyle)
end

-- TODO: put this somewhere
local shortDurationCurve = C_CurveUtil.CreateCurve()
shortDurationCurve:SetType(Enum.LuaCurveType.Step)
shortDurationCurve:AddPoint(-1, 0)
shortDurationCurve:AddPoint(0.5, 1)

--- @param self ActionButtonCountdown
function ActionButtonCountdownMixin:OnUpdate()
    -- CountdownMixin.OnUpdate(self)
    local cdDuration, chargeDuration, locDuration, cdEnabled = self:GetDuration()

    do
        local text = Tempocharged.Options.FormatDuration(locDuration:GetRemainingDuration())
        self._lossOfControlString:SetText(text)
        self._lossOfControlString:SetAlpha(locDuration:EvaluateRemainingDuration(shortDurationCurve))
    end

    if cdDuration ~= nil then
        -- TODO: make text formatting a config option
        local text = Tempocharged.Options.FormatDuration(cdDuration:GetRemainingDuration())

        for _, fontString in ipairs(self._cooldownStrings) do
            fontString:SetText(text)

            local alpha = C_CurveUtil.EvaluateColorValueFromBoolean(
                locDuration:IsZero(),
                C_CurveUtil.EvaluateColorValueFromBoolean(
                    cdEnabled,
                    cdDuration:EvaluateRemainingDuration(fontString._alphaCurve),
                    0),
                0)
            fontString:SetAlpha(alpha)
        end
    else
        for _, fontString in ipairs(self._cooldownStrings) do
            fontString:SetAlpha(0)
        end
    end

    do
        local text = Tempocharged.Options.FormatDuration(chargeDuration:GetRemainingDuration())
        self._chargingString:SetText(text)

        local alpha = C_CurveUtil.EvaluateColorValueFromBoolean(
            locDuration:IsZero(),
            C_CurveUtil.EvaluateColorValueFromBoolean(
                cdDuration == nil or cdDuration:IsZero(),
                chargeDuration:EvaluateRemainingDuration(shortDurationCurve),
                0),
            0)

        self._chargingString:SetAlpha(alpha)
        -- self._chargingString:SetAlpha(chargeDuration:EvaluateRemainingDuration(shortDurationCurve))
    end
end

--- @param self ActionButtonCountdown
--- @return DurationObject? cooldownDuration
--- @return DurationObject chargeDuration
--- @return DurationObject lossOfControlDuration
function ActionButtonCountdownMixin:GetDuration()
    local button = self:GetParent() --[[@as SecureActionButtonTemplate]]
    --- @diagnostic disable-next-line: undefined-field
    local action = button:CalculateAction()
    local cdInfo = C_ActionBar.GetActionCooldown(action)

    local cdDuration = (cdInfo.isOnGCD ~= true) and
        C_ActionBar.GetActionCooldownDuration(action) or nil

    local chargeDuration = C_ActionBar.GetActionChargeDuration(action)
    local locDuration = C_ActionBar.GetActionLossOfControlCooldownDuration(action)

    return cdDuration, chargeDuration, locDuration, cdInfo.isEnabled
end

--- @param self ActionButtonCountdown
--- @return number scaleFactor
function ActionButtonCountdownMixin:GetScaleFactorOverride()
    return 45 / 36
end

local function OnUpdateTargetAuraFrames(targetFrame, auraList)
    for _, child in ipairs({ targetFrame:GetChildren() }) do
        local aura = child.auraInstanceID and auraList[child.auraInstanceID]
        if aura ~= nil then
            TargetAuraFrameCountdownMixin:GetOrCreate(child.Cooldown)
        end
    end
end

local function OnUpdateTargetOfTargetFrame(totFrame)
    if not totFrame:IsShown() then return end

    local unit = totFrame["unit"]
    local filter = ((C_CVar.GetCVar("showDispelDebuffs") and UnitCanAssist("player", unit))
        and "HARMFUL|RAID"
        or "HARMFUL")

    local i = 0
    AuraUtil.ForEachAura(unit, filter, MAX_PARTY_DEBUFFS, function(auraData)
        i = i + 1
        local parent = _G["TargetFrameToTDebuff" .. i .. "Cooldown"]
        if parent ~= nil then
            local frame = TargetOfTargetDebuffCountdownMixin:GetOrCreate(parent)
            frame._duration =
                C_UnitAuras.GetAuraDuration(unit, auraData.auraInstanceID)
        end
    end, true)
end

local function HookTargetFrame()
    hooksecurefunc(TargetFrame, "UpdateAuraFrames", OnUpdateTargetAuraFrames)
    hooksecurefunc(TargetFrameToT, "Update", OnUpdateTargetOfTargetFrame)
end

local function HookActionBars()
    for i = 1, 12 do
        ActionButtonCountdownMixin:GetOrCreate(_G["ActionButton" .. i]) -- Bar 1
        ActionButtonCountdownMixin:GetOrCreate(_G["MultiBarBottomLeftButton" .. i]) -- Bar 2
        ActionButtonCountdownMixin:GetOrCreate(_G["MultiBarBottomRightButton" .. i]) -- Bar 3
        ActionButtonCountdownMixin:GetOrCreate(_G["MultiBarRightButton" .. i]) -- Bar 4
        ActionButtonCountdownMixin:GetOrCreate(_G["MultiBarLeftButton" .. i]) -- Bar 5
        ActionButtonCountdownMixin:GetOrCreate(_G["MultiBar5Button" .. i]) -- Bar 6
        ActionButtonCountdownMixin:GetOrCreate(_G["MultiBar6Button" .. i]) -- Bar 7
        ActionButtonCountdownMixin:GetOrCreate(_G["MultiBar7Button" .. i]) -- Bar 8
    end
end

function module.Initialize()
    HookTargetFrame()
    HookActionBars()
end

Tempocharged.Countdown = module
