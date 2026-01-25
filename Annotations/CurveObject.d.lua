---@meta _

---The `CurveObject` type allows various addon functionality with secrets, that would otherwise not
---be possible. These are typically used as `ColorCurveObject` for health bars or other similar uses.
---Create one using `C_CurveUtil.CreateCurve()`. 
---
---@class CurveObject : CurveObjectBase
local CurveObject = {}

---Adds a single point to the curve. 
---
---@param x number
---@param y number
function CurveObject:AddPoint(x, y) end

---Removes all points from the curve. Evaluating an empty curve always yields
---a zero value. Note that this does not reset the secret state of the curve.
---Call `CurveObject:SetToDefaults()` for that. 
function CurveObject:ClearPoints() end

---Returns a new copy of this curve.
---
---@return CurveObject curve 
function CurveObject:Copy() end

---Returns a calculated 'y'' value from the configured curve points. 
---
---@param x number
---@return number y
function CurveObject:Evaluate(x) end

---Returns the vector for an individual point index on the curve.
---
---@param index number
---@return vector2? point
function CurveObject:GetPoint(index) end

---Returns the total number of points on the curve.
---
---@return number size
function CurveObject:GetPointCount() end

---Returns the vectors for all points on the curve.
---@return vector2[] point
function CurveObject:GetPoints() end

---Removes a single point from the curve. Raises an error if the supplied point
---index is out of range.
---
---@param index number
function CurveObject:RemovePoint(index) end

---Replaces all points on the curve.
---
---@param point vector2[]
function CurveObject:SetPoints(point) end

---Resets all state on the curve, and clears the secret values flag.
function CurveObject:SetToDefaults() end