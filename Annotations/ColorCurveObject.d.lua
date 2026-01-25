--- @meta _

--- @class LuaColorCurvePoint
--- @field x number
--- @field y colorRGBA

--- The `ColorCurveObject` type allows various addon functionality with secrets, that would otherwise
--- not be possible, for example coloring the health bar based on the remaining health of the unit.
--- The generic `CurveObject` handles other cases. Create one using `C_CurveUtil.CreateColorCurve()`.
---
--- @class ColorCurveObject : CurveObjectBase
local ColorCurveObject = {}

--- Adds a single point to the curve.
---
--- @param x number
--- @param y colorRGBA The alpha parameter is supported but optional.
function ColorCurveObject:AddPoint(x, y) end

--- Removes all points from the curve. Evaluating an empty curve always yields
--- a zero value. Note that this does not reset the secret state of the curve.
--- Call `ColorCurveObject:SetToDefaults()` for that.
function ColorCurveObject:ClearPoints() end

--- Returns a new copy of this curve.
---
--- @return ColorCurveObject curve
function ColorCurveObject:Copy() end

--- Returns a calculated color value from the configured curve points.
---
--- @param x number
--- @return colorRGBA y
function ColorCurveObject:Evaluate(x) end

--- Returns an unpacked calculated color value from the configured curve points.
---
--- @param x number
--- @return SingleColorValue yR
--- @return SingleColorValue yG
--- @return SingleColorValue yB
--- @return SingleColorValue yA
function ColorCurveObject:EvaluateUnpacked(x) end

--- Returns the vector for an individual point index on the curve.
---
--- @param index number
--- @return LuaColorCurvePoint? point
function ColorCurveObject:GetPoint(index) end

--- Returns the total number of points on the curve.
---
--- @return number size
function ColorCurveObject:GetPointCount() end

--- Returns the vectors for all points on the curve.
--- @return LuaColorCurvePoint[] point
function ColorCurveObject:GetPoints() end

--- Removes a single point from the curve. Raises an error if the supplied point
--- index is out of range.
---
--- @param index number
function ColorCurveObject:RemovePoint(index) end

--- Replaces all points on the curve.
---
--- @param point LuaColorCurvePoint[]
function ColorCurveObject:SetPoints(point) end

--- Resets all state on the curve, and clears the secret values flag.
function ColorCurveObject:SetToDefaults() end
