--- @meta _

--- @class StatusBar : Frame
local StatusBar = {}

--- Returns the current interpolated value displayed by the bar.
---
--- @return number value
function StatusBar:GetInterpolatedValue() end

--- @return DurationObject duration
function StatusBar:GetTimerDuration() end

--- Returns true if the status bar is currently interpolating toward a target value.
---
--- @return boolean isInterpolating
function StatusBar:IsInterpolating() end

--- @param duration DurationObject
--- @param interpolation? Enum.StatusBarInterpolation
--- @param direction? Enum.StatusBarTimerDirection
function StatusBar:SetTimerDuration(duration, interpolation, direction) end

--- Immediately finishes any interpolation of the bar and snaps it to the target value.
function StatusBar:SetToTargetValue() end
