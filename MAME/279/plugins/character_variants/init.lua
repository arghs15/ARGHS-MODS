-- license:BSD-3-Clause
-- copyright-holders:Custom
local exports = {
	name = 'character_variants',
	version = '7.3',
	description = 'Character variant cycling plugin',
	license = 'BSD-3-Clause',
	author = { name = 'Custom' } }

local character_variants = exports

local stop_subscription

function exports.startplugin()
	local hotkeys = { }
	local plugin_settings = { }

	local input_manager
	local ui_manager = { menu_active = true, ui_active = true }
	local menu_handler
	
	-- Global state
	local current_rom = nil
	local rom_module = nil
	local current_frame = 0

	-- Persistence functions (copied from viewswitch approach)
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

	local function load_plugin_settings()
		local settings = { }
		
		local filename = settings_path() .. '/' .. plugin_settings_filename()
		local file = io.open(filename, 'r')
		if file then
			local json = require('json')
			local loaded = json.parse(file:read('a'))
			file:close()
			if loaded then
				settings = loaded
			end
		end
		
		return settings
	end

	local function save_plugin_settings(settings)
		local path = settings_path()
		local stat = lfs.attributes(path)
		if stat and (stat.mode ~= 'directory') then
			return
		end

		if not stat then
			lfs.mkdir(path)
		end

		local filename = path .. '/' .. plugin_settings_filename()
		local json = require('json')
		local text = json.stringify(settings, { indent = true })
		local file = io.open(filename, 'w')
		if file then
			file:write(text)
			file:close()
		end
	end

	local function load_hotkeys()
		local loaded_hotkeys = { }

		local filename = settings_path() .. '/' .. hotkeys_filename()
		local file = io.open(filename, 'r')
		if file then
			local json = require('json')
			local settings = json.parse(file:read('a'))
			file:close()
			if settings then
				local input = manager.machine.input
				for i, hotkey_data in pairs(settings) do
					local hotkey = {
						action = hotkey_data.action,
						config = hotkey_data.config,
						sequence = input:seq_from_tokens(hotkey_data.config),
						pressed = false
					}
					table.insert(loaded_hotkeys, hotkey)
				end
			end
		end

		-- if no hotkeys loaded, use defaults
		if #loaded_hotkeys == 0 then
			local input = manager.machine.input
			for i, default_hotkey in pairs(default_hotkeys) do
				local hotkey = {
					action = default_hotkey.action,
					config = default_hotkey.config,
					sequence = input:seq_from_tokens(default_hotkey.config),
					pressed = false
				}
				table.insert(loaded_hotkeys, hotkey)
			end
		end

		return loaded_hotkeys
	end

	local function save_hotkeys(hotkeys_to_save)
		local path = settings_path()
		local stat = lfs.attributes(path)
		if stat and (stat.mode ~= 'directory') then
			return
		end

		if #hotkeys_to_save == 0 then
			local filename = path .. '/' .. hotkeys_filename()
			os.remove(filename)
		else
			if not stat then
				lfs.mkdir(path)
			end

			local settings = { }
			for k, hotkey in pairs(hotkeys_to_save) do
				table.insert(settings, {
					action = hotkey.action,
					config = hotkey.config
				})
			end

			local filename = path .. '/' .. hotkeys_filename()
			local json = require('json')
			local text = json.stringify(settings, { indent = true })
			local file = io.open(filename, 'w')
			if file then
				file:write(text)
				file:close()
			end
		end
	end

	-- Get current ROM name
	local function get_current_rom()
		if manager and manager.machine and manager.machine.system then
			return manager.machine.system.name
		end
		return nil
	end

	-- Load ROM-specific module
	local function load_rom_module(rom_name)
		print(string.format("Loading module for ROM: %s", rom_name))
		
		-- Method 1: Try RetroArch require() method
		local success, module = pcall(require, "character_variants.games." .. rom_name)
		if success and module then
			print(string.format("Loaded module via require() for %s", rom_name))
			if module.init then
				local init_success = module.init()
				if init_success then
					return module
				end
			else
				return module
			end
		end
		
		-- Method 2: Try MAME file I/O method
		if io and io.open then
			local module_path = string.format("plugins/character_variants/games/%s.lua", rom_name)
			local module_file = io.open(module_path, "r")
			if module_file then
				local module_content = module_file:read("*all")
				module_file:close()
				
				if module_content and module_content ~= "" then
					local module_func, load_error = load(module_content, "@" .. module_path)
					if module_func then
						local exec_success, module = pcall(module_func)
						if exec_success and module then
							if module.init then
								local init_success = module.init()
								if init_success then
									return module
								end
							else
								return module
							end
						end
					end
				end
			end
		end
		
		return nil
	end

	-- Ensure ROM module is loaded
	local function ensure_module_loaded()
		local rom_name = get_current_rom()
		if not rom_name then
			return false
		end
		
		if rom_name ~= current_rom then
			if rom_module and rom_module.cleanup then
				rom_module.cleanup()
			end
			
			current_rom = rom_name
			rom_module = load_rom_module(rom_name)
		end
		
		return rom_module ~= nil
	end

	local function frame_done()
		current_frame = current_frame + 1
		
		if not ensure_module_loaded() then
			return
		end
		
		if rom_module and rom_module.update then
			rom_module.update()
		end

		if ui_manager.ui_active and (not ui_manager.menu_active) then
			for k, hotkey in pairs(hotkeys) do
				if input_manager:seq_pressed(hotkey.sequence) then
					if not hotkey.pressed then
						if hotkey.action == 'p1_cycle' and rom_module.cycle_p1_variant then
							rom_module.cycle_p1_variant()
						elseif hotkey.action == 'p2_cycle' and rom_module.cycle_p2_variant then
							rom_module.cycle_p2_variant()
						elseif hotkey.action == 'both_cycle' then
							if rom_module.cycle_both_variants then
								rom_module.cycle_both_variants()
							elseif rom_module.cycle_p1_variant and rom_module.cycle_p2_variant then
								rom_module.cycle_p1_variant()
								rom_module.cycle_p2_variant()
							end
						end
						hotkey.pressed = true
					end
				else
					hotkey.pressed = false
				end
			end
		end
	end

	local function start()
		plugin_settings = load_plugin_settings()
		hotkeys = load_hotkeys()

		local machine = manager.machine
		input_manager = machine.input
		ui_manager = manager.ui
	end

	local function stop()
		save_plugin_settings(plugin_settings)
		save_hotkeys(hotkeys)

		menu_handler = nil
		ui_manager = { menu_active = true, ui_active = true }
		input_manager = nil
		hotkeys = { }
		plugin_settings = { }
		
		if rom_module and rom_module.cleanup then
			rom_module.cleanup()
		end
		
		rom_module = nil
		current_rom = nil
		current_frame = 0
	end

	local function menu_callback(index, event)
		if menu_handler then
			return menu_handler:handle_event(index, event)
		end
		return false
	end

	local function menu_populate()
		if not menu_handler then
			-- Simple inline menu handler
			menu_handler = {
				poll_input = nil,
				
				handle_event = function(self, index, event)
					if self.poll_input then
						if self.poll_input.poller:poll() then
							if self.poll_input.poller.sequence then
								local hotkey = hotkeys[self.poll_input.hotkey_index]
								if hotkey then
									hotkey.sequence = self.poll_input.poller.sequence
									hotkey.config = manager.machine.input:seq_to_tokens(self.poll_input.poller.sequence)
								end
							end
							self.poll_input = nil
							return true
						end
						return false
					end
					
					if event == 'select' then
						local hotkey_index = index - 2
						if hotkey_index > 0 and hotkey_index <= #hotkeys then
							local commonui = require('commonui')
							self.poll_input = { 
								hotkey_index = hotkey_index,
								poller = commonui.switch_polling_helper() 
							}
							return true
						end
					elseif event == 'clear' then
						local hotkey_index = index - 2
						if hotkey_index > 0 and hotkey_index <= #hotkeys then
							local action = hotkeys[hotkey_index].action
							local defaults = {
								p1_cycle = 'JOYCODE_1_BUTTON10',
								p2_cycle = 'JOYCODE_2_BUTTON10',
								both_cycle = 'KEYCODE_F8'
							}
							if defaults[action] then
								hotkeys[hotkey_index].config = defaults[action]
								hotkeys[hotkey_index].sequence = manager.machine.input:seq_from_tokens(defaults[action])
							end
							return true
						end
					end
					return false
				end,
				
				populate = function(self)
					local items = {}
					
					table.insert(items, { 'Character Variants Hotkeys', '', 'off' })
					table.insert(items, { 'Press UI_CLEAR to reset hotkey', '', 'off' })
					
					local input = manager.machine.input
					for i, hotkey in pairs(hotkeys) do
						local seq_name = 'None'
						if hotkey.sequence then
							seq_name = input:seq_name(hotkey.sequence)
						end
						
						local action_name = hotkey.action
						if action_name == 'p1_cycle' then
							action_name = 'P1 Cycle Variant'
						elseif action_name == 'p2_cycle' then
							action_name = 'P2 Cycle Variant'
						elseif action_name == 'both_cycle' then
							action_name = 'Both Players Cycle'
						end
						
						local flags = ''
						if self.poll_input and (self.poll_input.hotkey_index == i) then
							flags = 'lr'
						end
						table.insert(items, { action_name, seq_name, flags })
					end
					
					if self.poll_input then
						return self.poll_input.poller:overlay(items)
					else
						return items
					end
				end
			}
		end
		
		return menu_handler:populate()
	end

	emu.register_frame_done(frame_done)
	emu.register_prestart(start)
	stop_subscription = emu.add_machine_stop_notifier(stop)
	emu.register_menu(menu_callback, menu_populate, 'Character Variants')
	
	print("Character Variants Plugin loaded!")
end

return exports