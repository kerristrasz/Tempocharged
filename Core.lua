---@diagnostic disable: unused-local

---@class Tempocharged
Tempocharged = select(2, ...)

local events = {}
local eventFrame = CreateFrame("Frame")

function Tempocharged:RegisterEvent(event, handler)
    if type(handler) == "string" then
        handler = self[handler]
    end
    eventFrame:RegisterEvent("PLAYER_LOGIN")
    events[event] = function(...) handler(self, ...) end
end

function Tempocharged:OnInitialize()
    -- local cd = getmetatable(CreateFrame("Cooldown"))
    -- for k, _ in pairs(cd.__index) do
    --     print(" - "..k)
    -- end

    eventFrame:SetScript("OnUpdate", function() Tempocharged:OnUpdate() end)
    eventFrame:SetScript("OnEvent", function(frame, event, ...)
        if events[event] then
            events[event](...)
        end
    end)

    self.M_Displays:Initialize()

    Tempocharged:RegisterEvent("PLAYER_LOGIN", "OnEnable")
end

function Tempocharged:OnEnable()
    self:SetUpCurves()

    if TargetFrame ~= nil then
        hooksecurefunc(TargetFrame, "UpdateAuraFrames",
            function(targetFrame, auraList, numAuras, numOppositeAuras, setupFunc, anchorFunc, maxRowWidth, offsetX,
                     mirrorAurasVertically, template)
                ---@cast targetFrame Frame


                for i, child in ipairs({ targetFrame:GetChildren() }) do
                    -- print(i, childFrame.unit, childFrame.auraInstanceID)

                    local aura = child.auraInstanceID and auraList[child.auraInstanceID]
                    if aura ~= nil then
                        -- local aura = auraList[auraInstanceID] ---@type AuraData
                        -- print(auraList[childFrame.auraInstanceID])
                        self:TargetAuraFrame_Update(child, aura)

                        -- local cd = childFrame['Cooldown'] ---@type Cooldown
                        -- if not cd.__tccc then
                        --     cd.__tccc = true
                        --     cd:SetHideCountdownNumbers(false)
                        --     cd:HookScript("OnUpdate", function(frame) self:TargetAuraFrameCooldown_OnUpdate(frame) end)
                        -- end
                    end
                end
            end)
    end
end

function Tempocharged:TargetAuraFrame_Update(frame, aura)
    -- local unit, auraInstanceID, cooldown = frame.unit, frame.auraInstanceID, frame.cooldown

    -- run setup if needed
    if frame.__tempocharged__ == nil then
        -- Set up normal countdown numbers
        frame.Cooldown:SetHideCountdownNumbers(false)
        frame.Cooldown:GetCountdownFontString():SetFont(STANDARD_TEXT_FONT, 10.5, "OUTLINE")
        frame.Cooldown:GetCountdownFontString():SetTextColor(1, 1, 0.1, 1)

        -- Set up big countdown numbers
        local extraFrame = CreateFrame("Frame", frame:GetDebugName() .. ".__tempocharged__", frame)
        extraFrame:SetAllPoints()
        -- print(extraFrame:GetSize())

        extraFrame.shortCountdownFontString = extraFrame:CreateFontString()
        extraFrame.shortCountdownFontString:SetPoint("CENTER")
        extraFrame.shortCountdownFontString:SetFont(STANDARD_TEXT_FONT, 10.5 * 1.5, "OUTLINE") 
        extraFrame.shortCountdownFontString:SetTextColor(1, 0.1, 0.1, 1)
        extraFrame.shortCountdownFontString:SetJustifyV("MIDDLE")
        extraFrame.shortCountdownFontString:SetJustifyH("CENTER")

        frame.__tempocharged__ = extraFrame

        frame.Cooldown:HookScript("OnUpdate", function(cd)
            self:TargetAuraFrameCooldown_OnUpdate(cd, aura)
        end)
    end

    --
end

---@param cooldown Cooldown
function Tempocharged:TargetAuraFrameCooldown_OnUpdate(cooldown, aura)
    local unit = cooldown:GetParent().unit
    local auraInstanceID = cooldown:GetParent().auraInstanceID
    if unit == nil or auraInstanceID == nil then return end

    local duration = C_UnitAuras.GetAuraDuration(unit, auraInstanceID) ---@type DurationObject

    local shortText = cooldown:GetParent().__tempocharged__.shortCountdownFontString ---@type FontString
    local mediumText = cooldown:GetCountdownFontString() ---@type FontString

    -- local color = duration:EvaluateRemainingDuration(self.colorCurve)
    -- local scale = duration:EvaluateRemainingDuration(self.scaleCurve)
    local shortAlpha = duration:EvaluateRemainingDuration(self.shortDurationCurve)
    local mediumAlpha = duration:EvaluateRemainingDuration(self.mediumDurationCurve)

    -- text:SetFont("fonts/frizqt__.ttf", 12, "OUTLINE")

    
    -- local text = string.format("%0.1f", duration:GetRemainingDuration())
    local text = C_StringUtil.RoundToNearestString(duration:GetRemainingDuration())

    shortText:SetText(text)
    -- shortText:SetTextColor(color.r, color.g, color.b, color.a)
    -- shortText:SetAlpha(1)
    shortText:SetAlpha(shortAlpha)

    -- mediumText:SetTextColor(color.r, color.g, color.b, color.a)
    mediumText:SetAlpha(mediumAlpha)
    -- text:SetTextScale(0.75)
    -- text:SetTextScale(scale)
