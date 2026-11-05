//@ pragma UseQApplication

// Shell root — composition only. Everything lives in its own file tree:
//   AppState.qml     shared state (caffeine, command-center open/hover, active
//                    MPRIS player) + the processes/timers that serve it
//   Theme.qml        palette (matugen with hand-tuned fallbacks) + layout metrics
//   Utils.qml        pure helpers (status colors, icon glyphs, formatting)
//   ui/              dumb reusable widgets (BarBox, BarIcon, CcButton, ...)
//   bar/             the bar window (Bar.qml) + one file per bar cluster;
//                    segments/ holds the stats box internals
//   cc/              the command-center window (CommandCenter.qml) + one file
//                    per section
// Layer logic: shell/state → windows → clusters and sections → segments and
// ui widgets. Shared state is read through the AppState singleton; each
// element owns its sensors, timers and processes.
//
// This is a vendored asset: copyable to non-NixOS machines, never generated
// from Nix values (AGENTS.md feature-module pattern #9). On machines without
// JetBrainsMono Nerd Font the glyphs fall back through fontconfig.

import Quickshell
import "bar"
import "cc"

ShellRoot {
    Bar { }

    CommandCenter { }

}
