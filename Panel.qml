import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root
  property var pluginApi: null
  readonly property var service: pluginApi?.mainInstance?.codexService || null
  readonly property var data: service?.payload ?? null
  readonly property var primary: data?.rateLimits?.primary ?? null
  readonly property var secondary: data?.rateLimits?.secondary ?? null

  property real contentPreferredWidth: 300
  property real contentPreferredHeight: body.implicitHeight + Style.marginM * 2
  implicitWidth: contentPreferredWidth
  implicitHeight: contentPreferredHeight

  function remaining(w) {
    return (!w || typeof w.usedPercent !== "number") ? -1 : Math.max(0, Math.min(100, 100 - w.usedPercent));
  }
  function windowName(mins) {
    if (!mins) return "Usage window";
    if (mins % 10080 === 0) return (mins / 10080) + "-week window";
    if (mins % 1440 === 0) return (mins / 1440) + "-day window";
    if (mins % 60 === 0) return (mins / 60) + "-hour window";
    return mins + "-minute window";
  }
  function resetText(epoch) {
    if (!epoch) return "Reset time unavailable";
    var d = Math.max(0, epoch - Math.floor(Date.now() / 1000));
    if (d < 60) return "Resets in less than a minute";
    if (d < 3600) return "Resets in " + Math.ceil(d / 60) + " min";
    if (d < 86400) {
      var h = Math.floor(d / 3600), m = Math.ceil((d % 3600) / 60);
      return "Resets in " + h + "h" + (m ? " " + m + "m" : "");
    }
    return "Resets " + new Date(epoch * 1000).toLocaleString(Qt.locale(), "ddd HH:mm");
  }
  function updatedText() {
    var d = service?.updatedAt;
    return (!d || d.getTime() === 0) ? "Not updated yet" : "Updated at " + d.toLocaleTimeString(Qt.locale(), "HH:mm");
  }
  function openPreferences() {
    if (!pluginApi?.panelOpenScreen || !pluginApi?.manifest) return;
    BarService.openPluginSettings(pluginApi.panelOpenScreen, pluginApi.manifest);
    pluginApi.closePanel(pluginApi.panelOpenScreen);
  }

  ColumnLayout {
    id: body
    anchors.fill: parent
    anchors.margins: Style.marginM
    spacing: Style.marginS

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginS
      Item {
        Layout.preferredWidth: Style.fontSizeL
        Layout.preferredHeight: Style.fontSizeL
        Image { id: logo; anchors.fill: parent; visible: false; source: Qt.resolvedUrl("icons/openai.svg") }
        MultiEffect { anchors.fill: parent; source: logo; colorization: 1; colorizationColor: Color.mPrimary }
      }
      NText { text: "Codex usage"; font.bold: true; Layout.fillWidth: true }
      NText { text: String(data?.rateLimits?.planType ?? ""); color: Color.mOnSurfaceVariant; font.pixelSize: Style.fontSizeXS }
    }

    NDivider { Layout.fillWidth: true }

    NText {
      visible: service?.fetchState === "error"
      text: service?.errorMessage || "Unable to read Codex usage"
      color: Color.mError
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }

    UsageCard {
      visible: primary !== null
      title: root.windowName(primary?.windowDurationMins)
      remainingPercent: root.remaining(primary)
      resetText: root.resetText(primary?.resetsAt)
    }
    UsageCard {
      visible: secondary !== null
      title: root.windowName(secondary?.windowDurationMins)
      remainingPercent: root.remaining(secondary)
      resetText: root.resetText(secondary?.resetsAt)
    }

    RowLayout {
      visible: data !== null
      Layout.fillWidth: true
      spacing: Style.marginS
      Rectangle {
        Layout.fillWidth: true; implicitHeight: 48; radius: Style.radiusM; color: Color.mSurfaceVariant
        Column { anchors.centerIn: parent; spacing: 1
          NText { text: data?.rateLimits?.credits?.unlimited ? "∞" : String(data?.rateLimits?.credits?.balance ?? "—"); font.bold: true }
          NText { text: "Credits"; font.pixelSize: Style.fontSizeXS; color: Color.mOnSurfaceVariant }
        }
      }
      Rectangle {
        Layout.fillWidth: true; implicitHeight: 48; radius: Style.radiusM; color: Color.mSurfaceVariant
        Column { anchors.centerIn: parent; spacing: 1
          NText { text: String(data?.resetCredits?.availableCount ?? "—"); font.bold: true }
          NText { text: "Limit resets"; font.pixelSize: Style.fontSizeXS; color: Color.mOnSurfaceVariant }
        }
      }
    }

    NDivider { Layout.fillWidth: true }
    NText { text: root.updatedText(); font.pixelSize: Style.fontSizeXS; color: Color.mOnSurfaceVariant }

    NButton {
      Layout.fillWidth: true
      text: "Preferences"
      icon: "settings"
      outlined: true
      onClicked: root.openPreferences()
    }
    NButton {
      Layout.fillWidth: true
      text: service?.fetchState === "loading" ? "Refreshing…" : "Refresh"
      icon: "refresh"
      enabled: service?.fetchState !== "loading"
      onClicked: service?.refresh()
    }
  }
}
