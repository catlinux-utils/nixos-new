pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  // Runtime palette from matugen (modules/home/palette.nix): the bar recolors
  // live when the wallpaper changes. When ~/.cache/theming/palette.json is
  // missing or invalid the hand-tuned fallbacks below apply, so this file
  // stays copyable to non-NixOS machines.
  property var palette: null

  FileView {
    id: paletteFile

    path: Quickshell.env("HOME") + "/.cache/theming/palette.json"
    watchChanges: true
    onFileChanged: {
      paletteFile.reload();
      paletteFile.waitForJob();
      parse();
    }

    Component.onCompleted: {
      paletteFile.reload();
      paletteFile.waitForJob();
      parse();
    }

    function parse() {
      try {
        palette = JSON.parse(paletteFile.text());
      } catch (e) {
        palette = null;
      }
    }
  }

  function pick(key, fallback) {
    return palette && palette[key] !== undefined ? palette[key] : fallback
  }

  readonly property color colBg: pick("bg", "#010001")
  readonly property color colFg: pick("fg", "#ebeffe")
  readonly property color col0: pick("bgAlt", "#18161a")
  readonly property color col1: pick("dim", "#707f9b")
  readonly property color col2: pick("dimAlt", "#7a7e96")
  readonly property color col3: pick("dim", "#5b6a99")
  readonly property color col4: pick("dimAlt", "#838dab")
  readonly property color col5: pick("dimAlt", "#859bb7")
  readonly property color col6: pick("dimAlt", "#959cbc")
  readonly property color col7: pick("bright", "#dbe0f5")
  readonly property color col8: pick("dimAlt", "#999bab")
  readonly property color col9: pick("dimAlt", "#97abcf")
  readonly property color col10: pick("dimAlt", "#a2a7c8")
  readonly property color col11: pick("accentAlt", "#8fa6ec")
  readonly property color col12: pick("dimAlt", "#afbee4")
  readonly property color col13: pick("dimAlt", "#b0cef4")
  readonly property color col14: pick("accent", "#c7d1fb")
  readonly property color col15: pick("bright", "#edf0fc")
  readonly property color col16: pick("bright", "#dbe0f5")
}
