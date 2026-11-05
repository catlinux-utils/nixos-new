// Media (MPRIS) pill — hidden entirely when nothing is playing
import QtQuick
import QtQuick.Layouts
import ".."
import "../ui"

BarBox {
    id: mediaBox

    property var player: null

    readonly property bool isPlaying: player?.isPlaying ?? false
    readonly property string title: player?.trackTitle ?? ""
    readonly property string author: player?.trackArtist ?? ""

    visible: title !== ""
    tint: isPlaying ? Theme.col7 : Theme.col3

    BarIcon {
        text: mediaBox.isPlaying ? "󰎈" : "󰏤"
        color: mediaBox.isPlaying ? Theme.col7 : Theme.col3
    }

    BarText {
        text: mediaBox.author !== "" ? mediaBox.author + " - " + mediaBox.title : mediaBox.title
        color: mediaBox.isPlaying ? Theme.col7 : Theme.col3
        Layout.maximumWidth: 300
        elide: Text.ElideRight
    }

}
