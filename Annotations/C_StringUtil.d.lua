--- @meta _

C_StringUtil = {}

--- @param text string
--- @return string escapedText
function C_StringUtil.EscapeLuaFormatString(text) end

--- @param text string
--- @return string escapedText
function C_StringUtil.EscapeLuaPatterns(text) end

--- @param text string
--- @return string escaped
function C_StringUtil.EscapeQuotedCodes(text) end

--- @param number number
--- @return string text
function C_StringUtil.FloorToNearestString(number) end

--- @param text string
--- @param maxAllowedSpaces number
--- @return string trimmedText
function C_StringUtil.RemoveContiguousSpaces(text, maxAllowedSpaces) end

--- @param text string
--- @param maintainColor? boolean
--- @param maintainBrackets? boolean
--- @param stripNewlines? boolean
--- @param maintainAtlases? boolean
--- @return string stripped
function C_StringUtil.StripHyperlinks(text, maintainColor, maintainBrackets, stripNewlines,
    maintainAtlases) end

--- @param number number
--- @return string text
function C_StringUtil.TruncateWhenZero(number) end

--- @param infix string
--- @param prefix? string
--- @param suffix? string
--- @return string text
function C_StringUtil.WrapString(infix, prefix, suffix) end

--- @param number number
--- @return string text
function C_StringUtil.RoundToNearestString(number) end
