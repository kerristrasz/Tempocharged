--- @class Tempocharged
local Tempocharged = select(2, ...)

--- @class Tempocharged.Options
local module = {}

--- @class Tempocharged.Options.Theme
--- @field font Tempocharged.Options.Font
--- @field shadow Tempocharged.Options.FontShadow
--- @field point Tempocharged.Options.Position
--- @field durationStyles Tempocharged.Options.DurationStyle[]
--- @field rechargingStyle Tempocharged.Options.Style
--- @field lossOfControlStyle Tempocharged.Options.Style

--- @class Tempocharged.Options.Font
--- @field file FontFile
--- @field height number
--- @field flags? TBFFlags

--- @class Tempocharged.Options.FontShadow
--- @field r number
--- @field g number
--- @field b number
--- @field a? number
--- @field offsetX number
--- @field offsetY number

--- @class Tempocharged.Options.Position
--- @field anchor FramePoint
--- @field offsetX number
--- @field offsetY number

--- @class Tempocharged.Options.Style
--- @field r number
--- @field g number
--- @field b number
--- @field a? number
--- @field scale number

--- @class Tempocharged.Options.DurationStyle : Tempocharged.Options.Style
--- @field minDuration number

--- @return Tempocharged.Options.Theme
function module.GetTheme()
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
        durationStyles = {
            --- Must be sorted by minDuration
            {
                minDuration = 0.5,
                r = 1,
                g = 0.1,
                b = 0.1,
                scale = 1.5,
            },
            {
                minDuration = 5.5 * sec,
                r = 1,
                g = 1,
                b = 0.1,
                scale = 1,
            },
            {
                minDuration = min - 0.5 * sec,
                r = 1,
                g = 1,
                b = 1,
                scale = 1,
            },
            {
                minDuration = hr - 0.5 * min,
                r = 0.7,
                g = 0.7,
                b = 0.7,
                scale = 0.75,
            },
            {
                minDuration = day - 0.5 * hr,
                r = 0.7,
                g = 0.7,
                b = 0.7,
                scale = 0.75,
            },
        },
        rechargingStyle = {
            r = 0.8,
            g = 1,
            b = .3,
            a = .8,
            scale = .75,
        },
        lossOfControlStyle = {
            r = 1,
            g = .1,
            b = .1,
            scale = 1.5,
        },
    }
end

Tempocharged.Options = module
