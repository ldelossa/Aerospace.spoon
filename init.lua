local obj = {}
obj.__index = obj

-- Metadata
obj.name = "Aerospace"
obj.version = "0.1"
obj.author = "Louis DeLosSantos <louis.delos@gmail.com>"
obj.homepage = "https://github.com/ldelossa/AerospaceSpoon"
obj.license = "MIT - https://opensource.org/licenses/MIT"

-- fields
obj.logger = hs.logger.new('Aerospace', 'debug')
obj.client = dofile(hs.spoons.resourcePath("client.lua"))

obj.registry = {
	onApplicationChanged = {},
	onSpacesChanged = {},
	onWindowsChanged = {},
	onDisplaysChanged = {}
}

local defaultHotKeysMapping = {
	createSpace = { { "alt", "ctrl", "shift" }, "n" },
	selectSpace = { { "alt" }, "w" },
	labelSpace = { { "alt" }, "r" },
	windowToSpace = { { "alt" }, "a" },
	scratchpad = { { "alt" }, "-"}
}

local hotKeyHandlers = {
	createSpace = function() obj:createSpace() end,
	selectSpace = function() obj:selectSpace() end,
	windowToSpace = function() obj:moveWindowToSpace() end,
	scratchpad = function() obj:toggleScratchSpace() end
}

function obj:bindHotkeys(mapping)
	if mapping then
		for k, v in pairs(mapping) do
			defaultHotKeysMapping[k] = v
		end
	end

	for k, v in pairs(defaultHotKeysMapping) do
		hs.hotkey.bind(v[1], v[2], hotKeyHandlers[k])
	end
end

-- The cmd used to launch a scratch pad.
local scratchCmd = "open -n -a kitty.app --args -T scratchpad --instance-group scratchpad"

function obj:start(scratchPadLaunchCmd)
	if scratchpadLaunchCmd then
		scratchCmd = scratchPadLaunchCmd
	end
end

function obj:stop()
end

function obj:onApplicationsChanged(event)
	for _, cb in ipairs(self.registry.onApplicationChanged) do
		cb(event)
	end
end

function obj:onSpacesChanged(event)
	for _, cb in ipairs(self.registry.onSpacesChanged) do
		cb(event)
	end
end

function obj:onWindowsChanged(event)
	for _, cb in ipairs(self.registry.onWindowsChanged) do
		cb(event)
	end
end

function obj:onDisplaysChanged(event)
	for _, cb in ipairs(self.registry.onDisplaysChanged) do
		cb(event)
	end
end

function obj:registerOnApplicationsChangedCB(func)
	table.insert(self.registry.onApplicationChanged, func)
end

function obj:registerOnSpacesChangedCB(func)
	table.insert(self.registry.onSpacesChanged, func)
end

function obj:registerOnWindowsChangedCB(func)
	table.insert(self.registry.onWindowsChanged, func)
end

function obj:registerOnDisplaysChangedCB(func)
	table.insert(self.registry.onDisplaysChanged, func)
end

-- Creates a chooser which invokes `cb` on a choice.
-- @param cb function: The callback to invoke on a choice which takes the
-- following arguments:
-- 										{choice}
--
-- The `choice` argument to the callback will have a .space member containing
-- the selected Aerospace space.
--
-- If `choice` is nil, the user canceled the operation or no spaces exist.
function obj:spaceChooser(cb)
	local spaces = self.client:getSpaces()
	if not spaces then
		self.logger.ef("Failed to retrieve spaces")
		return
	end

	if #spaces == 0 then
		self.logger.df("No spaces found")
		return
	end

	local choices = {}
	for _, space in ipairs(spaces) do
		-- ignore .scratchpad space
		if space.workspace == ".scratchpad" then
			goto continue
		end

		local text = space.workspace
		table.insert(choices, {
			text = text,
			subText = "",
			uuid = text,
			space = space
		})
		::continue::
	end

	local chooser = hs.chooser.new(function(choice)
		cb(choice)
	end)
	chooser:enableDefaultForQuery(true)

	local rows = #choices
	if rows > 10 then
		rows = 10
	end

	chooser:rows(rows)
	chooser:choices(choices)
	chooser:show()
end

function obj:simpleTextPrompt(summary, details)
	local button, input = hs.dialog.textPrompt(summary, details, "", "OK", "Cancel")
	if (button == "Cancel") then
		return nil
	end
	return input
end

-- Promp the user with a TextPrompt for a label, create a new space, label it
-- and focus it.
function obj:createSpace()
	self.logger.d("Creating a new space")

	local label = self:simpleTextPrompt("Create a new space",
		"Provide a label for the space.\nAn empty label will use the next available desktop number.")

	if not label then return end

	self.client:createSpace(label, true)
	self.logger.df("Created new space with label: %s", label)
end

-- Prompt the user with a chooser to select a space to focus.
function obj:selectSpace()
	self.logger.d("Selecting a space")

	self:spaceChooser(function(choice)
		if not choice then
			self.logger.df("User canceled space selection")
			return
		end

		if not choice.space then
			-- create space
			self.client:createOrFocusSpace(choice.text)
			return
		end

		self.client:createOrFocusSpace(choice.space.workspace)

		self.logger.df("Focused space with label: %s", choice.text)
	end)
end

function obj:moveWindowToSpace()
	self:spaceChooser(function(choice)
		if not choice then
			self.logger.df("User canceled space selection")
			return
		end

		if not choice.space then
			self.client:currentWindowToSpace(choice.text)
			return
		end

		self.client:currentWindowToSpace(choice.space.workspace)

		self.logger.df("Focused space with label: %s", choice.text)
	end)
end

function obj:toggleScratchSpace()
	local windows = self.client:getWindows()
	local focused_space = self.client:getFocusedSpace()

	local scratchpad = nil
	for _, window in ipairs(windows) do
		if window["window-title"] == "scratchpad" then
			scratchpad = window
			break
		end
	end

	-- if no scratchpad window found, create a scratchpad with the cmd
	-- this relies on aersospace window detection to detect the window, place
	-- it in a .scratchpad workspace, and make it floating.
	if not scratchpad then
		self.logger.d("Creating a new scratchpad")
		hs.execute(scratchCmd, false)
		return
	end

	-- scratchpad exists, is it the currently focused window, if it is, we should
	-- move it away to .scratchpad workspace.
	local focused = self.client:getFocusedWindow()
	if focused ~= nil and focused["window-id"] == scratchpad["window-id"] then
		self.logger.d("Hiding the scratchpad")
		self.client:windowToSpace(scratchpad["window-id"], ".scratchpad")
		return
	end

	-- focused window is not the scratchpad, so we want to summon it.
	-- lets move the scratchpad to the focused space
	self.logger.d("Summoning the scratchpad")
	self.client:windowToSpace(scratchpad["window-id"], focused_space.workspace)
	self.client:focusWindow(scratchpad["window-id"])
	return
end

return obj
