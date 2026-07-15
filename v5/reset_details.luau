local MAIN_PANEL_ID = "aaronroquefonseca/codex-usage:details"
local state = noctalia.state.get("usage") or { loading = true }

local function credits()
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

local function expiration(epoch)
  if epoch == nil then return "Does not expire" end
  if type(epoch) ~= "number" then return "Expiration unavailable" end
  return "Expires " .. noctalia.formatTime("%H:%M on %d %b %Y", epoch)
end

local function render()
  local available, count = credits()
  local children = {
    ui.row({ gap = 8, align = "center" }, {
      ui.button({ glyph = "chevron-left", variant = "ghost", onClick = "onBack" }),
      ui.label({ text = "Limit resets", color = "on_surface", fontSize = 19, fontWeight = "bold", flexGrow = 1 }),
      ui.label({ text = tostring(count), color = "on_surface_variant", fontSize = 13 }),
    }),
    ui.separator({ color = "outline/0.4", thickness = 1 }),
    ui.label({ text = count == 1 and "1 usage limit reset available." or (count .. " usage limit resets available."), color = "on_surface", fontWeight = "semibold" }),
  }
  for index, credit in ipairs(available) do
    table.insert(children, ui.column({ key = "reset-" .. index, fill = "surface_variant", radius = 10, padding = 10, gap = 3 }, {
      ui.label({ text = tostring(credit.title or "Full reset"), color = "on_surface", fontWeight = "semibold", maxLines = 2 }),
      ui.label({ text = expiration(credit.expiresAt), color = "on_surface_variant", fontSize = 12 }),
    }))
  end
  if count == 0 then
    table.insert(children, ui.label({ text = "You do not have any usage limit resets available.", color = "on_surface_variant" }))
  elseif count > #available then
    table.insert(children, ui.label({ text = "Some reset expiration details are unavailable.", color = "on_surface_variant", fontSize = 12 }))
  end
  table.insert(children, ui.button({ text = "Close", glyph = "close", variant = "outline", onClick = "onClose" }))
  panel.render(ui.column({ key = "root", padding = 16, gap = 10, fill = "surface" }, children))
end

noctalia.state.watch("usage", function(value)
  state = type(value) == "table" and value or { loading = true }
  render()
end)
function update() render() end
function onOpen() render() end
function onBack() noctalia.togglePanel(MAIN_PANEL_ID) end
function onClose() panel.close() end
