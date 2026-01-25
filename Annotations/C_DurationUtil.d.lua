--- @meta _

--- @class C_DurationUtil
C_DurationUtil = {}

--- Creates a zero duration container that can represent a time span.
---
--- @return DurationObject duration
function C_DurationUtil.CreateDuration() end

--- Returns the current time used by duration objects. Equivalent to `GetTime()` in public builds.
---
--- @return number currentTime
function C_DurationUtil.GetCurrentTime() end
