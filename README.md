# Noctalia Codex Usage

A Noctalia bar plugin that shows the remaining OpenAI Codex usage for the 5-hour and weekly windows.

## Features

- Full, usage-only, and icon-only bar modes
- Both limits, 5-hour only, or weekly only
- Detailed panel with reset times, usage meters, credits, and free limit resets
- Automatic refresh with a configurable interval
- Manual refresh and a direct Preferences shortcut
- Automatic Codex CLI discovery, with an optional explicit executable path
- Uses the official local `codex app-server --stdio` protocol and does not read OAuth files directly

## Requirements

- Noctalia Shell 4.4 or newer with the QML plugin system
- Python 3
- OpenAI Codex CLI, logged into a ChatGPT account

Verify Codex first:

```bash
codex --version
codex login status
```

## Install

```bash
git clone https://github.com/aaronroquefonseca/noctalia-codex-usage.git
cd noctalia-codex-usage
bash install.sh
```

Then reload Noctalia, enable **Codex Usage**, and add it to the desired bar section. Noctalia controls whether a widget is placed on the left, center, or right side of the bar.

Manual installation is also supported by copying the repository contents to:

```text
~/.config/noctalia/plugins/codex-usage
```

## Settings

Open the plugin settings from Noctalia or from the panel's **Preferences** button.

Available options:

- Bar appearance: Codex and usage, usage only, or icon only
- Values: both windows, 5-hour only, or weekly only
- Refresh interval: 60–3600 seconds
- Optional explicit Codex executable path

## Test the helper

```bash
python3 ~/.config/noctalia/plugins/codex-usage/codex_usage.py --codex "$(command -v codex)"
```

A successful response starts with:

```json
{"ok":true,"account":...
```

## License

MIT
