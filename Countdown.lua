--- @class Tempocharged
local Tempocharged = select(2, ...)

local module = {}

--- @class CountdownMixin
--- @field _durationStrings CountdownFontString[]
--- @field _rechargingString CountdownFontString
--- @field _lossOfControlString CountdownFontString
local CountdownMixin = {}

--- @class Countdown : Frame, CountdownMixin

--- @class CountdownFontString : FontString
--- @field _alphaCurve CurveObject

--- @type { [Frame]: Countdown }
local countdowns = {}

--- Gets the `Countdown` for the `parent` if one exists, or creates a new one if not.
---
--- @param parent Frame the countdown's parent
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

    self._durationStrings = {}
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

        tinsert(self._durationStrings, fontString)
    end

    -- TODO: these don't need curves
    self._rechargingString = CreateCountdownFontString(self, theme, theme.rechargingStyle)
    self._lossOfControlString = CreateCountdownFontString(self, theme, theme.lossOfControlStyle)

    self:SetScript("OnUpdate", self.OnUpdate)
end

--- @param self Countdown
function CountdownMixin:OnUpdate()
    local duration = self:GetDuration()
    if duration == nil then return end

    -- TODO: make text formatting a config option
    local text = C_StringUtil.RoundToNearestString(duration:GetRemainingDuration())

    for _, fontString in ipairs(self._durationStrings) do
        fontString:SetText(text)
        fontString:SetAlpha(duration:EvaluateRemainingDuration(fontString._alphaCurve))
    end
end

--- Gets the duration to display on this countdown.
---
--- @param self Countdown
--- @return DurationObject? duration
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

--- @class TargetAuraFrameCountdown : Frame, TargetAuraFrameCountdownMixin

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
    -- The buff/debuff icons end up having a text height of 10.5.
    -- TODO: figure out how
    return 10.5 / 18
end

local function OnUpdateTargetAuraFrames(targetFrame, auraList)
    for _, child in ipairs({ targetFrame:GetChildren() }) do
        local aura = child.auraInstanceID and auraList[child.auraInstanceID]
        if aura ~= nil then
            TargetAuraFrameCountdownMixin:GetOrCreate(child.Cooldown)
        end
    end
end

local function HookTargetFrame()
    hooksecurefunc(TargetFrame, "UpdateAuraFrames", OnUpdateTargetAuraFrames)
end

function module.Initialize()
    HookTargetFrame()
end

Tempocharged.Countdown = module
