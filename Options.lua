--- @class Tempocharged
local Tempocharged = select(2, ...)

--- @class Tempocharged.Options
local Options = {}
Tempocharged.Options = Options

--- @class Tempocharged.Options.Config
--- @field font Tempocharged.Options.FontConfig
--- @field shadow Tempocharged.Options.FontShadowConfig
--- @field point Tempocharged.Options.PointConfig
--- @field cooldownText Tempocharged.Options.TextConfig[]
--- @field chargeText Tempocharged.Options.TextConfig
--- @field lossOfControlText Tempocharged.Options.TextConfig

--- @class Tempocharged.Options.FontConfig
--- @field file FontFile
--- @field height number
--- @field flags? TBFFlags

--- @class Tempocharged.Options.FontShadowConfig
--- @field r number
--- @field g number
--- @field b number
--- @field a? number
--- @field offsetX number
--- @field offsetY number

--- @class Tempocharged.Options.PointConfig
--- @field anchor FramePoint
--- @field offsetX number
--- @field offsetY number

--- @class Tempocharged.Options.TextConfig
--- @field minDuration number
--- @field r number
--- @field g number
--- @field b number
--- @field a? number
--- @field scale number

--- Gets the raw database config.
---
--- @return Tempocharged.Options.Config
local function GetConfig()
    local sec = 1
    local min = 60 * sec
    local hr = 60 * min
    local day = 24 * hr

    -- TODO: use an actual database
    return {
        font = {
            file = "fonts/frizqt__.ttf",
            height = 18,
            flags = "OUTLINE",
        },
        shadow = {
            r = 1,
            g = 1,
            b = 1,
            a = 0,
            offsetX = 0,
            offsetY = 0,
        },
        point = {
            anchor = "CENTER",
            offsetX = 0,
            offsetY = 0,
        },
        cooldownText = {
            {
                minDuration = 0,
                r = 1,
                g = 0.1,
                b = 0.1,
                scale = 1.5,
            },
            {
                minDuration = 5 * sec,
                r = 1,
                g = 1,
                b = 0.1,
                scale = 1,
            },
            {
                minDuration = min,
                r = 1,
                g = 1,
                b = 1,
                scale = 1,
            },
            {
                minDuration = hr,
                r = 0.7,
                g = 0.7,
                b = 0.7,
                scale = 0.75,
            },
            {
                minDuration = day,
                r = 0.7,
                g = 0.7,
                b = 0.7,
                scale = 0.75,
            },
        },
        chargeText = {
            minDuration = 0,
            r = 0.8,
            g = 1,
            b = .3,
            a = .8,
            scale = .75,
        },
        lossOfControlText = {
            minDuration = 0,
            r = 1,
            g = .1,
            b = .1,
            scale = 1.5,
        },
    }
end

-- TODO: change this back to a common CooldownType
-- (auras should always use `auraDisplayTime = true`)
--- @enum Tempocharged.SpellCooldownType
Tempocharged.SpellCooldownType = {
    Cooldown = 1,
    Charge = 2,
    LossOfControl = 3,
}

--- @class Tempocharged.CooldownStyle
--- @field countdowns Tempocharged.CountdownStyle

--- @class Tempocharged.CountdownStyle
--- @field fontFile FontFile
--- @field fontHeight number
--- @field fontFlags TBFFlags?
--- @field shadowColor ColorMixin
--- @field shadowOffsetX number
--- @field shadowOffsetY number
--- @field anchor FramePoint
--- @field offsetX number
--- @field offsetY number
--- @field scale number
--- @field colorCurve ColorCurveObject the curve to use when `useAuraDisplayTime` is `false`
--- @field auraColorCurve ColorCurveObject the curve to use when `useAuraDisplayTime` is `true`

--- @type { [Tempocharged.SpellCooldownType]: Tempocharged.CooldownStyle }
local cachedStyles = {}

--- Spells count down to 1, but auras count down to 0.
--- Because of this, we need to offset aura durations a bit.
local AURA_DISPLAY_TIME_OFFSET = 1

local TRANSPARENT = CreateColor(0, 0, 0, 0)

