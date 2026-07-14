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
  readonly property var payload: service?.payload ?? null
  readonly property var primary: payload?.rateLimits?.primary ?? null
  readonly property var secondary: payload?.rateLimits?.secondary ?? null
  readonly property real scale: Style.uiScaleRatio
  property bool resetsExpanded: false

  readonly property var availableResetCredits: {
    var summary = payload?.resetCredits;
    var source = summary?.credits;
    if (!Array.isArray(source)) return [];
    var available = [];
    for (var i = 0; i < source.length; i++) {
      var credit = source[i];
      if (String(credit?.status ?? "").toLowerCase() === "available")
        available.push(credit);
    }
    available.sort(function(a, b) {
      var aExpiry = a?.expiresAt ?? Number.MAX_SAFE_INTEGER;
      var bExpiry = b?.expiresAt ?? Number.MAX_SAFE_INTEGER;
      return aExpiry - bExpiry;
    });
    var count = Number(summary?.availableCount);
    if (!isFinite(count) || count < 0) count = available.length;
    return available.slice(0, count);
  }

  readonly property int availableResetCount: {
    var count = Number(payload?.resetCredits?.availableCount);
    return isFinite(count) && count >= 0 ? count : availableResetCredits.length;
  }

  property real contentPreferredWidth: 320 * scale
  property real contentPreferredHeight: body.implicitHeight + Style.marginL * 2
  implicitWidth: contentPreferredWidth
  implicitHeight: contentPreferredHeight

  function remaining(windowData) {
    return (!windowData || typeof windowData.usedPercent !== "number")
      ? -1 : Math.max(0, Math.min(100, 100 - windowData.usedPercent));
  }

  function windowName(minutes) {
    if (!minutes) return "Usage window";
    if (minutes % 10080 === 0) return (minutes / 10080) + "-week window";
    if (minutes % 1440 === 0) return (minutes / 1440) + "-day window";
    if (minutes % 60 === 0) return (minutes / 60) + "-hour window";
    return minutes + "-minute window";
  }

  function resetText(epoch) {
    if (!epoch) return "Reset time unavailable";
    var delta = Math.max(0, epoch - Math.floor(Date.now() / 1000));
    if (delta < 60) return "Resets in less than a minute";
    if (delta < 3600) return "Resets in " + Math.ceil(delta / 60) + " min";
    if (delta < 86400) {
      var hours = Math.floor(delta / 3600);
      var mins = Math.ceil((delta % 3600) / 60);
      return "Resets in " + hours + "h" + (mins ? " " + mins + "m" : "");
    }
    return "Resets " + new Date(epoch * 1000).toLocaleString(Qt.locale(), "ddd HH:mm");
  }

  function resetTitle(credit) {
    var title = String(credit?.title ?? "").trim();
    return title.length > 0 ? title : "Full reset";
  }

  function resetExpiration(epoch) {
    if (epoch === null || epoch === undefined) return "Does not expire";
    var date = new Date(Number(epoch) * 1000);
    if (isNaN(date.getTime())) return "Expiration unavailable";
    return "Expires " + date.toLocaleTimeString(Qt.locale(), "HH:mm")
      + " on " + date.toLocaleDateString(Qt.locale(), "d MMM yyyy");
  }

  function resetSummaryText() {
    if (availableResetCount === 1) return "1 usage limit reset available.";
    return availableResetCount + " usage limit resets available.";
  }

  function updatedText() {
    var date = service?.updatedAt;
    return (!date || date.getTime() === 0)
      ? "Not updated yet"
      : "Updated at " + date.toLocaleTimeString(Qt.locale(), "HH:mm");
  }

  function openPreferences() {
    if (!pluginApi?.panelOpenScreen || !pluginApi?.manifest) return;
    BarService.openPluginSettings(pluginApi.panelOpenScreen, pluginApi.manifest);
    pluginApi.closePanel(pluginApi.panelOpenScreen);
  }

  ColumnLayout {
    id: body
    anchors.fill: parent
    anchors.margins: Style.marginL
    spacing: Style.marginM

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginM

      Item {
        Layout.preferredWidth: 22 * root.scale
        Layout.preferredHeight: 22 * root.scale
        Image {
          id: logo
          anchors.fill: parent
          visible: false
          source: Qt.resolvedUrl("icons/openai.svg")
          fillMode: Image.PreserveAspectFit
        }
        MultiEffect {
          anchors.fill: parent
          source: logo
          colorization: 1
          colorizationColor: Color.mPrimary
        }
      }

      NText {
        text: "Codex usage"
        pointSize: Style.fontSizeL
        font.weight: Font.DemiBold
        color: Color.mOnSurface
        Layout.fillWidth: true
      }

      NText {
        text: String(payload?.rateLimits?.planType ?? "")
        pointSize: Style.fontSizeS
        color: Color.mOnSurfaceVariant
      }
    }

    NDivider { Layout.fillWidth: true }

    NText {
      visible: service?.fetchState === "error"
      text: service?.errorMessage || "Unable to read Codex usage"
      pointSize: Style.fontSizeS
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
      visible: payload !== null
      Layout.fillWidth: true
      spacing: Style.marginM

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 58 * root.scale
        radius: Style.radiusM
        color: Color.mSurfaceVariant
        ColumnLayout {
          anchors.centerIn: parent
          spacing: 0
          NText {
            text: payload?.rateLimits?.credits?.unlimited ? "∞" : String(payload?.rateLimits?.credits?.balance ?? "—")
            pointSize: Style.fontSizeM
            font.weight: Font.DemiBold
          }
          NText { text: "Credits"; pointSize: Style.fontSizeS; color: Color.mOnSurfaceVariant }
        }
      }

      Rectangle {
        id: resetCard
        Layout.fillWidth: true
        Layout.preferredHeight: 58 * root.scale
        radius: Style.radiusM
        color: resetMouse.containsMouse ? Color.mHover : Color.mSurfaceVariant
        ColumnLayout {
          anchors.centerIn: parent
          spacing: 0
          NText {
            text: String(root.availableResetCount)
            pointSize: Style.fontSizeM
            font.weight: Font.DemiBold
            color: resetMouse.containsMouse ? Color.mOnHover : Color.mOnSurface
          }
          NText {
            text: "Limit resets"
            pointSize: Style.fontSizeS
            color: resetMouse.containsMouse ? Color.mOnHover : Color.mOnSurfaceVariant
          }
        }
        NIcon {
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: Style.marginS
          icon: root.resetsExpanded ? "chevron-down" : "chevron-right"
          pointSize: Style.fontSizeXS
          color: resetMouse.containsMouse ? Color.mOnHover : Color.mOnSurfaceVariant
        }
        MouseArea {
          id: resetMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.resetsExpanded = !root.resetsExpanded
        }
      }
    }

    ColumnLayout {
      visible: payload !== null && root.resetsExpanded
      Layout.fillWidth: true
      spacing: Style.marginS

      NText {
        text: root.resetSummaryText()
        pointSize: Style.fontSizeS
        font.weight: Font.DemiBold
        color: Color.mOnSurface
        Layout.fillWidth: true
      }

      Repeater {
        model: root.availableResetCredits
        delegate: Rectangle {
          id: resetCreditCard
          property var credit: modelData
          Layout.fillWidth: true
          Layout.preferredHeight: resetDetail.implicitHeight + Style.marginM * 2
          radius: Style.radiusM
          color: Color.mSurfaceVariant
          ColumnLayout {
            id: resetDetail
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginXS
            NText {
              text: root.resetTitle(resetCreditCard.credit)
              pointSize: Style.fontSizeM
              font.weight: Font.DemiBold
              color: Color.mOnSurface
              Layout.fillWidth: true
              wrapMode: Text.WordWrap
            }
            NText {
              text: root.resetExpiration(resetCreditCard.credit?.expiresAt)
              pointSize: Style.fontSizeS
              color: Color.mOnSurfaceVariant
              Layout.fillWidth: true
            }
          }
        }
      }

      NText {
        visible: root.availableResetCount === 0
        text: "You don't have any usage limit resets available."
        pointSize: Style.fontSizeS
        color: Color.mOnSurfaceVariant
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
      }

      NText {
        visible: root.availableResetCount > root.availableResetCredits.length
        text: "Some reset expiration details are unavailable."
        pointSize: Style.fontSizeS
        color: Color.mOnSurfaceVariant
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
      }
    }

    NDivider { Layout.fillWidth: true }

    NText { text: root.updatedText(); pointSize: Style.fontSizeS; color: Color.mOnSurfaceVariant }

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
