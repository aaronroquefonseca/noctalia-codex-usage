import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Rectangle {
  id: root

  property string title: "Usage window"
  property int remainingPercent: -1
  property string resetText: "Reset time unavailable"

  readonly property real scale: Style.uiScaleRatio
  readonly property color levelColor: remainingPercent >= 0 && remainingPercent <= 10
    ? Color.mError
    : (remainingPercent >= 0 && remainingPercent <= 25 ? Color.mTertiary : Color.mPrimary)

