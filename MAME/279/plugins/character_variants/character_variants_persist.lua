-- license:BSD-3-Clause
-- copyright-holders:Custom

-- helper functions

local function settings_path()
	return manager.machine.options.entries.homepath:value():match('([^;]+)') .. '/character_variants'
end

local function hotkeys_filename()
	return 'hotkeys.cfg'
end

local function plugin_settings_filename()
	return 'character_variants_settings.cfg'
end

-- Default hotkeys
local default_hotkeys = {
	{ action = 'p1_cycle', config = 'JOYCODE_1_BUTTON10' },
	{ action = 'p2_cycle', config = 'JOYCODE_2_BUTTON10' },
	{ action = 'both_cycle', config = 'KEYCODE_F8' }
}

-- entry points

local lib = { }

function lib:load_plugin_settings()
	local plugin_settings = { }  -- empty default
	
	-- try to open the plugin settings file
	local filename = settings_path() .. '/' .. plugin_settings_filename()
	local file = io.open(filename, 'r')
	if file then
		-- try parsing settings as JSON
		local json = require('json')
		local settings = json.parse(file:read('a'))
		file:close()
		if not settings then
			emu.print_error(string.format('Error loading plugin settings: error parsing file "%s" as JSON', filename))
		else
			plugin_settings = settings
		end
	end
	
	return plugin_settings
end

function lib:save_plugin_settings(plugin_settings)
	-- make sure the settings path is a folder if it exists
	local path = settings_path()
	local stat = lfs.attributes(path)
	if stat and (stat.mode ~= 'directory') then
		emu.print_error(string.format('Error saving plugin settings: "%s" is not a directory', path))
		return
	end

	if not stat then
		lfs.mkdir(path)
		stat = lfs.attributes(path)
	end

	-- try to write the file
	local filename = path .. '/' .. plugin_settings_filename()
	local json = require('json')
	local text = json.stringify(plugin_settings, { indent = true })
	local file = io.open(filename, 'w')
	if not file then
		emu.print_error(string.format('Error saving plugin settings: error opening file "%s" for writing', filename))
	else
		file:write(text)
		file:close()
	end
end

function lib:load_hotkeys()
	local hotkeys = { }

	-- try to open the hotkeys file
	local filename = settings_path() .. '/' .. hotkeys_filename()
	local file = io.open(filename, 'r')
	if file then
		-- try parsing settings as JSON
		local json = require('json')
		local settings = json.parse(file:read('a'))
		file:close()
		if not settings then
			emu.print_error(string.format('Error loading character variants hotkeys: error parsing file "%s" as JSON', filename))
		else
			-- convert settings to hotkeys with sequences
			local input = manager.machine.input
			for i, hotkey_data in pairs(settings) do
				local hotkey = {
					action = hotkey_data.action,
					config = hotkey_data.config,
					sequence = input:seq_from_tokens(hotkey_data.config),
					pressed = false
				}
				table.insert(hotkeys, hotkey)
			end
		end
	end

	-- if no hotkeys loaded, use defaults
	if #hotkeys == 0 then
		local input = manager.machine.input
		for i, default_hotkey in pairs(default_hotkeys) do
			local hotkey = {
				action = default_hotkey.action,
				config = default_hotkey.config,
				sequence = input:seq_from_tokens(default_hotkey.config),
				pressed = false
			}
			table.insert(hotkeys, hotkey)
		end
	end

	return hotkeys
end

function lib:save_hotkeys(hotkeys)
	-- make sure the settings path is a folder if it exists
	local path = settings_path()
	local stat = lfs.attributes(path)
	if stat and (stat.mode ~= 'directory') then
		emu.print_error(string.format('Error saving character variants hotkeys: "%s" is not a directory', path))
		return
	end

	-- if nothing to save, remove existing hotkeys file
	if #hotkeys == 0 then
		local filename = path .. '/' .. hotkeys_filename()
		os.remove(filename)
	else
		if not stat then
			lfs.mkdir(path)
			stat = lfs.attributes(path)
		end

		-- flatten the hotkeys for saving
		local settings = { }
		for k, hotkey in pairs(hotkeys) do
			table.insert(settings, {
				action = hotkey.action,
				config = hotkey.config
			})
		end

		-- try to write the file
		local filename = path .. '/' .. hotkeys_filename()
		local json = require('json')
		local text = json.stringify(settings, { indent = true })
		local file = io.open(filename, 'w')
		if not file then
			emu.print_error(string.format('Error saving character variants hotkeys: error opening file "%s" for writing', filename))
		else
			file:write(text)
			file:close()
		end
	end
end

return lib