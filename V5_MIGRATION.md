# Noctalia v5 migration

This branch is the native, Quickshell-free Noctalia v5 port. The `main` branch remains the working Noctalia v4/QML implementation until this port reaches feature parity.

## Architecture mapping

| Noctalia v4 | Noctalia v5 |
| --- | --- |
| `manifest.json` | `plugin.toml` |
| `Main.qml` background process | `[[service]]` Luau entry |
| `BarWidget.qml` | `[[widget]]` Luau entry |
| `Panel.qml` | `[[panel]]` Luau entry |
| `Settings.qml` | manifest-declared `[[setting]]` fields |
| QML/Quickshell process spawning | v5 script runtime process/API integration |
| `pluginApi` shared state | service IPC and host-managed settings |

## Target feature parity

- Codex 5-hour and weekly remaining percentages.
- Full, usage-only, and icon-only bar modes.
- Both-window, primary-only, and secondary-only display modes.
- Native Noctalia panel with usage cards and reset times.
- Credits balance and available reset count.
- Expandable reset-credit list sorted by expiration.
- Manual refresh and configurable automatic refresh interval.
- Optional custom Codex executable path.
- Warning and critical presentation based on remaining usage.

## Initial work completed

- Created `plugin.toml` with v5 widget, panel, and service entries.
- Ported the existing settings schema to native v5 manifest fields.
- Added English setting translations.
- Preserved the v4 code on this branch temporarily as a behavioral reference.

## Current implementation task

The next step is the service bridge. The v4 helper already handles the Codex app-server JSONL protocol correctly. The v5 service must either:

1. invoke the existing Python helper through the v5 process API, then publish its JSON payload over plugin IPC; or
2. implement the app-server JSONL exchange directly in Luau if the runtime exposes the required subprocess and streaming primitives.

The widget and panel will consume the service payload over plugin IPC rather than owning separate Codex processes.

## Branch policy

- `main`: stable Noctalia v4/QML plugin.
- `noctalia-v5`: active native Noctalia v5 development.
- The default branch can move to `noctalia-v5` after the v5 plugin is installable and reaches feature parity.
