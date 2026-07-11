import QtQuick
import QtQuick.Effects
import Quickshell
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  property var codexService: pluginApi?.mainInstance?.codexService || null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""

  readonly property var cfg: pluginApi?.pluginSettings || ({})
  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
  readonly property string panelStyle: cfg.panelStyle ?? defaults.panelStyle ?? "full"
  readonly property string displayMode: cfg.displayMode ?? defaults.displayMode ?? "both"
  readonly property var payload: codexService?.payload ?? null
  readonly property string fetchState: codexService?.fetchState ?? "idle"
  readonly property string screenName: screen ? screen.name : ""
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool verticalBar: barPosition === "left" || barPosition === "right"
  readonly property int capsuleSize: Style.getCapsuleHeightForScreen(screenName)

  function remaining(windowData) {
    if (!windowData || typeof windowData.usedPercent !== "number") return null;
    return Math.max(0, Math.min(100, 100 - windowData.usedPercent));
  }

  readonly property var primary: remaining(payload?.rateLimits?.primary)
  readonly property var secondary: remaining(payload?.rateLimits?.secondary)

  function usageText() {
    if (fetchState === "error") return "!";
    if (!payload) return "…";
    if (displayMode === "primary") return primary === null ? "—" : primary + "%";
    if (displayMode === "secondary") return secondary === null ? "—" : secondary + "%";
    if (primary !== null && secondary !== null) return primary + "% · " + secondary + "%";
    return primary !== null ? primary + "%" : (secondary !== null ? secondary + "%" : "—");
  }

  readonly property int lowest: {
    var values = [];
    if (primary !== null) values.push(primary);
    if (secondary !== null) values.push(secondary);
    return values.length ? Math.min.apply(Math, values) : 100;
  }

  readonly property color statusColor: fetchState === "error" || lowest <= 10
    ? Color.mError : (lowest <= 25 ? Color.mTertiary : Color.mOnSurface)

  implicitWidth: content.item?.implicitWidth ?? 0
  implicitHeight: content.item?.implicitHeight ?? 0

  Loader {
    id: content
    anchors.fill: parent
    sourceComponent: root.panelStyle === "icon" ? iconMode : textMode
  }

  Component {
    id: textMode
    BarPill {
      screen: root.screen
      oppositeDirection: BarService.getPillDirection(root)
      icon: ""
      text: root.panelStyle === "usage" ? root.usageText() : "Codex " + root.usageText()
      forceOpen: true
      autoHide: false
      customTextIconColor: root.statusColor
      tooltipText: "Codex usage"
      onClicked: root.togglePopup()
      onRightClicked: root.openContextMenu()
    }
  }

  Component {
    id: iconMode
    Item {
      implicitWidth: root.capsuleSize
      implicitHeight: root.capsuleSize
      width: root.verticalBar ? parent.width : implicitWidth
      height: root.verticalBar ? implicitHeight : parent.height

      Rectangle {
        id: iconBg
        anchors.centerIn: parent
        width: root.capsuleSize
        height: root.capsuleSize
        radius: Style.radiusM
        color: iconMouse.containsMouse ? Color.mHover : Style.capsuleColor
        border.color: Style.capsuleBorderColor
        border.width: Style.capsuleBorderWidth
      }

      Image {
        id: logo
        visible: false
        source: Qt.resolvedUrl("icons/openai.svg")
        sourceSize.width: Math.round(root.capsuleSize * 0.5)
        sourceSize.height: sourceSize.width
      }

      MultiEffect {
        anchors.centerIn: iconBg
        width: Math.round(root.capsuleSize * 0.5)
        height: width
        source: logo
        colorization: 1
        colorizationColor: iconMouse.containsMouse ? Color.mOnHover : root.statusColor
      }

      MouseArea {
        id: iconMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: function(mouse) {
          if (mouse.button === Qt.RightButton) root.openContextMenu();
          else root.togglePopup();
        }
      }
    }
  }

  PopupWindow {
    id: usagePopup
    visible: false
    grabFocus: true
    color: "transparent"
    width: popupContent.implicitWidth
    height: popupContent.implicitHeight

    anchor.item: root
    anchor.adjustment: PopupAdjustment.Flip | PopupAdjustment.Slide
    anchor.edges: root.barPosition === "bottom" ? Edges.Top
      : root.barPosition === "left" ? Edges.Right
      : root.barPosition === "right" ? Edges.Left
      : Edges.Bottom
    anchor.gravity: anchor.edges
    anchor.margins.top: root.barPosition === "top" ? 8 : 0
    anchor.margins.bottom: root.barPosition === "bottom" ? 8 : 0
    anchor.margins.left: root.barPosition === "left" ? 8 : 0
    anchor.margins.right: root.barPosition === "right" ? 8 : 0
    anchor.rect.x: root.verticalBar ? 0 : root.width / 2 - width / 2 - (root.section === "right" ? 24 : root.section === "left" ? -24 : 0)
    anchor.rect.y: root.verticalBar ? root.height / 2 - height / 2 : 0

    Panel {
      id: popupContent
      anchors.fill: parent
      pluginApi: root.pluginApi
      codexService: root.codexService
      screen: root.screen
      onRequestClose: usagePopup.visible = false
      onRequestPreferences: {
        usagePopup.visible = false;
        BarService.openPluginSettings(root.screen, root.pluginApi.manifest);
      }
    }
  }

  function togglePopup() { usagePopup.visible = !usagePopup.visible; }
  function openContextMenu() { PanelService.showContextMenu(contextMenu, root, screen); }

  NPopupContextMenu {
    id: contextMenu
    model: [
      {"label": "Refresh", "action": "refresh", "icon": "refresh"},
      {"label": "Settings", "action": "settings", "icon": "settings"}
    ]
    onTriggered: function(action) {
      contextMenu.close();
      PanelService.closeContextMenu(screen);
      if (action === "refresh") codexService?.refresh();
      else if (action === "settings") BarService.openPluginSettings(root.screen, pluginApi.manifest);
    }
  }
}
