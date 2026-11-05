// command center: calendar card — month navigation, weekday header and a
// 42-cell Monday-first month grid; own clock + month state
import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../ui"

CcSection {
    id: calendarSection

    property date month: {
        var n = new Date();
        return new Date(n.getFullYear(), n.getMonth(), 1);
    }
    readonly property var cells: Utils.calendarCells(month)
    readonly property var weekdays: {
        var names = [];
        for (var i = 0; i < 7; i++)
            names.push(Qt.locale().standaloneDayName((i + 1) % 7, Locale.ShortFormat));
        return names;
    }

    SystemClock {
        id: calClock

        precision: SystemClock.Seconds
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        CcButton {
            glyph: "‹"
            name: "Previous month"
            onActivate: () => calendarSection.month = new Date(calendarSection.month.getFullYear(), calendarSection.month.getMonth() - 1, 1)
        }

        Item {
            Layout.fillWidth: true
        }

        Text {
            text: Qt.locale().standaloneMonthName(calendarSection.month.getMonth(), Locale.LongFormat) + " " + calendarSection.month.getFullYear()
            color: Theme.col14
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
            font.bold: true

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: calendarSection.month = new Date(calClock.date.getFullYear(), calClock.date.getMonth(), 1)
            }

        }

        Item {
            Layout.fillWidth: true
        }

        CcButton {
            glyph: "›"
            name: "Next month"
            onActivate: () => calendarSection.month = new Date(calendarSection.month.getFullYear(), calendarSection.month.getMonth() + 1, 1)
        }

    }

    Row {
        Layout.alignment: Qt.AlignHCenter
        spacing: 2

        Repeater {
            model: calendarSection.weekdays

            Item {
                width: 40
                height: 20

                Text {
                    anchors.centerIn: parent
                    text: modelData
                    color: Theme.col3
                    font.pixelSize: Theme.fontSize - 1
                    font.family: Theme.fontFamily
                }

            }

        }

    }

    Grid {
        Layout.alignment: Qt.AlignHCenter
        columns: 7
        spacing: 2

        Repeater {
            model: calendarSection.cells

            Item {
                id: ccDay

                readonly property bool isToday: !modelData.other && new Date(calendarSection.month.getFullYear(), calendarSection.month.getMonth(), modelData.day).toDateString() === calClock.date.toDateString()

                width: 40
                height: 24

                Rectangle {
                    anchors.fill: parent
                    radius: 5
                    color: ccDay.isToday ? Qt.alpha(Theme.col16, 0.40) : "transparent"
                }

                Text {
                    anchors.centerIn: parent
                    text: modelData.day
                    color: modelData.other ? Theme.col3 : (ccDay.isToday ? Theme.col15 : Theme.col14)
                    font.pixelSize: Theme.fontSize - 1
                    font.family: Theme.fontFamily
                    font.bold: ccDay.isToday
                }

            }

        }

    }

}