end

function Tempocharged:SetUpCurves()
    local SECOND = 1
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
            -- scale = 1.5,
            soon = true,
        },
        {
            time = SECONDS_THRESHOLD,
            color = CreateColor(1, 1, 0.1),
            -- scale = 1,
        },
        {
            time = MINUTES_THRESHOLD,
            color = CreateColor(1, 1, 1),
            -- scale = 1,
        },
        {
            time = HOURS_THRESHOLD,
            color = CreateColor(0.7, 0.7, 0.7),
            -- scale = 0.75,
        },
        {
            time = DAYS_THRESHOLD,
            color = CreateColor(0.7, 0.7, 0.7),
            -- scale = 0.75,
        },
    }

    self.colorCurve = C_CurveUtil.CreateColorCurve()
    self.colorCurve:SetType(Enum.LuaCurveType.Step)

    -- self.scaleCurve = C_CurveUtil.CreateCurve()
    -- self.scaleCurve:SetType(Enum.LuaCurveType.Step)

    self.shortDurationCurve = C_CurveUtil.CreateCurve()
    self.shortDurationCurve:SetType(Enum.LuaCurveType.Step)
    self.shortDurationCurve:AddPoint(SOON_THRESHOLD, 1)
    self.shortDurationCurve:AddPoint(SECONDS_THRESHOLD, 0)

    self.mediumDurationCurve = C_CurveUtil.CreateCurve()
    self.mediumDurationCurve:SetType(Enum.LuaCurveType.Step)
    self.mediumDurationCurve:AddPoint(SOON_THRESHOLD, 0)
    self.mediumDurationCurve:AddPoint(SECONDS_THRESHOLD, 1)

    for _, point in ipairs(POINTS) do
        self.colorCurve:AddPoint(point.time, point.color)
        -- self.scaleCurve:AddPoint(point.time, point.scale)

        -- self.shortDurationCurve:AddPoint(point.time, point.soon and 1 or 0)
        -- self.mediumDurationCurve:AddPoint(point.time, point.soon and 0 or 1)
    end

    -- self.auraFrame = CreateFrame("Frame", nil, nil, "BackdropTemplate")

    -- self.auraFrame:SetPoint("TOPLEFT", nil, "TOPLEFT", 25, -25)
    -- self.auraFrame:SetSize(200, 100)
    -- self.auraFrame:SetBackdrop(BACKDROP_TUTORIAL_16_16)


    -- self.colorCurve = C_CurveUtil.CreateColorCurve()
    -- self.colorCurve:SetType(Enum.LuaCurveType.Step)
    -- self.colorCurve:AddPoint(0, CreateColor(1, 0, 0)) -- red at <3 sec
    -- self.colorCurve:AddPoint(3, CreateColor(1, 1, 0)) -- yellow at 3-7 sec
    -- self.colorCurve:AddPoint(7, CreateColor(1, 1, 1)) -- white at >7 sec

    -- self.auraTrackers = {}
end

function Tempocharged:OnUpdate()
    -- ---@type AuraData[]
    -- local auraIds = C_UnitAuras.GetUnitAuraInstanceIDs("target", "PLAYER|HARMFUL") or {}
    -- for _, id in ipairs(auraIds) do
    --     local tracker = self.auraTrackers[id]
    --     if not tracker then
    --         tracker = CreateAuraTracker(self.auraFrame, 'target', id)
    --         self.auraTrackers[tracker.instanceID] = tracker
    --     end
    -- end

    -- local innerHeight = 0
    -- local prev = nil
    -- for _, tracker in pairs(self.auraTrackers) do
    --     local exists = tracker:Update()
    --     if not exists then
    --         self.auraTrackers[tracker.instanceID] = nil
    --     end

    --     if prev then
    --         tracker.frame:SetPoint("TOPLEFT", prev.frame, "BOTTOMLEFT", 0, -4)
    --     else
    --         tracker.frame:SetPoint("TOPLEFT", self.auraFrame, "TOPLEFT", 8, -8)
    --     end
    --     innerHeight = innerHeight + tracker.frame:GetLineHeight() + 4
    --     prev = tracker
    -- end
    -- self.auraFrame:SetHeight(math.max(innerHeight + 16, 50))
end

-- ---@param parent Frame
-- ---@param unit string
-- ---@param auraInstanceID number
-- function CreateAuraTracker(parent, unit, auraInstanceID)
--     local tracker = {}

--     tracker.unit = unit
--     tracker.instanceID = auraInstanceID
--     tracker.frame = parent:CreateFontString(nil, "ARTWORK", "GameTooltipText")


--     function tracker:Update()
--         local data = C_UnitAuras.GetAuraDataByAuraInstanceID(self.unit, self.instanceID)
--         if not data then
--             self.frame:SetParent(nil)
--             self.frame:Hide()
--             return false
--         end

--         ---@type DurationObject
--         tracker.duration = C_UnitAuras.GetAuraDuration(unit, auraInstanceID)
--         local remaining = self.duration:GetRemainingDuration(Enum.DurationTimeModifier.BaseTime)

--         local color = self.duration:EvaluateRemainingDuration(Tempocharged.colorCurve, Enum.DurationTimeModifier.BaseTime)
--         self.frame:SetText(color:WrapTextInColorCode(data.name .. ": " .. remaining))

--         return true
--     end

--     return tracker
-- end
