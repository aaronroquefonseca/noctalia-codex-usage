local RESET_PANEL_ID = "aaronroquefonseca/codex-usage:reset-details"
local state = noctalia.state.get("usage") or { loading = true }
local refreshSequence = 0
local iconPath = noctalia.pluginDir() .. "/../icons/openai.svg"

local function clamp(v) return math.max(0, math.min(100, v)) end
local function remaining(w)
  if type(w) ~= "table" or type(w.usedPercent) ~= "number" then return nil end
  return clamp(100 - w.usedPercent)
end
local function windowName(m)
  if type(m) ~= "number" then return "Usage window" end
  if m % 10080 == 0 then return (m / 10080) .. "-week window" end
  if m % 1440 == 0 then return (m / 1440) .. "-day window" end
  if m % 60 == 0 then return (m / 60) .. "-hour window" end
  return m .. "-minute window"
end
local function resetText(epoch)
  if type(epoch) ~= "number" then return "Reset time unavailable" end
  local d = math.max(0, epoch - os.time())
  if d < 60 then return "Resets in less than a minute" end
  if d < 3600 then return "Resets in " .. math.ceil(d / 60) .. " min" end
  if d < 86400 then
    local h = math.floor(d / 3600)
    local m = math.ceil((d % 3600) / 60)
    return "Resets in " .. h .. "h" .. (m > 0 and (" " .. m .. "m") or "")
  end
  return "Resets " .. noctalia.formatTime("%a %H:%M", epoch)
end
local function severity(v)
  if not v then return "on_surface" end
  if v <= 10 then return "error" end
  if v <= 25 then return "tertiary" end
  return "primary"
end
local function usageCard(w, key)
  local v = remaining(w)
  return ui.column({ key = key, fill = "surface_variant", radius = 12, padding = 12, gap = 7 }, {
    ui.row({ gap = 8, justify = "space_between", align = "center" }, {
      ui.label({ text = windowName(w.windowDurationMins), color = "on_surface", fontWeight = "semibold", flexGrow = 1 }),
      ui.label({ text = v and (v .. "%") or "—", color = severity(v), fontSize = 18, fontWeight = "bold" }),
    }),
    ui.label({ text = resetText(w.resetsAt), color = "on_surface_variant", fontSize = 12 }),
    ui.progress({ progress = v and (v / 100) or 0, fill = severity(v), track = "outline/0.35", height = 6, radius = 3 }),
  })
end
local function resetCount()
  local s = type(state.resetCredits) == "table" and state.resetCredits or {}
  return tonumber(s.availableCount) or 0
end

local function render()
  local limits = type(state.rateLimits) == "table" and state.rateLimits or {}
  local credits = type(limits.credits) == "table" and limits.credits or {}
  local creditValue = credits.unlimited and "∞" or tostring(credits.balance or "—")
  local children = {
    ui.row({ gap = 10, align = "center" }, {
      ui.image({ path = iconPath, width = 22, height = 22, fit = "contain" }),
      ui.label({ text = "Codex usage", color = "on_surface", fontSize = 19, fontWeight = "bold", flexGrow = 1 }),
      ui.label({ text = tostring(limits.planType or ""), color = "on_surface_variant", fontSize = 12 }),
    }),
    ui.separator({ color = "outline/0.4", thickness = 1 }),
  }
  if state.ok == false then
    table.insert(children, ui.column({ fill = "error/0.15", radius = 10, padding = 10 }, {
      ui.label({ text = tostring(state.error or "Unable to read Codex usage"), color = "error", maxLines = 4 }),
    }))
  end
  if limits.primary then table.insert(children, usageCard(limits.primary, "primary")) end
  if limits.secondary then table.insert(children, usageCard(limits.secondary, "secondary")) end
  table.insert(children, ui.row({ gap = 10, align = "stretch" }, {
    ui.column({ key = "credits", flexGrow = 1, fill = "surface_variant", radius = 12, padding = 10, gap = 2, align = "center" }, {
      ui.label({ text = creditValue, color = "on_surface", fontSize = 17, fontWeight = "bold", textAlign = "center" }),
      ui.label({ text = "Credits", color = "on_surface_variant", fontSize = 12, textAlign = "center" }),
    }),
    ui.button({ key = "resets", text = resetCount() .. "  Limit resets", glyph = "chevron-right", variant = "outline", flexGrow = 1, onClick = "onOpenResets" }),
  }))
  table.insert(children, ui.separator({ color = "outline/0.4", thickness = 1 }))
  local updated = state.updatedAt and ("Updated at " .. noctalia.formatTime("%H:%M", state.updatedAt)) or "Not updated yet"
  table.insert(children, ui.label({ text = state.loading and "Refreshing…" or updated, color = "on_surface_variant", fontSize = 12 }))
  table.insert(children, ui.row({ gap = 8 }, {
    ui.button({ text = state.loading and "Refreshing…" or "Refresh", glyph = "refresh", variant = "outline", enabled = not state.loading, flexGrow = 1, onClick = "onRefresh" }),
    ui.button({ text = "Close", glyph = "close", variant = "ghost", onClick = "onClose" }),
  }))
  panel.render(ui.column({ key = "root", padding = 16, gap = 10, fill = "surface" }, children))
end

noctalia.state.watch("usage", function(value)
  state = type(value) == "table" and value or { loading = true }
  render()
end)
panel.setWantsSecondTicks(true)
function update() render() end
function onOpen() render() end
function onOpenResets() noctalia.togglePanel(RESET_PANEL_ID) end
function onRefresh()
  refreshSequence = refreshSequence + 1
  noctalia.state.set("refresh_request", { token = tostring(os.time()) .. ":" .. refreshSequence })
end
function onClose() panel.close() end
