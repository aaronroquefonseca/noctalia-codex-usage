import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  property var codexService: pluginApi?.mainInstance?.codexService || null

  readonly property var payload: codexService?.payload ?? null
  readonly property string fetchState: codexService?.fetchState ?? "idle"
  readonly property string errorMessage: codexService?.errorMessage ?? ""
  readonly property var primaryWindow: payload?.rateLimits?.primary ?? null
  readonly property var secondaryWindow: payload?.rateLimits?.secondary ?? null

  property real contentPreferredWidth: 330
  property real contentPreferredHeight: contentColumn.implicitHeight + Style.marginM * 2
  implicitWidth: contentPreferredWidth
  implicitHeight: contentPreferredHeight

  function remaining(windowData) {
    if (!windowData || typeof windowData.usedPercent !== "number") return -1;
    return Math.max(0, Math.min(100, 100 - windowData.usedPercent));
  }

  function windowName(minutes) {
    if (!minutes) return "Usage window";
    if (minutes % 10080 === 0) return (minutes / 10080) + "-week window";
    if (minutes % 1440 === 0) return (minutes / 1440) + "-day window";
    if (minutes % 60 === 0) return (minutes / 60) + "-hour window";
    return minutes + "-minute window";
  }

  function resetText(epochSeconds) {
    if (!epochSeconds) return "Reset time unavailable";
    var delta = Math.max(0, epochSeconds - Math.floor(Date.now() / 1000));
    if (delta < 60) return "Resets in less than a minute";
    if (delta < 3600) return "Resets in " + Math.ceil(delta / 60) + " min";
    if (delta < 86400) {
      var hours = Math.floor(delta / 3600);
      var mins = Math.ceil((delta % 3600) / 60);
      return "Resets in " + hours + "h" + (mins ? " " + mins + "m" : "");
    }
    return "Resets " + new Date(epochSeconds * 1000).toLocaleString(Qt.locale(), "ddd HH:mm");
  }

  function planName() {
    var plan = payload?.rateLimits?.planType || payload?.account?.planType || "Unknown";
    plan = String(plan).replaceAll("_", " ");
    return plan.charAt(0).toUpperCase() + plan.slice(1);
  }

  function updatedText() {
    var date = codexService?.updatedAt;
    if (!date || date.getTime() === 0) return "Not updated yet";
    return "Updated at " + date.toLocaleTimeString(Qt.locale(), "HH:mm");
  }

  ColumnLayout {
    id: contentColumn
    anchors.fill: parent
    anchors.margins: Style.marginM
    spacing: Style.marginS

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      Item {
        Layout.preferredWidth: Style.fontSizeL
        Layout.preferredHeight: Style.fontSizeL

        Image {
          id: logoSource
          anchors.fill: parent
          visible: false
          source: Qt.resolvedUrl("icons/openai.svg")
          fillMode: Image.PreserveAspectFit
        }

        MultiEffect {
          anchors.fill: parent
          source: logoSource
          colorization: 1
          colorizationColor: Color.mPrimary
        }
      }

      NText {
        text: "Codex usage"
        font.pixelSize: Style.fontSizeM
        font.bold: true
        color: Color.mOnSurface
        Layout.fillWidth: true
      }

      Rectangle {
        Layout.preferredWidth: planLabel.implicitWidth + Style.marginS * 2
        Layout.preferredHeight: planLabel.implicitHeight + Style.marginXXS * 2
        radius: height / 2
        color: Color.mSurfaceVariant

        NText {
          id: planLabel
          anchors.centerIn: parent
          text: root.planName()
          font.pixelSize: Style.fontSizeXS
          font.bold: true
          color: Color.mOnSurfaceVariant
        }
      }
    }

    NDivider { Layout.fillWidth: true }

    NText {
      visible: root.fetchState === "loading" && !root.payload
      text: "Reading Codex usage…"
      color: Color.mOnSurfaceVariant
      Layout.fillWidth: true
      horizontalAlignment: Text.AlignHCenter
    }

    NText {
      visible: root.fetchState === "error"
      text: root.errorMessage || "Unable to read Codex usage"
      color: Color.mError
      Layout.fillWidth: true
      wrapMode: Text.WordWrap
    }

    UsageCard {
      visible: root.primaryWindow !== null
      title: root.windowName(root.primaryWindow?.windowDurationMins)
      remainingPercent: root.remaining(root.primaryWindow)
      resetText: root.resetText(root.primaryWindow?.resetsAt)
    }

    UsageCard {
      visible: root.secondaryWindow !== null
      title: root.windowName(root.secondaryWindow?.windowDurationMins)
      remainingPercent: root.remaining(root.secondaryWindow)
      resetText: root.resetText(root.secondaryWindow?.resetsAt)
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginS
      visible: root.payload !== null

      Rectangle {
        Layout.fillWidth: true
        implicitHeight: credits.implicitHeight + Style.marginS * 2
        radius: Style.radiusM
        color: Color.mSurfaceVariant
        ColumnLayout {
          id: credits
          anchors.fill: parent
          anchors.margins: Style.marginS
          spacing: 0
          NText {
            text: root.payload?.rateLimits?.credits?.unlimited ? "∞" : String(root.payload?.rateLimits?.credits?.balance ?? "—")
            font.pixelSize: Style.fontSizeM
            font.bold: true
          }
          NText { text: "Credits"; font.pixelSize: Style.fontSizeXS; color: Color.mOnSurfaceVariant }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        implicitHeight: resets.implicitHeight + Style.marginS * 2
        radius: Style.radiusM
        color: Color.mSurfaceVariant
        ColumnLayout {
          id: resets
          anchors.fill: parent
          anchors.margins: Style.marginS
          spacing: 0
          NText {
            text: String(root.payload?.resetCredits?.availableCount ?? "—")
            font.pixelSize: Style.fontSizeM
            font.bold: true
          }
          NText { text: "Limit resets"; font.pixelSize: Style.fontSizeXS; color: Color.mOnSurfaceVariant }
        }
      }
    }

    NDivider { Layout.fillWidth: true }

    NText {
      text: root.updatedText()
      font.pixelSize: Style.fontSizeXS
      color: Color.mOnSurfaceVariant
      Layout.fillWidth: true
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      NButton {
        Layout.fillWidth: true
        text: "Preferences"
        icon: "settings"
        outlined: true
        onClicked: BarService.openPluginSettings(pluginApi.panelOpenScreen, pluginApi.manifest)
      }

      NButton {
        Layout.fillWidth: true
        text: root.fetchState === "loading" ? "Refreshing…" : "Refresh"
        icon: "refresh"
        enabled: root.fetchState !== "loading"
        onClicked: root.codexService?.refresh()
      }
    }
  }
}
