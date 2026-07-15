local state=noctalia.state.get("usage") or {loading=true}
local view="usage"
local seq=0
local icon=noctalia.pluginDir().."/../icons/openai.svg"

local function rem(w)
  if type(w)~="table" or type(w.usedPercent)~="number" then return nil end
  return math.max(0,math.min(100,100-w.usedPercent))
end
local function name(m)
  if type(m)~="number" then return "Usage window" end
  if m%10080==0 then return (m/100