--- @diagnostic disable: unused-local

--- @class Tempocharged
local Tempocharged = select(2, ...)

--- Called when the addon and its SavedVariables are fully loaded.
function Tempocharged:OnInitialize()
end

--- Called when the player loads their UI.
function Tempocharged:OnEnable()
    self.Countdown.Initialize()
end
