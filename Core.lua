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
    eventFrame:SetScript("OnEvent", function(frame, event, ...)
        if events[event] then
            events[event](...)
        end
    end)

    Tempocharged:RegisterEvent("PLAYER_LOGIN", "OnEnable")
end

function Tempocharged:OnEnable()
    self.Countdown.Initialize()
end
