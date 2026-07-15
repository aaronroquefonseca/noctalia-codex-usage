local state = noctalia.state.get("usage") or { loading = true }
local currentView = "usage"
local refreshSequence = 0
local iconPath = noctalia.pluginDir() .. "/../icons/openai.svg"

local function clamp(v)
  return math.max(0, math.min(100, v))
end

local function remaining(window)
  if type(window) ~= "table" or type(window.usedPercent) ~= "number" then
    return nil
  end
  return clamp(100 -