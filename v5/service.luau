local STATE_KEY = "usage"
local REFRESH_KEY = "refresh_request"

local busy = false
local lastRefreshRequest = nil

local function shellQuote(value)
  local text = tostring(value or "")
  return "'" .. string.gsub(text, "'", "'\\''") .. "'"
end

local function refreshIntervalMs()
  local seconds = tonumber(noctalia.getConfig("refresh_interval_seconds")) or 300
  seconds = math.max(60, math.min(3600, seconds))
