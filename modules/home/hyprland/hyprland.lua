-- Refer to the wiki for more information.
-- https://wiki.hypr.land/Configuring/Start/
-- Please note not all available settings / options are set here.
-- For a full list, see the wiki
-- You can (and should!!) split this configuration into multiple files
-- Create your files separately and then require them like this:
-- require("myColors")
-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1
})

hl.config({
    general = {
        gaps_in = 0,
        gaps_out = 0,
        gaps_workspaces = 50,

        resize_on_border = true,
        no_focus_fallback = true,

        allow_tearing = false,

        col = {
            active_border = "rgba(0,0,0,0)",
            inactive_border = "rgba(0,0,0,0)"
        },

        -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on

        layout = "dwindle"
    },

    decoration = {
        rounding = 10,
        rounding_power = 2,

        active_opacity = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = 0xee1a1a1a
        },

        blur = {
            enabled = true,
            size = 3,
            passes = 1,
            vibrancy = 0.1696
        }
    },

    input = {
        kb_layout = "pl",
        numlock_by_default = true,
        repeat_delay = 250,
        repeat_rate = 35,

        touchpad = {
            natural_scroll = true,
            clickfinger_behavior = true,
            scroll_factor = 0.5
        },
        special_fallthrough = true,
        follow_mouse = 1,
        accel_profile = "flat"
    },

    animations = {
        enabled = true
    },

    dwindle = {
        preserve_split = true,
        smart_split = true
    },
    binds = {
        scroll_event_delay = 0,
        allow_workspace_cycles = true
    },
    misc = {
        disable_hyprland_logo = true,
        force_default_wallpaper = 0,
        allow_session_lock_restore = true,

        middle_click_paste = true,

        initial_workspace_tracking = 2,

        background_color = "rgba(0, 0, 0, 1)"
    }
})

hl.device({
    name = "logitech-usb-receiver-mouse",
    sensitivity = -0.50,
    accel_profile = "adaptive"
})

hl.on("hyprland.start", function()
    hl.exec_cmd("uwsm app -- dbus-update-activation-environment --all")
    monitors_setup()
end)

hl.on("monitor.added", function()
    monitors_setup()
end)
hl.on("config.reloaded", function()
    monitors_setup()
end)

function monitors_setup()
    local monitors = hl.get_monitors()

    local workspace_map = {
        ["DP-3"] = {
            start_w = 1,
            end_w = 5
        },
        ["HDMI-A-1"] = {
            start_w = 6,
            end_w = 10
        }
    }

    local connected = {}
    for _, mon in ipairs(monitors) do
        if workspace_map[mon.name] then
            connected[mon.name] = true
        end
    end

    if connected["DP-3"] or connected["HDMI-A-1"] then
        for mon_name, range in pairs(workspace_map) do
            for i = range.start_w, range.end_w do
                hl.workspace_rule({
                    workspace = tostring(i),
                    monitor = mon_name
                })
            end
        end
    end
end

-----------------------
----- PERMISSIONS -----
-----------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

-- hl.config({
--   ecosystem = {
--     enforce_permissions = true,
--   },
-- })

-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")

-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/

-- Default curves and animations, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("easeOutQuint", {
    type = "bezier",
    points = {{0.23, 1}, {0.32, 1}}
})
hl.curve("easeInOutCubic", {
    type = "bezier",
    points = {{0.65, 0.05}, {0.36, 1}}
})
hl.curve("linear", {
    type = "bezier",
    points = {{0, 0}, {1, 1}}
})
hl.curve("almostLinear", {
    type = "bezier",
    points = {{0.5, 0.5}, {0.75, 1}}
})
hl.curve("quick", {
    type = "bezier",
    points = {{0.15, 0}, {0.1, 1}}
})

hl.curve("menu_decel", {
    type = "bezier",
    points = {{0.1, 1}, {0, 1}}
})

-- Default springs
hl.curve("easy", {
    type = "spring",
    mass = 1,
    stiffness = 71.2633,
    dampening = 15.8273644
})

hl.animation({
    leaf = "global",
    enabled = true,
    speed = 10,
    bezier = "default"
})
hl.animation({
    leaf = "border",
    enabled = true,
    speed = 5.39,
    bezier = "easeOutQuint"
})
hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 4.79,
    spring = "easy"
})
hl.animation({
    leaf = "windowsIn",
    enabled = true,
    speed = 4.1,
    spring = "easy",
    style = "popin 87%"
})
hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 1.49,
    bezier = "linear",
    style = "popin 87%"
})
hl.animation({
    leaf = "fadeIn",
    enabled = true,
    speed = 1.73,
    bezier = "almostLinear"
})
hl.animation({
    leaf = "fadeOut",
    enabled = true,
    speed = 1.46,
    bezier = "almostLinear"
})
hl.animation({
    leaf = "fade",
    enabled = true,
    speed = 3.03,
    bezier = "quick"
})
hl.animation({
    leaf = "layers",
    enabled = true,
    speed = 3.81,
    bezier = "easeOutQuint"
})
hl.animation({
    leaf = "layersIn",
    enabled = true,
    speed = 4,
    bezier = "easeOutQuint",
    style = "fade"
})
hl.animation({
    leaf = "layersOut",
    enabled = true,
    speed = 1.5,
    bezier = "linear",
    style = "fade"
})
hl.animation({
    leaf = "fadeLayersIn",
    enabled = true,
    speed = 1.79,
    bezier = "almostLinear"
})
hl.animation({
    leaf = "fadeLayersOut",
    enabled = true,
    speed = 1.39,
    bezier = "almostLinear"
})
hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 7,
    bezier = "menu_decel",
    style = "slide"
})
hl.animation({
    leaf = "zoomFactor",
    enabled = true,
    speed = 7,
    bezier = "quick"
})