--- @param spellType? Tempocharged.SpellCooldownType default = `Cooldown`
--- @return Tempocharged.CooldownStyle
function Options.GetCooldownStyle(spellType)
    spellType = spellType or Tempocharged.SpellCooldownType.Cooldown

    if cachedStyles[spellType] ~= nil then
        return cachedStyles[spellType]
    end

    local config = GetConfig()
    local textConfigs
    if spellType == Tempocharged.SpellCooldownType.Charge then
        textConfigs = { CopyTable(config.chargeText) }
    elseif spellType == Tempocharged.SpellCooldownType.LossOfControl then
        textConfigs = { CopyTable(config.lossOfControlText) }
    elseif spellType == Tempocharged.SpellCooldownType.Cooldown then
        textConfigs = CopyTable(config.cooldownText)
    else
        error("Unknown spell cooldown type " .. spellType)
    end

    -- Copy the shared options right away.
    local baseStyle = {
        fontFile = config.font.file,
        fontHeight = config.font.height,
        fontFlags = config.font.flags,
        shadowColor =
            CreateColor(config.shadow.r, config.shadow.g, config.shadow.b, config.shadow.a),
        shadowOffsetX = config.shadow.offsetX,
        shadowOffsetY = config.shadow.offsetY,
        anchor = config.point.anchor,
        offsetX = config.point.offsetX,
        offsetY = config.point.offsetY,
    }

    -- Need to sort by duration in order to set up the curves correctly.
    table.sort(textConfigs, function(a, b)
        return a.minDuration < b.minDuration
    end)

    -- Colors can be set with a curve, but sizes/scales cannot, so we might need multiple
    -- FontStrings. However, we can merge styles together if they share the same scale,
    -- letting us cut down on the number of FontStrings we create.
    local textConfigsByScale = {}
    for i, cfg in ipairs(textConfigs) do
        cfg.maxDuration = textConfigs[i + 1] and textConfigs[i + 1].minDuration
        cfg.color = CreateColor(cfg.r, cfg.g, cfg.b, cfg.a)

        local tbl = textConfigsByScale[cfg.scale] or {}
        tbl[#tbl + 1] = cfg
        textConfigsByScale[cfg.scale] = tbl
    end


    local result = {
        countdowns = {},
    }

    for scale, configs in pairs(textConfigsByScale) do
        local curve = C_CurveUtil.CreateColorCurve()
        local auraCurve = C_CurveUtil.CreateColorCurve()
        curve:SetType(Enum.LuaCurveType.Step)
        auraCurve:SetType(Enum.LuaCurveType.Step)

        -- Make the text transparent before the first minDuration
        if configs[1].minDuration > 0 then
            curve:AddPoint(0, TRANSPARENT)
        end
        if configs[1].minDuration > AURA_DISPLAY_TIME_OFFSET then
            auraCurve:AddPoint(AURA_DISPLAY_TIME_OFFSET, TRANSPARENT)
        end

        for i, curr in pairs(configs) do
            local prev = configs[i - 1]

            local skip = false
            if prev then
                if prev.maxDuration < curr.minDuration then
                    -- There's a gap! Make the text transparent here.
                    curve:AddPoint(prev.maxDuration, TRANSPARENT)
                    auraCurve:AddPoint(prev.maxDuration + AURA_DISPLAY_TIME_OFFSET, TRANSPARENT)
                else
                    -- No gap... we'd be able to skip adding a point if it wouldn't change the color.
                    if prev.color:IsEqualTo(curr.color) then
                        skip = true
                    end
                end
            end

            if not skip then
                curve:AddPoint(curr.minDuration, curr.color)
                auraCurve:AddPoint(curr.minDuration + AURA_DISPLAY_TIME_OFFSET, curr.color)
            end
        end

        -- Make the text transparent before after the last maxDuration
        if configs[#configs].maxDuration then
            curve:AddPoint(configs[#configs].maxDuration, TRANSPARENT)
            auraCurve:AddPoint(configs[#configs].maxDuration + AURA_DISPLAY_TIME_OFFSET, TRANSPARENT)
        end

        local style = Mixin({
            scale = scale,
            colorCurve = curve,
            auraColorCurve = auraCurve,
        }, baseStyle)

        result.countdowns[#result.countdowns + 1] = style
    end

    cachedStyles[spellType] = result
    return result
end
