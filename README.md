# Aerospace.spoon


A HammerSpoon Aerospace integration which provides:

1. UI Element for selecting and creating spaces by name
2. UI Element for moving a window to a particular space
3. Toggleable terminal scratchpad instance.

## Usage

Follow directions for installing a Spoon on HammerSpoon's documentation.

Load it with defaults in your `init.lua`.

```lua
Aerospace = hs.loadSpoon('Aerospace')
Aerospace:bindHotkeys({})
Aerospace:start()
```

### Creating and switching spaces

By default `alt + w` opens the workspace switcher.
You can select a workspace to switch too using a fuzzy searcher.

You can also provide a workspace which does not exist, it will be created and
you will be switched to the workspace.

### Moving windows to another space

By default `alt + a` opens the window mover.
You can select a workspace to move the currently focused window to using a fuzzy searcher.

You can also provide a workspace which does not exist, it will be created and
the window will be moved to the new workspace, focusing the window after.

### Scratchpad

The scratchpad is a bit opinionated.
It expects a single window to have the permanent title of `scratchpad`.

This window is expected to be detected and set to floating in your Aerospace
configuration:

```toml
[[on-window-detected]]
	if.window-title-regex-substring = '^scratchpad$'
	run = ['layout floating']

```

By default when you press `alt + -` one of several actions will occur.
1. If no scratchpad window is found the provided launch command passed to `start`
will be executed.
2. If the application window created from the launch command is focused, the
window will be moved to the `.scratchpad` workspace. This workspace is hidden
from the workspace switcher.
3. If a scrachpad window does exist but is not focused it will moved to the
current workspace and focused.

The default scratchpad launch command is the one I use personally:
`open -n -a kitty.app --args -T scratchpad --instance-group scratchpad`

## Configuration

### Config
You can provide a scratchpad launch command to the `start` function.
See [Usage Scratchpad](#usage-scratchpad)

```lua
Aerospace:start("alacritty -t 'terminal-scratchpad'")
```

### Keymaps

```lua
local defaultHotKeysMapping = {
	createSpace = { { "alt", "ctrl", "shift" }, "n" },
	selectSpace = { { "alt" }, "w" },
	windowToSpace = { { "alt" }, "a" },
	scratchpad = { { "alt" }, "-"}
}
```

Keymaps can be overwritten on a per-key basis:
```lua
aerospace:bindHotkeys({ createSpace = { { "alt", "shift" }, "x" } })
```
