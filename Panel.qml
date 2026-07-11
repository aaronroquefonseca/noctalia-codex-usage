import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs.Commons
import qs.Widgets

Rectangle {
  id: root

  property var pluginApi: null
  property var codexService: null
  property ShellScreen screen

  signal requestPreferences()
  signal requestClose()

  readonly property var payload: codexService?.payload ?? null
  readonly property string fetchState: codexService?.fetchState ?? "idle"
  readonly property string errorMessage: codexService?.errorMessage ?? ""
  readonly property var primaryWindow: payload?.rateLimits?.primary ?? null
  readonly property var secondaryWindow: payload?.rateLimits?.secondary ?? null

  function remaining(windowData) {
    if (!windowData || typeof windowData.usedPercent !== "number")
      return -1;
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
    if (!epochSeconds)
      return "Reset time unavailable";

    var now = Math.floor(Date.now() / 1000);
    var delta = Math.max(0, epochSeconds - now);
    if (delta < 60)
      return "Resets in less than a minute";
    if (delta < 3600)
      return "Resets in " + Math.ceil(delta / 60) + " min";
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
    if (!date || date.getTime() === 0)
      return "Not updated yet";
    return "Updated at " + date.toLocaleTimeString(Qt.locale(), "HH:mm");
  }

  implicitWidth: 350
  implicitHeight: contentColumn.implicitHeight + Style.marginM * 2
  radius: Style.radiusL
  color: Color.mSurface
  border.color: Color.mOutline
  border.width: 1
  clip: true

  ColumnLayout {
    id: contentColumn
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: Style.marginM
    spacing: Style.marginS

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      Item {
        Layout.preferredWidth: Style.fontSizeL
        Layout.preferredHeight: Style.fontSizeL

        Image {
          id: panelLogoSource
          anchors.fill: parent
          visible: false
          source: Qt.resolvedUrl("icons/openai.svg")
          fillMode: Image.PreserveAspectFit
        }

        MultiEffect {
          anchors.fill: parent
          source: panelLogoSource
          colorization: 1.0
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

    NDivider {}

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
        Layout.preferredHeight: creditsColumn.implicitHeight + Style.marginS * 2
        radius: Style.radiusM
        color: Color.mSurfaceVariant

        ColumnLayout {
          id: creditsColumn
          anchors.fill: parent
          anchors.margins: Style.marginS
          spacing: 0

          NText {
            text: root.payload?.rateLimits?.credits?.unlimited
              ? "∞"
              : String(root.payload?.rateLimits?.credits?.balance ?? "—")
            font.pixelSize: Style.fontSizeM
            font.bold: true
            color: Color.mOnSurface
          }

          NText {
            text: "Credits"
            font.pixelSize: Style.fontSizeXS
            color: Color.mOnSurfaceVariant
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: resetsColumn.implicitHeight + Style.marginS * 2
        radius: Style.radiusM
        color: Color.mSurfaceVariant

        ColumnLayout {
          id: resetsColumn
          anchors.fill: parent
          anchors.margins: Style.marginS
          spacing: 0

          NText {
            text: String(root.payload?.resetCredits?.availableCount ?? "—")
            font.pixelSize: Style.fontSizeM
            font.bold: true
            color: Color.mOnSurface
          }

          NText {
            text: "Limit resets"
            font.pixelSize: Style.fontSizeXS
            color: Color.mOnSurfaceVariant
          }
        }
      }
    }

    NDivider {}

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      NText {
        text: root.updatedText()
        font.pixelSize: Style.fontSizeXS
        color: Color.mOnSurfaceVariant
        Layout.fillWidth: true
      }

      NButton {
        text: "Preferences"
        icon: "settings"
        outlined: true
        onClicked: root.requestPreferences()
      }

      NButton {
        text: root.fetchState === "loading" ? "Refreshing…" : "Refresh"
        icon: "refresh"
        enabled: root.fetchState !== "loading"
        onClicked: root.codexService?.refresh()
      }
    }
  }
}
