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

  Layout.fillWidth: true
  Layout.preferredHeight: content.implicitHeight + Style.marginM * 2
  radius: Style.radiusM
  color: Color.mSurfaceVariant

  ColumnLayout {
    id: content
    anchors.fill: parent
    anchors.margins: Style.marginM
    spacing: Style.marginS

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginM

      NText {
        text: root.title
        pointSize: Style.fontSizeM
        font.weight: Font.DemiBold
        color: Color.mOnSurface
        Layout.fillWidth: true
        elide: Text.ElideRight
      }

      NText {
        text: root.remainingPercent < 0 ? "—" : root.remainingPercent + "%"
        pointSize: Style.fontSizeL
        font.weight: Font.DemiBold
        color: root.levelColor
        Layout.leftMargin: Style.marginM
      }
    }

    NText {
      text: root.resetText
      pointSize: Style.fontSizeS
      color: Color.mOnSurfaceVariant
      Layout.fillWidth: true
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginXS

      Repeater {
        model: 10
        delegate: Rectangle {
          required property int index
          Layout.fillWidth: true
          Layout.preferredHeight: Math.max(5, Math.round(5 * root.scale))
          radius: height / 2
          color: index < Math.ceil(Math.max(0, root.remainingPercent) / 10)
            ? root.levelColor
            : Color.mOutline
          opacity: index < Math.ceil(Math.max(0, root.remainingPercent) / 10) ? 1 : 0.35
        }
      }
    }
  }
}
