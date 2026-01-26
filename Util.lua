--- @class Tempocharged
local Tempocharged = select(2, ...)

local CreateColorFromRGBHexString = CreateColorFromRGBHexString

--- @class Tempocharged.Util
local module = {}

local hex = function(c)
    return CreateColorFromRGBHexString(c:sub(2))
end

local DEFAULT_COLOR = hex("#FFFFFF")
local KEY_COLOR = hex("#9CDCFE")
local FUNCTION_NAME_COLOR = hex("#DCDCAA")
local TYPE_COLORS = {
    ["string"] = hex("#ce9178"),
    ["number"] = hex("#b5cea8"),
    ["boolean"] = hex("#569cd6"),
    -- ["table"] = hex("#d7ba7d"),
    ["function"] = hex("#C586C0"),
    ["nil"] = hex("#C586C0"),
    ["userdata"] = hex("#4EC9B0"),
}
local SECRET_COLOR = ACCOUNT_WIDE_FONT_COLOR

local INDENT = "    "

local function StringifyFlat(value)
    local color = TYPE_COLORS[type(value)] or DEFAULT_COLOR

    local s
    if type(value) == "string" then
        s = color:WrapTextInColorCode('"' .. value .. '"')
    elseif type(value) == "table" then
        s = color:WrapTextInColorCode("{ ... }")
    elseif type(value) == "function" then
        s = color:WrapTextInColorCode("function")
    elseif type(value) == "userdata" then
        s = color:WrapTextInColorCode("userdata")
    else
        s = color:WrapTextInColorCode(tostring(value))
    end

    if issecretvalue(value) then
        return SECRET_COLOR:WrapTextInColorCode("<secret> ") .. s
    else
        return s
    end
end

--- @param value any
--- @param depth number
--- @param maxDepth number
--- @return string prettyString
local function StringifyRecursive(value, depth, maxDepth)
    --- @diagnostic disable-next-line: undefined-global

    if issecretvalue(value) or depth > maxDepth then
        return StringifyFlat(value)
    end

    if type(value) == "table" then
        local outerIndent = "\n" .. string.rep(INDENT, depth - 1)
        local innerIndent = outerIndent .. INDENT

        -- if #value == 0 and type(value[0]) == "userdata" then
        --     return DEFAULT_COLOR:WrapTextInColorCode("{") ..
        --         " " .. StringifyFlat(value[0]) ..
        --         " " .. StringifyRecursive(getmetatable(value), depth) ..
        --         " " .. DEFAULT_COLOR:WrapTextInColorCode("}")
        -- end

        local str = DEFAULT_COLOR:WrapTextInColorCode("{")

        local i = 0
        for k, v in pairs(value) do
            i = i + 1

            if i > 1 then
                str = str .. DEFAULT_COLOR:WrapTextInColorCode(",")
            end

            str = str .. innerIndent

            if type(k) == "string" then
                local color = (type(v) == "function") and FUNCTION_NAME_COLOR or KEY_COLOR
                str = str .. color:WrapTextInColorCode(k)
            else
                local color = TYPE_COLORS.number
                str = str ..
                    color:WrapTextInColorCode("[") ..
                    StringifyFlat(k) ..
                    color:WrapTextInColorCode("]")
            end

            str = str ..
                DEFAULT_COLOR:WrapTextInColorCode(" = ") ..
                StringifyRecursive(v, depth + 1, maxDepth)
        end


        if i > 0 then
            str = str .. outerIndent
        end
        str = str .. DEFAULT_COLOR:WrapTextInColorCode("}")

        return str
    end

    return StringifyFlat(value)
end

--- @param value any
--- @param maxDepth? number
--- @return string prettyString
function module.Stringify(value, maxDepth)
    return StringifyRecursive(value, 1, maxDepth or 2)
end

--- @generic T
--- @param value T
--- @param maxDepth? number
--- @return T originalValue
function module.Dump(value, maxDepth)
    local str = module.Stringify(value, maxDepth)
    if issecretvalue(str) then
        print(str)
    else
        for _, line in pairs({ string.split("\n", str) }) do
            print(line)
        end
    end
    return value
end

Tempocharged.Util = module
