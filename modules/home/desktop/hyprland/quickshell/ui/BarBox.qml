// rounded group box: lays its children out in a centered row inside a
// slightly rounded outline — border only, no fill (the bar background
// shows through); `interactive` boxes get a faint tint fill on hover
// (same treatment as the workspace pills). `tint` colors the border
// (and the hover fill).
import ".."
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: box

    default property alias content: boxRow.data
    property bool interactive: false
    property color tint: "white"

    Layout.preferredHeight: Theme.barHeight - 8
    Layout.alignment: Qt.AlignVCenter
    Layout.leftMargin: 3
    Layout.rightMargin: 3
    implicitWidth: boxRow.implicitWidth + 20
    radius: 6
    color: interactive && boxHover.hovered ? Qt.alpha(tint, 0.10) : "transparent"
    border.width: 1
    border.color: Qt.alpha(tint, interactive && boxHover.hovered ? 0.55 : 0.35)

    Behavior on color {
        ColorAnimation {
            duration: 150
        }

    }

    HoverHandler {
        id: boxHover

        cursorShape: interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    RowLayout {
        id: boxRow

        anchors {
            fill: parent
            leftMargin: 10
            rightMargin: 10
        }

        spacing: 5
    }

}