-- Ref https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- "Smart gaps" / "No gaps when only"
-- uncomment all if you wish to use that.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
--     name  = "no-gaps-wtv1",
--     match = { float = false, workspace = "w[tv1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
-- hl.window_rule({
--     name  = "no-gaps-f1",
--     match = { float = false, workspace = "f[1]" },
--     border_size = 0,
--     rounding    = 0,
-- })

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more

---------------------
---- KEYBINDINGS ----
---------------------

hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + SHIFT + C", hl.dsp.window.kill())

hl.bind("SUPER + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || uwsm stop"))

hl.bind("SUPER + ALT + Space", hl.dsp.window.float())
hl.bind("SUPER + I", hl.dsp.layout("togglesplit"))
hl.bind("SUPER + L", hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind("SUPER + F", hl.dsp.window.fullscreen())
hl.bind("ALT + Tab", hl.dsp.focus({
    workspace = "previous"
}))

hl.bind("SUPER + T", hl.dsp.exec_cmd("uwsm app -- kitty.desktop"))
hl.bind("SUPER + W", hl.dsp.exec_cmd("uwsm app -- brave-browser.desktop"))
hl.bind("SUPER + C", hl.dsp.exec_cmd("uwsm app -- code.desktop"))
hl.bind("SUPER + E", hl.dsp.exec_cmd("uwsm app -- nemo.desktop"))
hl.bind("SUPER + R", hl.dsp.exec_cmd(
    "pidof rofi & killall rofi || uwsm app -- rofi -show drun -location 1 -config ~/.config/rofi/config.rasi -terminal kitty -run-command 'uwsm app -- {cmd}'"))
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("hyprshot -m region -z"))

hl.bind("SUPER + left", hl.dsp.focus({
    direction = "left"
}))
hl.bind("SUPER + right", hl.dsp.focus({
    direction = "right"
}))
hl.bind("SUPER + up", hl.dsp.focus({
    direction = "up"
}))
hl.bind("SUPER + down", hl.dsp.focus({
    direction = "down"
}))

hl.bind("SUPER + SHIFT + left", hl.dsp.window.move({
    direction = "left"
}))
hl.bind("SUPER + SHIFT + right", hl.dsp.window.move({
    direction = "right"
}))
hl.bind("SUPER + SHIFT + up", hl.dsp.window.move({
    direction = "up"
}))
hl.bind("SUPER + SHIFT + down", hl.dsp.window.move({
    direction = "down"
}))

for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind("SUPER + " .. key, hl.dsp.focus({
        workspace = i
    }))
    hl.bind("SUPER + ALT + " .. key, hl.dsp.window.move({
        workspace = i,
        follow = false
    }))
end

-- hl.bind("SUPER + S",         hl.dsp.workspace.toggle_special("magic"))
-- hl.bind("SUPER + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind("SUPER + mouse_down", hl.dsp.focus({
    workspace = "+1"
}))
hl.bind("SUPER + mouse_up", hl.dsp.focus({
    workspace = "-1"
}))

hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), {
    mouse = true
})
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), {
    mouse = true
})

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), {
    locked = true,
    repeating = true
})
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), {
    locked = true,
    repeating = true
})
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), {
    locked = true,
    repeating = true
})
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), {
    locked = true,
    repeating = true
})
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), {
    locked = true,
    repeating = true
})
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), {
    locked = true,
    repeating = true
})

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), {
    locked = true
})
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), {
    locked = true
})
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), {
    locked = true
})
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), {
    locked = true
})

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Example window rules that are useful

hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name = "suppress-maximize-events",
    match = {
        class = ".*"
    },

    suppress_event = "maximize"
})

hl.window_rule({
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false
    },
    no_focus = true
})

hl.window_rule({
    match = {
        title = "^(Picture(-| )in(-| )[Pp]icture)$|^(Obraz w obrazie)$"
    },
    float = true,
    size = {608, 342},
    keep_aspect_ratio = true,
    pin = true
})
hl.window_rule({
    match = {
        class = "^(xdg-desktop-portal-gtk)$"
    },
    float = true,
    center = true
})
-- hl.window_rule({ match = { class = "^(.*\\.exe|steam_app)$" },immediate = true })
hl.window_rule({
    match = {
        float = false
    },
    no_shadow = true
})
hl.window_rule({
    match = {
        class = "^steam$",
        title = "^(Steam)$"
    },
    center = true,
    opacity = 1.0
})
hl.window_rule({
    match = {
        class = "^steam$",
        title = "^(Friends List|Lista znajomych)$"
    },
    float = true,
    size = {300, 800},
    no_focus = false
})
hl.window_rule({
    match = {
        title = "^Arma Reforger$"
    },
    render_unfocused = true
})
hl.window_rule({
    match = {
        class = "^steam21$"
    },
    idle_inhibit = "fullscreen"
})

-- smart gaps / no gaps when only one window - per workspace
hl.workspace_rule({
    workspace = "w[tv1]",
    gaps_out = 0,
    gaps_in = 0
})
hl.workspace_rule({
    workspace = "f[1]",
    gaps_out = 0,
    gaps_in = 0
})
hl.window_rule({
    match = {
        float = false,
        workspace = "w[tv1]"
    },
    border_size = 0
})
hl.window_rule({
    match = {
        float = false,
        workspace = "w[tv1]"
    },
    rounding = 0
})
hl.window_rule({
    match = {
        float = false,
        workspace = "f[1]"
    },
    border_size = 0
})
hl.window_rule({
    match = {
        float = false,
        workspace = "f[1]"
    },
    rounding = 0
})

hl.layer_rule({
    match = {
        class = ".*"
    },
    xray = 1
})
