local AerospaceClient = {}
AerospaceClient.index = AerospaceClient

local log = hs.logger.new('AerospaceClient', 'debug')

function AerospaceClient:new()
	local obj = {}
	setmetatable(obj, self)
	return obj
end

-- Executes a aerospace command
-- @param domain string: The domain to execute the command in
-- @param args string: The arguments to pass to the command
local execAerospace = function(args)
	local cmd = "aerospace " .. args
	local data, _, _, code = hs.execute(cmd, true)
	return data, code
end

-- Returns the focused space
-- @return table: The focused space
function AerospaceClient:getFocusedSpace()
	local json, code = execAerospace("list-workspaces --focused --json")
	if code ~= 0 then
		log.ef("getFocusedSpace failed. code: %d", code)
		return nil
	end
	json = hs.json.decode(json)

	if #json == 0 then
		return nil
	end

	return json[1]
end

-- Returns a list of spaces
-- @return table: A list of spaces
function AerospaceClient:getSpaces()
	local json, code = execAerospace("list-workspaces --all --json")
	if code ~= 0 then
		log.ef("getSpaces failed. code: %d", code)
		return nil
	end
	json = hs.json.decode(json)

	return json
end

-- Creates a new space
-- @param space string: The space of the space
-- @param focus boolean: Whether to focus the space after creation
function AerospaceClient:createOrFocusSpace(space)
	execAerospace("workspace " .. space)
end

-- Moves the specified window to the specified space
-- @param window_id number: The ID of the window
-- @param workspace string: The space of the space
function AerospaceClient:windowToSpace(window_id, workspace)
	-- log arguments
	log.df("Moving window %s to space %s", window_id, workspace)
	execAerospace("move-node-to-workspace --window-id " .. window_id .. " " .. workspace)
end

-- Moves the current window to the specified space
-- @param space string: The space of the space
function AerospaceClient:currentWindowToSpace(space)
	execAerospace("move-node-to-workspace --focus-follows-window" .. space)
end

function AerospaceClient:getWindows()
	local json, code = execAerospace("list-windows --all --json")
	if code ~= 0 then
		log.ef("getWindows failed. code: %d", code)
		return nil
	end
	json = hs.json.decode(json)

	return json
end

function AerospaceClient:getFocusedWindow()
	local json, code = execAerospace("list-windows --focused --json")
	if code ~= 0 then
		log.ef("getWindows failed. code: %d", code)
		return nil
	end
	json = hs.json.decode(json)

	return json[1]
end

function AerospaceClient:focusWindow(window_id)
	execAerospace("focus --window-id " .. window_id)
end

return AerospaceClient
