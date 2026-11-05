// command center: media card — title/artist, progress (hidden for
// livestreams) and transport controls; `visible` is set by the caller
import QtQuick
import QtQuick.Layouts
import ".."
import "../ui"

CcSection {
    id: mediaSection

    property var player: null

    readonly property bool isPlaying: player?.isPlaying ?? false
    readonly property string title: player?.trackTitle ?? ""
    readonly property string author: player?.trackArtist ?? ""
    // livestreams (Twitch, browser live tabs) report no usable length —
    // Chromium emits INT64_MAX, some players emit 0 — treat that as live and
    // hide the progress/time row instead of showing a bogus clock
    readonly property bool live: player === null
        || (player.length <= 0 || player.length > 86400) // > 24h can't be a track

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Text {
            text: "󰎈"
            font.family: Theme.iconFont
            font.pixelSize: Theme.iconSize + 7
            color: mediaSection.isPlaying ? Theme.col16 : Theme.col3

            Behavior on color {
                ColorAnimation {
                    duration: 150
                }

            }

        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                text: mediaSection.title !== "" ? mediaSection.title : "No media"
                color: Theme.col14
                font.pixelSize: Theme.fontSize
                font.family: Theme.fontFamily
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: mediaSection.author
                visible: mediaSection.author !== ""
                color: Theme.col5
                font.pixelSize: Theme.fontSize - 1
                font.family: Theme.fontFamily
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

        }

    }

    // progress: thin accent fill on a dim groove
    // (hidden for livestreams — no meaningful length)
    RowLayout {
        visible: mediaSection.player !== null && !mediaSection.live
        Layout.fillWidth: true
        spacing: 8

        Text {
            text: Utils.fmtSec(mediaSection.player?.position ?? 0)
            color: Theme.col5
            font.pixelSize: Theme.fontSize - 1
            font.family: Theme.fontFamily
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 4
            radius: 2
            color: Qt.alpha(Theme.col16, 0.15)

            Rectangle {
                width: parent.width * ((mediaSection.player && mediaSection.player.length > 0) ? Math.min(1, (mediaSection.player.position ?? 0) / mediaSection.player.length) : 0)
                height: parent.height
                radius: 2
                color: Theme.col16
            }

        }

        Text {
            text: Utils.fmtSec(mediaSection.player?.length ?? 0)
            color: Theme.col5
            font.pixelSize: Theme.fontSize - 1
            font.family: Theme.fontFamily
        }

    }

    Row {
        Layout.alignment: Qt.AlignHCenter
        spacing: 8

        CcButton {
            glyph: "󰒮"
            name: "Previous"
            onActivate: () => mediaSection.player?.previous()
        }

        CcButton {
            implicitWidth: 44
            glyph: mediaSection.isPlaying ? "󰏤" : "󰐊"
            name: mediaSection.isPlaying ? "Pause" : "Play"
            onActivate: () => mediaSection.player?.togglePlaying()
        }

        CcButton {
            glyph: "󰒭"
            name: "Next"
            onActivate: () => mediaSection.player?.next()
        }

    }

}
