import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Rectangle {
  id: root

  property string title: "Usage window"
  property int remainingPercent: -1
  property string resetText: "Reset time unavailable"

  readonly property color levelColor: {
    if (remainingPercent >= 0 && remainingPercent <= 10)
      return Color.mError;
    if (remainingPercent >= 0 && remainingPercent <= 25)
      return Color.mTertiary;
    return Color.mPrimary;
  }

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
        font.pixelSize: Style.fontSizeM
        font.bold: true
        color: Color.mOnSurface
        Layout.fillWidth: true
        elide: Text.ElideRight
      }

      NText {
        text: root.remainingPercent < 0 ? "—" : root.remainingPercent + "%"
        font.pixelSize: Style.fontSizeL
        font.bold: true
        color: root.levelColor
        Layout.leftMargin: Style.marginM
      }
    }

    NText {
      text: root.resetText
      font.pixelSize: Style.fontSizeS
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
          Layout.preferredHeight: 5
          radius: height / 2
          color: {
            var filled = root.remainingPercent < 0 ? 0 : Math.ceil(root.remainingPercent / 10);
            return index < filled ? root.levelColor : Color.mOutline;
          }
          opacity: index < Math.ceil(Math.max(0, root.remainingPercent) / 10) ? 1.0 : 0.35
        }
      }
    }
  }
}
