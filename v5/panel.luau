local state = noctalia.state.get("usage") or { loading = true }
local resetsExpanded = false
local refreshSequence = 0

local function clamp(value)
  return math.max(0, math.min(100, value))
end

local function remaining(window)
  if type(window) ~= "table" or type(window.usedPercent) ~= "number" then return nil end
  return clamp(100 - window.usedPercent)
end

local function windowName(minutes)
  if type(minutes) ~= "number" then return "Usage window" end
  if minutes % 10080 == 0 then return (minutes / 10080) .. "-week window" end
  if minutes % 1440 == 0 then return (minutes / 1440) .. "-day window" end
  if minutes % 60 == 0 then return (minutes / 60) .. "-hour window" end
  return minutes .. "-minute window"
end

local function resetText(epoch)
  if type(epoch) ~= "number" then return "Reset time unavailable" end
  local delta = math.max(0, epoch - os.time())
  if delta < 60 then return "Resets in less than a minute" end
  if delta < 3600 then return "Resets in " .. math.ceil(delta / 60) .. " min" end
  if delta < 86400 then
    local hours = math.floor(delta / 3600)
    local minutes = math.ceil((delta % 3600) / 60)
    return "Resets in " .. hours .. "h" .. (minutes > 0 and (" " .. minutes .. "m") or "")
  end
  return "Resets " .. noctalia.formatTime("%a %H:%M", epoch)
end

local function severity(value)
  if not value then return "on_surface" end
  if value <= 10 then return "error" end
  if value <= 25 then return "tertiary" end
  return "primary"
end

local function usageCard(window, key)
  local value = remaining(window)
  return ui.column({ key = key, fill = "surface_variant", radius = 12, padding = 12, gap = 7 }, {
    ui.row({ gap = 8, justify = "space_between", align = "center" }, {
      ui.label({ text = windowName(window.windowDurationMins), color = "on_surface", fontWeight = "semibold", flexGrow = 1 }),
      ui.label({ text = value and (value .. "%") or "—", color = severity(value), fontSize = 18, fontWeight = "bold" }),
    }),
    ui.label({ text = resetText(window.resetsAt), color = "on_surface_variant", fontSize = 12 }),
    ui.progress({ progress = value and (value / 100) or 0, fill = severity(value), track = "outline/0.35", height = 6, radius = 3 }),
  })
end

local function resetCredits()
  local summary = type(state.resetCredits) == "table" and state.resetCredits or {}
  local source = type(summary.credits) == "table" and summary.credits or {}
  local available = {}
  for _, credit in ipairs(source) do
    if type(credit) == "table" and string.lower(tostring(credit.status or "")) == "available" then
      table.insert(available, credit)
    end
  end
  table.sort(available, function(a, b)
    return (tonumber(a.expiresAt) or math.huge) < (tonumber(b.expiresAt) or math.huge)
  end)
  return available, tonumber(summary.availableCount) or #available
end

local function expirationText(epoch)
  if epoch == nil then return "Does not expire" end
  if type(epoch) ~= "number" then return "Expiration unavailable" end
  return "Expires " .. noctalia.formatTime("%H:%M on %d %b %Y", epoch)
end

local function creditCard(value)
  return ui.column({ key = "credits", flexGrow = 1, fill = "surface_variant", radius = 12, padding = 10, gap = 2, align = "center" }, {
    ui.label({ text = tostring(value), color = "on_surface", fontSize = 17, fontWeight = "bold", textAlign = "center" }),
    ui.label({ text = "Credits", color = "on_surface_variant", fontSize = 12, textAlign = "center" }),
  })
end

