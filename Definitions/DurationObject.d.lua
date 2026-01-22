---@meta _

---If no curve is specified, a floating point percentage value. Else, the result of evaluating the
---curve with the percentage as the input.
---
--- * If no curve or a `CurveObject` is given, returns a floating point number.
--- * If a [`ColorCurveObject`](lua://ColorCurveObject) is given, returns a [`ColorMixin`](lua://ColorMixin) object.
---
---@alias CurveEvaluatedResult
---| number
---| colorRGBA

---`DurationObject`s provide methods to perform calculations natively on potentially secret data
---and return secrets back to Lua. Create one with
---[`C_DurationUtil.CreateDuration()`](lua://C_DurationUtil.CreateDuration). These can be passed to
---[`StatusBar:SetTimerDuration()`](lua://StatusBar.SetTimerDuration). 
---
---@class DurationObject
local DurationObject = {}

---Copies another duration object and assigns it to this one. 
---
---@param other DurationObject
function DurationObject:Assign(other) end

---Returns a copy of this duration object. 
---
---@return DurationObject copy
function DurationObject:Copy() end

---Calculates the elapsed duration in seconds and evaluates it against a supplied curve. 
---
---@param curve CurveObjectBase
---@param modifier? Enum.DurationTimeModifier
---@return CurveEvaluatedResult result 
function DurationObject:EvaluateElapsedDuration(curve, modifier) end

---Calculates the elapsed duration as a percentage value and evaluates it against a supplied curve.
---
---@param curve CurveObjectBase
---@param modifier? Enum.DurationTimeModifier 
---@return CurveEvaluatedResult result
function DurationObject:EvaluateElapsedPercent(curve, modifier) end

---Calculates the remaining duration in seconds and evaluates it against a supplied curve.
---
---@param curve CurveObjectBase
---@param modifier? Enum.DurationTimeModifier
---@return CurveEvaluatedResult result
function DurationObject:EvaluateRemainingDuration(curve, modifier) end

---Calculates the remaining duration as a percentage value and evaluates it against a supplied curve.
---
---@param curve CurveObjectBase
---@param modifier? Enum.DurationTimeModifier
---@return CurveEvaluatedResult result
function DurationObject:EvaluateRemainingPercent(curve, modifier) end

---Calculates the elapsed duration of the stored time span.
---
---@param modifier? Enum.DurationTimeModifier
---@return number elapsedDuration
function DurationObject:GetElapsedDuration(modifier) end

---Calculates the elapsed duration as a percentage value.
---
---@param modifier? Enum.DurationTimeModifier
---@return number elapsedPercent
function DurationObject:GetElapsedPercent(modifier) end

---Calculates the end time of the stored time span. 
---
---@param modifier? Enum.DurationTimeModifier
---@return number endTime
function DurationObject:GetEndTime(modifier) end

---Returns the divisor used to convert a duration from real time to base time. 
---
---@return number modRate
function DurationObject:GetModRate() end

---Calculates the remaining duration of the stored time span. 
---
---@param modifier Enum.DurationTimeModifier?
---@return number remainingDuration
function DurationObject:GetRemainingDuration(modifier)  end

---Calculates the remaining duration as a percentage value. 
---
---@param modifier Enum.DurationTimeModifier?
---@return number remainingPercent
function DurationObject:GetRemainingPercent(modifier) end

---Calculates the start time of the stored time span. 
---
---@param modifier Enum.DurationTimeModifier?
---@return number startTime
function DurationObject:GetStartTime(modifier) end

---Calculates the total duration of the stored time span. 
---
---@param modifier Enum.DurationTimeModifier?
---@return number totalDuration
function DurationObject:GetTotalDuration(modifier) end

---Returns true if the duration has been configured with any secret values. 
---
---@return boolean hasSecretValues
function DurationObject:HasSecretValues() end

---Returns true if the duration object is measuring a zero duration time span. 
---
---@return boolean isZero
function DurationObject:IsZero() end

---Resets the duration object to represent a zero duration time span. 
function DurationObject:Reset() end

---Configures the duration object to represent an end time and a duration. 
---
---@param endTime number
---@param duration number
---@param modRate? number Optional divisor for converting this time span to a base time.
function DurationObject:SetTimeFromEnd(endTime, duration, modRate) end

---Configures the duration object to represent a start time and a duration. 
---
---@param startTime number
---@param duration number
---@param modRate? number Optional divisor for converting this time span to a base time.
function DurationObject:SetTimeFromStart(startTime, duration, modRate) end

---Configures the duration object to represent a fixed start and end time span. If the end time is
---earlier than the start time, the duration will clamp to zero. 
---
---@param startTime number
---@param endTime number
function DurationObject:SetTimeSpan(startTime, endTime) end

---Resets all state on the duration, and clears the secret values flag.
function DurationObject:SetToDefaults() end
