---@class Tempocharged
local Tempocharged = select(2, ...)

---@class Tempocharged.M_Displays
local module = {}

---@class Tempocharged.Display : Frame
---@field text FontString
local DisplayMixin = {}
DisplayMixin.__index = DisplayMixin

---@type ColorCurveObject
local colorCurve
---@type CurveObject
local scaleCurve

function module.Initialize()
    local MILLISECOND = 1
    local SECOND = 1000 * MILLISECOND
    local MINUTE = 60 * SECOND
    local HOUR = 60 * MINUTE
    local DAY = 24 * HOUR
   
    local SOON_THRESHOLD = 0
    local SECONDS_THRESHOLD = 5.5 * SECOND
    local MINUTES_THRESHOLD = MINUTE - 0.5 * SECOND
    local HOURS_THRESHOLD = HOUR - 0.5 * MINUTE
    local DAYS_THRESHOLD = DAY - 0.5 * HOUR

    local POINTS = {
        {
            time = SOON_THRESHOLD,
            color = CreateColor(1, 0.1, 0.1),
            scale = 1.5,
        },
        {
            time = SECONDS_THRESHOLD,
            color = CreateColor(1, 1, 0.1),
            scale = 1,
        },
        { 
            time = MINUTES_THRESHOLD,
            color = CreateColor(1, 1, 1),
            scale = 1,
        },
        {
            time = HOURS_THRESHOLD,
            color = CreateColor(0.7, 0.7, 0.7),
            scale = 0.75,
        },
        {
            time = DAYS_THRESHOLD,
            color = CreateColor(0.7, 0.7, 0.7),
            scale = 0.75,
        },
    }

    colorCurve = C_CurveUtil.CreateColorCurve()
    colorCurve:SetType(Enum.LuaCurveType.Step)

    scaleCurve = C_CurveUtil.CreateCurve()
    scaleCurve:SetType(Enum.LuaCurveType.Step)
    
    for _, point in ipairs(POINTS) do
        colorCurve:AddPoint(point.time, point.color)
        scaleCurve:AddPoint(point.time, point.scale)
    end
end

---@param parent? Cooldown
---@return Tempocharged.Display
function module.Create(parent)
    return DisplayMixin.Initialize(CreateFrame("Frame", nil, parent))
end

---@param self Frame
---@return Tempocharged.Display self
function DisplayMixin.Initialize(self)
    -- TODO: figure this out. is this the best way to do this??
    self = Mixin(self, DisplayMixin)

    ---@cast self Tempocharged.Display
    
    self:Hide()
    self:SetSize(36, 36) -- TODO: figure out size

    self.text = self:CreateFontString(nil, "OVERLAY")
    self.text:SetFont(STANDARD_TEXT_FONT, 18, "OUTLINE")
    self.text:SetAllPoints()

    return self
end

function DisplayMixin:UpdateText()
    
    local duration = cooldown:GetCooldownDuration()
end

Tempocharged.M_Displays = module
