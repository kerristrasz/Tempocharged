--- @class Tempocharged
local Tempocharged = select(2, ...)

local module = {}

--- @class CountdownMixin
--- @field _fontStrings CountdownFontString[]
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
function CountdownMixin:Initialize()
    self:SetAllPoints()

    local theme = Tempocharged.Options.GetTheme()

    self._fontStrings = {}
    for i, textStyle in ipairs(theme.textStyles) do
        local fontString = self:CreateFontString() --[[@as CountdownFontString]]
        fontString:SetPoint("CENTER")
        fontString:SetJustifyH("CENTER")
        fontString:SetJustifyV("MIDDLE")
        fontString:SetFont(theme.font.file, theme.font.height, theme.font.flags)
        fontString:SetShadowColor(theme.shadow.r, theme.shadow.g, theme.shadow.b, theme.shadow.a)
        fontString:SetShadowOffset(theme.shadow.offsetX, theme.shadow.offsetY)
        fontString:SetTextColor(textStyle.r, textStyle.g, textStyle.b)
        fontString:SetScale(textStyle.scale * self:GetScaleFactorOverride())

        -- TODO: maybe this could be cached?
        fontString._alphaCurve = C_CurveUtil.CreateCurve()
        fontString._alphaCurve:SetType(Enum.LuaCurveType.Step)
        if i > 1 then
            fontString._alphaCurve:AddPoint(theme.textStyles[i - 1].minDuration, 0)
        end
        fontString._alphaCurve:AddPoint(textStyle.minDuration, textStyle.a or 1)
        if i < #theme.textStyles then
            fontString._alphaCurve:AddPoint(theme.textStyles[i + 1].minDuration, 0)
        end

        tinsert(self._fontStrings, fontString)
    end

    self:SetScript("OnUpdate", self.OnUpdate)
end

--- @param self Countdown
function CountdownMixin:OnUpdate()
    local duration = self:GetDuration()
    if duration == nil then return end

    -- TODO: make text formatting a config option
    local text = C_StringUtil.RoundToNearestString(duration:GetRemainingDuration())

    for _, fontString in ipairs(self._fontStrings) do
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
