// card wrapping one command-center section; children land in an inner
// column pinned to the card's full width
import ".."
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: section

    default property alias content: secCol.data

    Layout.fillWidth: true
    radius: 6
    color: Qt.rgba(1, 1, 1, 0.05)
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.15)
    implicitHeight: secCol.implicitHeight + 16

    ColumnLayout {
        id: secCol

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 8
        }

        spacing: 8
    }

}