local function render()
  local limits = type(state.rateLimits) == "table" and state.rateLimits or {}
  local children = {}

  table.insert(children, ui.row({ gap = 10, align = "center" }, {
    ui.image({ path = "../icons/openai.svg", width = 22, height = 22, fit = "contain" }),
    ui.label({ text = "Codex usage", color = "on_surface", fontSize = 19, fontWeight = "bold", flexGrow = 1 }),
    ui.label({ text = tostring(limits.planType or ""), color = "on_surface_variant", fontSize = 12 }),
  }))
  table.insert(children, ui.separator({ color = "outline/0.4", thickness = 1 }))

  if state.ok == false then
    table.insert(children, ui.column({ fill = "error/0.15", radius = 10, padding = 10 }, {
      ui.label({ text = tostring(state.error or "Unable to read Codex usage"), color = "error", maxLines = 4 }),
    }))
  end
  if limits.primary then table.insert(children, usageCard(limits.primary, "primary")) end
  if limits.secondary then table.insert(children, usageCard(limits.secondary, "secondary")) end

  local credits = type(limits.credits) == "table" and limits.credits or {}
  local available, availableCount = resetCredits()
  local creditValue = credits.unlimited and "∞" or tostring(credits.balance or "—")
  table.insert(children, ui.row({ gap = 10, align = "stretch" }, {
    creditCard(creditValue),
    ui.button({
      key = "resets",
      text = tostring(availableCount) .. "  " .. (resetsExpanded and "Hide resets" or "Limit resets"),
      glyph = resetsExpanded and "chevron-up" or "chevron-down",
      variant = "secondary",
      flexGrow = 1,
      onClick = "onToggleResets",
    }),
  }))

  if resetsExpanded then
    local detailChildren = {
      ui.label({ text = availableCount == 1 and "1 usage limit reset available." or (availableCount .. " usage limit resets available."), color = "on_surface", fontWeight = "semibold" }),
    }
    for index, credit in ipairs(available) do
      table.insert(detailChildren, ui.column({ key = "reset-" .. index, fill = "surface_variant", radius = 10, padding = 10, gap = 3 }, {
        ui.label({ text = tostring(credit.title or "Full reset"), color = "on_surface", fontWeight = "semibold", maxLines = 2 }),
        ui.label({ text = expirationText(credit.expiresAt), color = "on_surface_variant", fontSize = 12 }),
      }))
    end
    if availableCount == 0 then
      table.insert(detailChildren, ui.label({ text = "You do not have any usage limit resets available.", color = "on_surface_variant" }))
    elseif availableCount > #available then
      table.insert(detailChildren, ui.label({ text = "Some reset expiration details are unavailable.", color = "on_surface_variant", fontSize = 12 }))
    end
    table.insert(children, ui.column({ key = "reset-details", gap = 7 }, detailChildren))
  end

  table.insert(children, ui.separator({ color = "outline/0.4", thickness = 1 }))
  local updated = state.updatedAt and ("Updated at " .. noctalia.formatTime("%H:%M", state.updatedAt)) or "Not updated yet"
  table.insert(children, ui.label({ text = state.loading and "Refreshing…" or updated, color = "on_surface_variant", fontSize = 12 }))
  table.insert(children, ui.row({ gap = 8 }, {
    ui.button({ text = state.loading and "Refreshing…" or "Refresh", glyph = "refresh", variant = "outline", enabled = not state.loading, flexGrow = 1, onClick = "onRefresh" }),
    ui.button({ text = "Close", glyph = "close", variant = "ghost", onClick = "onClose" }),
  }))

  panel.render(ui.scroll({ key = "root", padding = 16, gap = 10, fill = "surface" }, {
    ui.column({ key = "content", gap = 10 }, children),
  }))
end

noctalia.state.watch("usage", function(value)
  state = type(value) == "table" and value or { loading = true }
  render()
end)

panel.setWantsSecondTicks(true)

function update()
  render()
end

function onToggleResets()
  resetsExpanded = not resetsExpanded
  render()
end

function onRefresh()
  refreshSequence = refreshSequence + 1
  noctalia.state.set("refresh_request", { token = tostring(os.time()) .. ":" .. refreshSequence })
end

function onClose()
  panel.close()
end
