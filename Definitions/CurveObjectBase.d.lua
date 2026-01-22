---@meta _

---@class CurveObjectBase
local CurveObjectBase = {}

---Returns the configured type of the curve.
---
---@return Enum.LuaCurveType curveType
function CurveObjectBase:GetType() end

---Returns true if the curve has been configured with any secret values. Curves with secret values
---always produce secret results when evaluated.
---
---@return boolean hasSecretValues
function CurveObjectBase:HasSecretValues() end

---Changes the evaluation type of the curve.
---
---The default type for newly created curves is `Enum.LuaCurveType.Linear`.
---
---@param type Enum.LuaCurveType
function CurveObjectBase:SetType(type) end
