import QtQuick
import QtQuick.Layouts
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

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  readonly property string panelStyle: cfg.panelStyle ?? defaults.panelStyle ?? "full"
  readonly property string displayMode: cfg.displayMode ?? defaults.displayMode ?? "both"
  readonly property var payload: codexService?.payload ?? null
  readonly property string fetchState: codexService?.fetchState ?? "idle"
  readonly property string screenName: screen ? screen.name : ""
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isVerticalBar: barPosition === "left" || barPosition === "right"
  readonly property int capsuleSize: Style.getCapsuleHeightForScreen(screenName)

  function remaining(windowData) {
    if (!windowData || typeof windowData.usedPercent !== "number") return null;
    return Math.max(0, Math.min(100, 100 - windowData.usedPercent));
  }

  readonly property var primaryRemaining: remaining(payload?.rateLimits?.primary)
  readonly property var secondaryRemaining: remaining(payload?.rateLimits?.secondary)

  function valuesText() {
    if (fetchState === "error") return "!";
    if (!payload) return "…";
    if (displayMode === "primary") return primaryRemaining === null ? "—" : primaryRemaining + "%";
    if (displayMode === "secondary") return secondaryRemaining === null ? "—" : secondaryRemaining + "%";
    if (primaryRemaining !== null && secondaryRemaining !== null)
      return primaryRemaining + "% · " + secondaryRemaining + "%";
    if (primaryRemaining !== null) return primaryRemaining + "%";
    if (secondaryRemaining !== null) return secondaryRemaining + "%";
    return "—";
  }

  readonly property string panelText: panelStyle === "usage" ? valuesText() : "Codex " + valuesText()
  readonly property int lowestRemaining: {
    var values = [];
    if (primaryRemaining !== null) values.push(primaryRemaining);
    if (secondaryRemaining !== null) values.push(secondaryRemaining);
    return values.length ? Math.min.apply(Math, values) : 100;
  }
  readonly property color statusColor: {
    if (fetchState === "error" || lowestRemaining <= 10) return Color.mError;
    if (lowestRemaining <= 25) return Color.mTertiary;
    return Color.mOnSurface;
  }

  implicitWidth: contentLoader.item?.implicitWidth ?? 0
  implicitHeight: contentLoader.item?.implicitHeight ?? 0

  Loader {
    id: contentLoader
    anchors.fill: parent
    sourceComponent: root.panelStyle === "icon" ? iconComponent : textComponent
  }

  Component {
    id: textComponent
    BarPill {
      screen: root.screen
      oppositeDirection: BarService.getPillDirection(root)
      icon: ""
      text: root.panelText
      forceOpen: true
      autoHide: false
      customTextIconColor: root.statusColor
      tooltipText: "Codex usage"
      onClicked: root.togglePopup()
      onRightClicked: root.openContextMenu()
    }
  }

  Component {
    id: iconComponent
    Item {
      id: iconRoot
      property bool hovered: false
      implicitWidth: root.capsuleSize
      implicitHeight: root.capsuleSize
      width: root.isVerticalBar ? parent.width : implicitWidth
      height: root.isVerticalBar ? implicitHeight : parent.height

      Rectangle {
        id: iconBackground
        width: root.capsuleSize
        height: root.capsuleSize
        anchors.centerIn: parent
        radius: Style.radiusM
        color: iconRoot.hovered ? Color.mHover : Style.capsuleColor
        border.color: Style.capsuleBorderColor
        border.width: Style.capsuleBorderWidth
      }

      Image {
        id: sourceLogo
        visible: false
        source: Qt.resolvedUrl("icons/openai.svg")
        sourceSize.width: Math.round(root.capsuleSize * 0.50)
        sourceSize.height: Math.round(root.capsuleSize * 0.50)
        fillMode: Image.PreserveAspectFit
      }

      MultiEffect {
        anchors.centerIn: iconBackground
        width: Math.round(root.capsuleSize * 0.50)
        height: width
        source: sourceLogo
        colorization: 1.0
        colorizationColor: iconRoot.hovered ? Color.mOnHover : root.statusColor
      }

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: {
          iconRoot.hovered = true;
          TooltipService.show(iconRoot, "Codex usage", BarService.getTooltipDirection(root.screenName), Style.tooltipDelay);
        }
        onExited: {
          iconRoot.hovered = false;
          TooltipService.hide();
        }
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
    anchor.edges: {
      if (root.barPosition === "bottom") return Edges.Top | Edges.Right;
      if (root.barPosition === "left") return Edges.Right | Edges.Top;
      if (root.barPosition === "right") return Edges.Left | Edges.Top;
      return Edges.Bottom | Edges.Right;
    }
    anchor.gravity: {
      if (root.barPosition === "bottom") return Edges.Top | Edges.Left;
      if (root.barPosition === "left") return Edges.Right | Edges.Bottom;
      if (root.barPosition === "right") return Edges.Left | Edges.Bottom;
      return Edges.Bottom | Edges.Left;
    }
    anchor.adjustment: PopupAdjustment.Flip | PopupAdjustment.Slide
    anchor.margins: 8

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

  function togglePopup() {
    usagePopup.visible = !usagePopup.visible;
  }

  function openContextMenu() {
    PanelService.showContextMenu(contextMenu, root, screen);
  }

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
