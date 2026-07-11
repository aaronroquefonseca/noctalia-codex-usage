import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  spacing: Style.marginM

  NHeader {
    label: "Codex Usage"
    Layout.fillWidth: true
  }

  NDivider {}

  NLabel {
    label: "Bar appearance"
  }

  NText {
    text: "Choose how much space the widget uses in the bar."
    color: Color.mOnSurfaceVariant
    pointSize: Style.fontSizeXS
    Layout.fillWidth: true
    wrapMode: Text.WordWrap
  }

  NComboBox {
    Layout.fillWidth: true
    model: [
      { key: "full", name: "Codex and usage" },
      { key: "usage", name: "Usage only" },
      { key: "icon", name: "Icon only" }
    ]
    currentKey: cfg.panelStyle ?? defaults.panelStyle
    onSelected: function(key) {
      cfg.panelStyle = key;
      pluginApi?.saveSettings();
    }
  }

  NLabel {
    label: "Usage values"
  }

  NText {
    text: "The percentages shown are the amounts remaining."
    color: Color.mOnSurfaceVariant
    pointSize: Style.fontSizeXS
    Layout.fillWidth: true
    wrapMode: Text.WordWrap
  }

  NComboBox {
    Layout.fillWidth: true
    enabled: (cfg.panelStyle ?? defaults.panelStyle) !== "icon"
    model: [
      { key: "both", name: "Both windows" },
      { key: "primary", name: "5-hour window" },
      { key: "secondary", name: "Weekly window" }
    ]
    currentKey: cfg.displayMode ?? defaults.displayMode
    onSelected: function(key) {
      cfg.displayMode = key;
      pluginApi?.saveSettings();
    }
  }

  NDivider {}

  NLabel {
    label: "Refresh interval"
  }

  NSpinBox {
    from: 60
    to: 3600
    suffix: "s"
    value: cfg.refreshIntervalSeconds ?? defaults.refreshIntervalSeconds
    onValueModified: {
      cfg.refreshIntervalSeconds = value;
      pluginApi?.saveSettings();
    }
  }

  NLabel {
    label: "Codex executable path"
  }

  NText {
    text: "Leave blank to detect Codex automatically. Example: /usr/bin/codex"
    color: Color.mOnSurfaceVariant
    pointSize: Style.fontSizeXS
    Layout.fillWidth: true
    wrapMode: Text.WordWrap
  }

  NTextInput {
    Layout.fillWidth: true
    text: cfg.codexPath ?? defaults.codexPath
    placeholderText: "/usr/bin/codex"
    onEditingFinished: {
      cfg.codexPath = text.trim();
      pluginApi?.saveSettings();
    }
  }

  NText {
    text: "The widget position is controlled by Noctalia's bar layout. Move Codex Usage to the left, center, or right section there."
    color: Color.mOnSurfaceVariant
    pointSize: Style.fontSizeXS
    Layout.fillWidth: true
    wrapMode: Text.WordWrap
    Layout.topMargin: Style.marginS
  }
}
