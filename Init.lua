---@type string, Tempocharged
local addonName, Tempocharged = ...

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addon = select(1, ...)
        if addon == addonName then
            Tempocharged:OnInitialize()
        end
    else
        if event == "PLAYER_LOGIN" then
            Tempocharged:OnEnable()
        end
    end
end)
