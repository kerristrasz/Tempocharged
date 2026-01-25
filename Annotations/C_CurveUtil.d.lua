--- @meta _

--- @class C_CurveUtil
C_CurveUtil = {}

--- Returns a new color curve object with no assigned points.
---
--- @return ColorCurveObject curve
function C_CurveUtil.CreateColorCurve() end

--- Returns a new curve object with no assigned points.
---
--- @return CurveObject curve
function C_CurveUtil.CreateCurve() end

--- Evaluates a potentially-secret boolean value and returns a color.
---
--- @param boolean boolean
--- @param valueIfTrue colorRGBA
--- @param valueIfFalse colorRGBA
--- @return colorRGBA value
function C_CurveUtil.EvaluateColorFromBoolean(boolean, valueIfTrue, valueIfFalse) end

--- Evaluates a potentially-secret boolean value and returns a single color component (eg. alpha).
---
--- @param boolean boolean
--- @param valueIfTrue SingleColorValue
--- @param valueIfFalse SingleColorValue
--- @return SingleColorValue value
function C_CurveUtil.EvaluateColorValueFromBoolean(boolean, valueIfTrue, valueIfFalse) end

--- @param curveID number
--- @param x number
--- @return number y
function C_CurveUtil.EvaluateGameCurve(curveID, x) end
