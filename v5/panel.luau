local RESET_PANEL_ID = "aaronroquefonseca/codex-usage:reset-details"
local state = noctalia.state.get("usage") or { loading = true }
local refreshSequence = 0
local iconPath = noctalia.pluginDir() .. "/../icons/openai.svg"

local function clamp(value)
  return math.max(0, math.min(100, value))
end

local function remaining(window)
  if type(window) ~= "table" or type(window.usedPercent) ~= "number" then return nil end
  return clamp(100 - window.usedPercent)
