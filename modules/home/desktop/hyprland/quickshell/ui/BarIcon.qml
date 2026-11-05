// accent-tinted icon glyph, vertically centered (color overridable per instance)
import ".."
import QtQuick
import QtQuick.Layouts

Text {
    color: Theme.col11
    font.family: Theme.iconFont
    font.pixelSize: Theme.iconSize
    Layout.alignment: Qt.AlignVCenter
    verticalAlignment: Text.AlignVCenter

    Behavior on color {
        ColorAnimation {
            duration: 150
        }

    }

}
