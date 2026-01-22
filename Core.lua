---@diagnostic disable: unused-local

---@class Addon
local Addon = select(2, ...)

local events = {}
local eventFrame = CreateFrame("Frame")
function Addon:RegisterEvent(event, handler)
    if type(handler) == "string" then 
        handler = self[handler]
    end
    eventFrame:RegisterEvent("PLAYER_LOGIN")
    events[event] = function(...) handler(self, ...) end
end

function Addon:OnInitialize()
    print("OnInitialize")
    eventFrame:SetScript("OnUpdate", function() Addon:OnUpdate() end)
    eventFrame:SetScript("OnEvent", function(frame, event, ...)
        if events[event] then
            events[event](...)
        end
    end)

    Addon:RegisterEvent("PLAYER_LOGIN", "OnEnable")
end

function Addon:OnEnable()
    print("OnEnable")
    self.auraFrame = CreateFrame("Frame", UIParent, nil, "BackdropTemplate")

    self.auraFrame:SetPoint("TOPLEFT", nil, "TOPLEFT", 25, -25)
    self.auraFrame:SetSize(200, 100)
    self.auraFrame:SetBackdrop(BACKDROP_TUTORIAL_16_16)

    self.colorCurve = C_CurveUtil.CreateColorCurve()
    self.colorCurve:SetType(Enum.LuaCurveType.Step)
    self.colorCurve:AddPoint(0, CreateColor(1, 0, 0)) -- red at <3 sec
    self.colorCurve:AddPoint(3, CreateColor(1, 1, 0)) -- yellow at 3-7 sec
    self.colorCurve:AddPoint(7, CreateColor(1, 1, 1)) -- white at >7 sec

    self.auraTrackers = {}
    -- self.auraFrame.text = self.auraFrame:CreateFontString(nil, "ARTWORK", "GameTooltipText")
    -- self.auraFrame.text:SetPoint("LEFT", self.auraFrame, "LEFT", 8, 0)
    -- self.auraFrame.text:SetText("Initialized")
end

function Addon:OnUpdate()
    ---@type AuraData[]
    local auraIds = C_UnitAuras.GetUnitAuraInstanceIDs("target", "PLAYER|HARMFUL") or {}
    for _, id in ipairs(auraIds) do
        local tracker = self.auraTrackers[id] 
        if not tracker then 
            tracker = CreateAuraTracker(self.auraFrame, 'target', id)
            self.auraTrackers[tracker.instanceID] = tracker
        end
    end

    local innerHeight = 0
    local prev = nil
    for _, tracker in pairs(self.auraTrackers) do
        local exists = tracker:Update()
        if not exists then 
            self.auraTrackers[tracker.instanceID] = nil
        end

        if prev then 
            tracker.frame:SetPoint("TOPLEFT", prev.frame, "BOTTOMLEFT", 0, -4)
        else
            tracker.frame:SetPoint("TOPLEFT", self.auraFrame, "TOPLEFT", 8, -8)
        end
        innerHeight = innerHeight + tracker.frame:GetLineHeight() + 4
        prev = tracker
    end
    self.auraFrame:SetHeight(math.max(innerHeight + 16, 50))
end

---@param parent Frame
---@param unit string
---@param auraInstanceID number
function CreateAuraTracker(parent, unit, auraInstanceID)
    local tracker = {}

    tracker.unit = unit
    tracker.instanceID = auraInstanceID
    tracker.frame = parent:CreateFontString(nil, "ARTWORK", "GameTooltipText")

    
    function tracker:Update()
        local data = C_UnitAuras.GetAuraDataByAuraInstanceID(self.unit, self.instanceID)
        if not data then
            self.frame:SetParent(nil)
            self.frame:Hide()
            return false
        end
     
        ---@type DurationObject
        tracker.duration = C_UnitAuras.GetAuraDuration(unit, auraInstanceID)
        local remaining = self.duration:GetRemainingDuration(Enum.DurationTimeModifier.BaseTime)

        local color = self.duration:EvaluateRemainingDuration(Addon.colorCurve, Enum.DurationTimeModifier.BaseTime)
        self.frame:SetText(color:WrapTextInColorCode(data.name .. ": " .. remaining))
        
        return true
    end

    return tracker
end

Addon:OnInitialize()
