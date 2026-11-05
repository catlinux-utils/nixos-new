// ── left bar cluster: workspaces ──
// one shared pill behind the row; the buttons keep their own hover/active
// pill inside it. Wheel over the pill cycles workspaces.
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import ".."
import "../ui"

Rectangle {
    id: workspaceContainer

    // workspace pills: the bound 1..10 (Roman) always stay — SUPER+0..9
    // switch to them even when empty — plus any extra workspace Hyprland
    // knows (id > 10, e.g. created on another monitor or by a script),
    // shown by name
    property var wsRoman: ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
    readonly property var wsModel: {
        var model = [];
        for (var i = 1; i <= 10; i++)
            model.push({
                "id": i,
                "label": workspaceContainer.wsRoman[i - 1]
            });

        var extra = Hyprland.workspaces.values.filter((w) => w.id > 10);
        extra.sort((a, b) => a.id - b.id);
        for (var j = 0; j < extra.length; j++)
            model.push({
                "id": extra[j].id,
                "label": extra[j].name || String(extra[j].id)
            });
        return model;
    }

    Layout.preferredHeight: Theme.barHeight - 8
    Layout.alignment: Qt.AlignVCenter
    Layout.leftMargin: Theme.pad
    Layout.preferredWidth: workspaceRow.implicitWidth + 12
    radius: 6
    color: "transparent"
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.35)

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0)
                Hyprland.dispatch(`hl.dsp.focus({workspace = "-1"})`);
            else if (wheel.angleDelta.y < 0)
                Hyprland.dispatch(`hl.dsp.focus({workspace = "+1"})`);
            wheel.accepted = true;
        }
    }

    Row {
        id: workspaceRow

        anchors.centerIn: parent
        spacing: 3

        Repeater {
            model: workspaceContainer.wsModel

            Rectangle {
                property int wsId: modelData.id
                property var workspace: Hyprland.workspaces.values.find((w) => {
                    return w.id === wsId;
                })
                property bool hasWindows: workspace ? workspace.toplevels.values.length > 0 : false
                property bool isActive: Hyprland.focusedWorkspace?.id === wsId

                width: wsLabel.implicitWidth + 10
                height: Theme.barHeight - 14
                radius: 5
                // active workspace gets a translucent accent
                // fill — visible without shouting
                color: isActive ? Qt.alpha(Theme.col16, 0.40) : (hoverArea.containsPress ? Qt.rgba(1, 1, 1, 0.13) : (hoverArea.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent"))

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }

                }

                Text {
                    id: wsLabel

                    anchors.centerIn: parent
                    text: modelData.label
                    color: isActive ? Theme.col15 : (hasWindows ? Theme.col15 : Theme.col1)
                    font.pixelSize: Theme.fontSize + 1
                    font.family: Theme.fontFamily
                    font.bold: isActive

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }

                    }

                }

                MouseArea {
                    id: hoverArea

                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${wsId} })`)
                    onWheel: (wheel) => {
                        return wheel.accepted = false;
                    }
                    cursorShape: Qt.PointingHandCursor
                }

            }

        }

    }

}
