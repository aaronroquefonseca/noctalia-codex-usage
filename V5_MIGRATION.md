# Noctalia v5 migration

This branch is the native, Quickshell-free Noctalia v5 port. The `main` branch remains the Noctalia v4/QML implementation.

## Architecture

| Noctalia v4 | Noctalia v5 |
| --- | --- |
| `manifest.json` | `plugin.toml` |
| `Main.qml` background process | `v5/service.luau` |
| `BarWidget.qml` | `v5/widget.luau` |
| `Panel.qml` | `v5/panel.luau` |
| `Settings.qml` | manifest-declared settings |
| `pluginApi` shared state | `noctalia.state` |

## Implemented

- Persistent native service invoking the proven `codex_usage.py` helper.
- Shared state between service, bar widget, and panel.
- 5-hour and weekly remaining percentages.
- Full, usage-only, and icon-only bar modes.
- Both-window, primary-only, and secondary-only display modes.
- Native usage cards, meters, reset times, credits, and errors.
- Expandable available reset-credit list sorted by expiration.
- Manual refresh from the panel and bar right-click.
- Configurable automatic refresh interval and Codex executable path.
- Native Noctalia v5 manifest and generated settings interface.
- v5 data-directory installer with manifest validation and `noctalia plugins lint`.

## Install

```bash
git clone --branch noctalia-v5 --single-branch \
  https://github.com/aaronroquefonseca/noctalia-codex-usage.git
cd noctalia-codex-usage
bash install.sh
```

Then restart Noctalia, enable `aaronroquefonseca/codex-usage`, and add its `bar` widget.

## Branch policy

- `main`: stable Noctalia v4/QML plugin.
- `noctalia-v5`: native Noctalia v5 implementation.
- The default branch can move after real-system validation and any resulting compatibility fixes.