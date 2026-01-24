---@class Tempocharged
local Tempocharged = select(2, ...)

local module = {}

---@class Countdown : Frame
---@field fontStrings CountdownFontString[]
local CountdownMixin = {}

---@class CountdownFontString : FontString
---@field alphaCurve CurveObject

---@type { [Frame]: Countdown }
local countdowns = {}

function CountdownMixin:Initialize()
    self:SetAllPoints()

    local theme = Tempocharged.Options.GetTheme()

    self.fontStrings = {}
    for i, textStyle in ipairs(theme.textStyles) do
        ---@type CountdownFontString
        local fontString = self:CreateFontString()
        fontString:SetPoint("CENTER")
        fontString:SetJustifyH("CENTER")
        fontString:SetJustifyV("MIDDLE")
        fontString:SetFont(theme.font.file, theme.font.height, theme.font.flags)
        fontString:SetShadowColor(theme.shadow.r, theme.shadow.g, theme.shadow.b, theme.shadow.a)
        fontString:SetShadowOffset(theme.shadow.offsetX, theme.shadow.offsetY)
        fontString:SetTextColor(textStyle.r, textStyle.g, textStyle.b)
        fontString:SetScale(textStyle.scale * self:GetScaleFactorOverride())

        --TODO: maybe this could be cached?
        fontString.alphaCurve = C_CurveUtil.CreateCurve()
        fontString.alphaCurve:SetType(Enum.LuaCurveType.Step)
        if i > 1 then
            fontString.alphaCurve:AddPoint(theme.textStyles[i - 1].minDuration, 0)
        end
        fontString.alphaCurve:AddPoint(textStyle.minDuration, textStyle.a)
        if i < #theme.textStyles then
            fontString.alphaCurve:AddPoint(theme.textStyles[i + 1].minDuration, 0)
        end

        tinsert(self.fontStrings, fontString)
    end

    self:SetScript("OnUpdate", self.OnUpdate)
end

function CountdownMixin:OnUpdate()
    local duration = self:GetDuration()
    if duration == nil then return end

    -- TODO: make text formatting a config option
    local text = C_StringUtil.RoundToNearestString(duration:GetRemainingDuration())

    for _, fontString in self.fontStrings do
        fontString:SetText(text)
        fontString:SetAlpha(duration:EvaluateRemainingDuration(fontString.alphaCurve))
    end 
end

---Gets the duration to display on this countdown. 
---
---@return DurationObject? duration
function CountdownMixin:GetDuration() end

---Gets the scale factor to apply based on the size of the widget.
---
---@return number scale
function CountdownMixin:GetScaleFactorOverride()
    --TODO: this should be replaced with a SecureHandler function, somehow
    return 1
end


---@class TargetAuraFrameCountdown : Countdown
local TargetAuraFrameCountdownMixin = Mixin({}, CountdownMixin)

function TargetAuraFrameCountdownMixin:GetDuration()
    local auraFrame = self:GetParent():GetParent()
    local unit = auraFrame.unit
    local auraInstanceID = auraFrame.auraInstanceID
    if unit ~= nil and auraInstanceID ~= nil then
        return C_UnitAuras.GetAuraDuration(unit, auraInstanceID)
    end
    return nil
end 

---@return number scale
function TargetAuraFrameCountdownMixin:GetScaleFactorOverride()
    -- The buff/debuff icons end up having a text height of 10.5.
    -- TODO: figure out how
    return 10.5 / 18
end

---Gets the `Countdown` for the `parent` if one exists, or creates a new one if not.   
---
---@param parent Frame the countdown's parent
---@param countdownType Countdown the specific subtype of countdown
---@return Countdown countdown
local function GetOrCreateCountdown(parent, countdownType)
    if parent ~= nil and countdowns[parent] ~= nil then 
        return countdowns[parent]
    end
    -- TODO: check some config option
    -- if parent.SetHideCountdownNumbers ~= nil then
    --     parent:SetHideCountdownNumbers(true)
    -- end

    local frame = CreateFrame("Frame", nil, parent)
    frame = Mixin(frame, countdownType)
    frame:Initialize()
    return frame
end

local function OnUpdateTargetAuraFrames(targetFrame, auraList)
    for _, child in ipairs({ targetFrame:GetChildren() }) do
        local aura = child.auraInstanceID and auraList[child.auraInstanceID]
        if aura ~= nil then
            GetOrCreateCountdown(child.Cooldown, TargetAuraFrameCountdownMixin)
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
