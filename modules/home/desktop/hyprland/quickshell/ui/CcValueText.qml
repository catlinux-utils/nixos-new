// right-aligned dim value readout next to a slider
import ".."
import QtQuick
import QtQuick.Layouts

Text {
    color: Theme.col5
    font.pixelSize: Theme.fontSize - 1
    font.family: Theme.fontFamily
    Layout.preferredWidth: 34
    horizontalAlignment: Text.AlignRight
    verticalAlignment: Text.AlignVCenter
}
