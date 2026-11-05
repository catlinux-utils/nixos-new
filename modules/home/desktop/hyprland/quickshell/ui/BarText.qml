// bold value text, vertically centered
import ".."
import QtQuick
import QtQuick.Layouts

Text {
    color: Theme.col15
    font.pixelSize: Theme.fontSize
    font.family: Theme.fontFamily
    font.bold: true
    Layout.alignment: Qt.AlignVCenter
    verticalAlignment: Text.AlignVCenter

    Behavior on color {
        ColorAnimation {
            duration: 150
        }

    }

}
