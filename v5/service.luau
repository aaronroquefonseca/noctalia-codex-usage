local STATE_KEY = "usage"
local REFRESH_KEY = "refresh_request"

local busy = false
local lastRequest = nil

local function quote(value)
  local text = tostring(value or "")
  return "'" .. string.gsub(text, "'", "'\\''") .. "'"
end

local function intervalMs()
  local seconds = tonumber(noctalia.getConfig("refresh_interval_seconds")) or 300
  return math.max(60, math.min(3600, seconds)) * 1000
end
