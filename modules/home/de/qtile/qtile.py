import os
import subprocess

from libqtile import bar, layout, widget
from libqtile.config import Click, Drag, Group, Key, Match, Screen
from libqtile.lazy import lazy
from libqtile import hook

# Constants
mod = "mod4"
terminal = "kitty"
browser = "brave"
editor = "notepadqq --new-window"
fileManager = "nemo"

lightBlue = "#739BD0"
lightGrey = "#bcbcbc"

left = "Left"
right = "Right"
down = "Down"
up = "Up"


### SHORTCUTS ###
keys = [
	# Essentials
	Key([mod, "shift"], "c", lazy.window.kill(), desc="Kill focused window"),
	Key([mod, "control"], "r", lazy.reload_config(), desc="Reload the config"),
	Key([mod, "control"], "q", lazy.shutdown(), desc="Shutdown Qtile"),

	# Launch programs
	Key([mod], "Return", lazy.spawn(terminal), desc="Launch terminal"),
	Key([mod], "r", lazy.spawn("rofi -show drun"), desc="Spawn a command using a prompt widget"),
	Key([mod, "shift"], "r", lazy.spawn("rofi -show run"), desc="Spawn a command using a prompt widget"),
	Key([mod], "b", lazy.spawn(browser), desc="launch browser"),
	Key([mod], "n", lazy.spawn(editor), desc="launch notepadqq"),
	Key([mod], "f", lazy.spawn(fileManager), desc="launch file manager"),
	Key([mod], "c", lazy.spawn("codium"), desc="launch vscodium"),
	Key([mod], "s", lazy.spawn("spotify"), desc="launch spotify"),
	Key([mod], "v", lazy.spawn("clipmenu"), desc="launch clipmenu"),
	
	# Media controls
	Key([], "XF86AudioPlay", lazy.spawn("playerctl --player=ncspot,spotify play-pause "), desc="Play and pause spotify"),
	Key([], "XF86AudioMute", lazy.spawn("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), desc="Mute and unmute"),
	Key([], "XF86AudioLowerVolume", lazy.spawn("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), desc="Lower volume"),
	Key([], "XF86AudioRaiseVolume", lazy.spawn("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), desc="Raise volume"),

	# Brightness controls
	Key([], "XF86MonBrightnessUp", lazy.spawn("brightnessctl set +5%"), desc="Raise brightness"),
	Key([], "XF86MonBrightnessDown", lazy.spawn("brightnessctl set 5%-"), desc="Lower brightness"),

	# Move window focus
	Key([mod], left, lazy.layout.left(), desc="Move focus to left"),
	Key([mod], right, lazy.layout.right(), desc="Move focus to right"),
	Key([mod], down, lazy.layout.down(), desc="Move focus down"),
	Key([mod], up, lazy.layout.up(), desc="Move focus up"),
	Key([mod], "space", lazy.layout.next(), desc="Move window focus to other window"),
    
	# Move windows
	Key([mod, "shift"], left, lazy.layout.shuffle_left(), desc="Move window to the left"),
	Key([mod, "shift"], right, lazy.layout.shuffle_right(), desc="Move window to the right"),
	Key([mod, "shift"], down, lazy.layout.shuffle_down(), desc="Move window down"),
	Key([mod, "shift"], up, lazy.layout.shuffle_up(), desc="Move window up"),
    
	# Size windows
	Key([mod, "shift"], "n", lazy.layout.normalize(), desc="Reset all window sizes"),
	Key([mod], "plus", lazy.layout.grow().when(layout=["monadtall", "monadwide"]), desc="Grow window"),
	Key([mod], "minus", lazy.layout.shrink().when(layout=["monadtall", "monadwide"]), desc="Shrink window"),
    
	# Manage layouts
	Key([mod], "Tab", lazy.next_layout(), desc="Toggle between layouts"),
	Key([mod, "shift"], "f", lazy.window.toggle_fullscreen(), desc="Toggle fullscreen on the focused window"),
	Key([mod, "shift"], "t", lazy.window.toggle_floating(), desc="Toggle floating on the focused window"),
	Key([mod, "shift"], "b", lazy.hide_show_bar(), desc="Toggle bar visibility"),
]


### LAYOUTS ###
groups = [Group(i) for i in "123456789"]

# Switching between layouts
for i in groups:
	keys.extend(
		[
			Key([mod], i.name, lazy.group[i.name].toscreen(), desc="Switch to group {}".format(i.name)),
			Key([mod, "shift"], i.name, lazy.window.togroup(i.name, switch_group=False), desc="Switch to & move focused window to group {}".format(i.name)),
		]
	)

# Available layouts
layouts = [
	layout.MonadTall(border_focus=lightBlue, border_normal=lightGrey, border_width=2, margin=8, single_margin=0, single_border_width=0),
	layout.Floating(),
]

# Drag floating layouts.
mouse = [
	Drag([mod], "Button1", lazy.window.set_position_floating(), start=lazy.window.get_position()),
	Drag([mod], "Button3", lazy.window.set_size_floating(), start=lazy.window.get_size()),
	Click([mod], "Button1", lazy.window.bring_to_front()),
]


### WIDGETS ###
widget_defaults = dict(
	font="sans, JetBrainsMono Nerd Font",
	fontsize=15,
	padding=3,
)
extension_defaults = widget_defaults.copy()

# Display widgets on the bar
screens = [
	Screen(
		top=bar.Bar(
			[
				widget.Clock(format=" %H:%M"),
				widget.Sep(),
				widget.Clock(format="󰃮 %a. %d.%m.%y"),
				widget.Spacer(),
				widget.GroupBox(highlight_method="line", this_current_screen_border=lightBlue),
				widget.Spacer(),
				widget.WidgetBox(text_closed="", text_open="" , widgets=[ 
					widget.Systray()
				]),
				widget.Sep(),
				widget.Wlan(format="󰖩  {essid}", interface="wlp2s0", update_interval=5, max_chars=4),
				widget.Sep(),
				widget.ThermalSensor(format="  {temp:.1f}{unit}", tag_sensor="CPU", threshold=90, update_interval=5),
				widget.Sep(),
				widget.PulseVolume(fmt="󰕾 {}"),
				widget.Sep(),
				widget.Backlight(fmt="󰃠 {}", backlight_name='amdgpu_bl0'),
				widget.Sep(),
				widget.Battery(format="󰁹 {percent:2.0%}"),
			],
			26,
		),
	),
]


### RULES ###
dgroups_key_binder = None
dgroups_app_rules = []  # type: list
follow_mouse_focus = True
bring_front_click = False
floats_kept_above = True
cursor_warp = False
floating_layout = layout.Floating(
	float_rules=[
		# Run the utility of `xprop` to see the wm class and name of an X client.
		*layout.Floating.default_float_rules,
		Match(wm_class="confirmreset"),  # gitk
		Match(wm_class="makebranch"),  # gitk
		Match(wm_class="maketag"),  # gitk
		Match(wm_class="ssh-askpass"),  # ssh-askpass
		Match(title="branchdialog"),  # gitk
		Match(title="pinentry"),  # GPG key password entry
	]
)
auto_fullscreen = True
focus_on_window_activation = "smart"
reconfigure_screens = True

auto_minimize = True

wl_input_rules = None

wmname = "LG3D"