---@meta _

---@enum Enum.DurationTimeModifier
Enum.DurationTimeModifier = {
    ---Use real time for duration calculations. Durations will speed up or slow down based on the
    ---applied mod time.
    RealTime = 0,
    ---Use base time for duration calculations. Durations will be unaffected the applied mod time.
    BaseTime = 1,
}

---@enum Enum.LuaCurveType
Enum.LuaCurveType = {
    ---Linearly interpolates between points.
    Linear = 0,
    ---Performs no interpolation between points, instead snapping to values exactly.
    Step = 1,
    ---Interpolates between points with cosine smoothing applied.
    Cosine = 2,
    ---Interpolates between points with cubic smoothing applied. Requires a minimum of four points
    ---be defined; less than this will fall back to Cosine interpolation.
    Cubic = 3,
}

---@enum Enum.StatusBarInterpolation
Enum.StatusBarInterpolation = {
    ---Immediately snap to the target value with no interpolation. 
    Immediate = 0,
    ---Interpolate the bar toward the target value with exponential ease-out style decay.
    ExponentialEaseOut = 1,
}

---@enum Enum.StatusBarTimerDirection
Enum.StatusBarTimerDirection = {
    ---Calculate status timer bar values using the elapsed time of a duration.
    ElapsedTime = 0,
    ---Calculate status timer bar values using the remaining time of a duration.
    RemainingTime = 1,
}
