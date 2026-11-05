pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

// Shared shell state: caffeine, command-center open/hover bookkeeping and
// the active MPRIS player. The bar (bar/Bar.qml) and the command center
// (cc/CommandCenter.qml) both read through this singleton; layout metrics
// and palette live in Theme, pure helpers in Utils.
Singleton {
    id: appState

    // idle inhibitor ("caffeine"), toggled from the command center's quick
    // actions: while on, the bar surface holds a Wayland idle-inhibit so the
    // compositor never reports idle and hypridle's dim/lock/dpms/suspend
    // listeners stay quiet — no external process, no dbus dance
    property bool idleInhibited: false

    // ── command center (toggled by clicking the clock) ──
    // A small Overlay-layer panel under the clock with media controls, volume
    // and brightness sliders, quick actions and a month calendar. `ccScreen`
    // keeps it on the monitor whose clock was clicked; hovering off it (and the
    // clock) dismisses it, clicks outside it never land on the popup at all.
    property bool ccOpen: false
    // hover-dismiss: the popup stays open while the pointer is over the popup
    // itself or the clock; a short grace timer closes it once it's over neither
    property bool ccHoverPopup: false
    property bool ccHoverClock: false
    property var ccScreen: null
    // y offset of the bar surface per output, read from Hyprland's layer
    // list when the command center opens — with a second (test) bar stacked
    // above, the bar does not sit at y=0 and the popup must anchor below its
    // real position. Our bar is identified by its layer namespace.
    property var barTops: ({})

    function toggleCc(screen) {
        layerQuery.running = true;
        if (appState.ccOpen && appState.ccScreen === screen) {
            appState.ccOpen = false;
            return ;
        }
        appState.ccScreen = screen;
        appState.activePlayer?.positionChanged(); // refresh the position binding now, not at the first tick
        appState.ccOpen = true;
    }

    // media comes from MPRIS (event-driven); prefer a playing player, else the first
    readonly property MprisPlayer activePlayer: Mpris.players.values.find((p) => p.isPlaying) ?? Mpris.players.values[0] ?? null

    // command center: locate the bar's layer surface per output
    Process {
        id: layerQuery

        command: ["hyprctl", "-j", "layers"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                var tops = {};
                try {
                    var outputs = JSON.parse(text);
                    for (var output in outputs) {
                        var levels = outputs[output].levels;
                        for (var level in levels)
                            for (var i = 0; i < levels[level].length; i++)
                                if (levels[level][i].namespace === "quickshell:bar")
                                    tops[output] = levels[level][i].y;
                    }
                } catch (e) {}
                appState.barTops = tops;
            }
        }

    }

    // MprisPlayer.position is not reactive — reading it is always current but
    // bindings only refresh when positionChanged fires (players emit it on
    // seeks, not continuously). Re-emit it on a fast tick while the command
    // center is open and a track is playing so the progress row moves.
    Timer {
        interval: 500
        running: appState.ccOpen && appState.activePlayer !== null && appState.activePlayer.isPlaying
        repeat: true
        triggeredOnStart: true
        onTriggered: appState.activePlayer.positionChanged()
    }

    // tracked once — the bar's volume/mic segments and the command-center
    // sliders read the default sink/source through it
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

}
