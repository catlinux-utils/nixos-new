// System tray pill — hidden when no tray items exist
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import ".."
import "../ui"

BarBox {
    id: trayBox

    visible: trayItems.count > 0

    Row {
        spacing: 6

        Repeater {
            id: trayItems

            model: SystemTray.items

            WrapperMouseArea {
                id: mouseArea

                required property SystemTrayItem modelData

                acceptedButtons: Qt.AllButtons
                onClicked: (event) => {
                    switch (event.button) {
                    case Qt.LeftButton:
                        mouseArea.modelData.activate();
                        break;
                    case Qt.RightButton:
                        if (mouseArea.modelData.hasMenu)
                            menu.open();

                        break;
                    }
                    event.accepted = true;
                }

                IconImage {
                    implicitHeight: Theme.iconSize
                    implicitWidth: Theme.iconSize
                    anchors.fill: parent
                    source: mouseArea.modelData.icon
                }

                QsMenuAnchor {
                    id: menu

                    menu: mouseArea.modelData.menu

                    anchor {
                        item: mouseArea
                        edges: Edges.Top
                        gravity: Edges.Top
                        adjustment: PopupAdjustment.All
                    }

                }

            }

        }

    }

}
