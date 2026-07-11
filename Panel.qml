import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  readonly property var codexService: pluginApi?.mainInstance?.codexService || null
  readonly property var payload: codexService?.payload ?? null
  readonly property string fetchState: codexService?.fetchState ?? "idle"
  readonly