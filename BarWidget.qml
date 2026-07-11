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

  property