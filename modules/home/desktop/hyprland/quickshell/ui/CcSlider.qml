// themed slider: thin accent track over a dim groove, round handle
import ".."
import QtQuick
import QtQuick.Controls

Slider {
    id: ccSlider

    implicitHeight: 22

    background: Rectangle {
        x: ccSlider.leftPadding
        y: ccSlider.topPadding + (ccSlider.availableHeight - height) / 2
        width: ccSlider.availableWidth
        height: 4
        radius: 2
        color: Qt.alpha(Theme.col16, 0.15)

        Rectangle {
            width: ccSlider.visualPosition * parent.width
            height: parent.height
            radius: 2
            color: Theme.col16
        }

    }

    handle: Rectangle {
        x: ccSlider.leftPadding + ccSlider.visualPosition * (ccSlider.availableWidth - width)
        y: ccSlider.topPadding + (ccSlider.availableHeight - height) / 2
        width: 12
        height: 12
        radius: 6
        color: Theme.col15
        border.width: 1
        border.color: Theme.colBg
    }

}
