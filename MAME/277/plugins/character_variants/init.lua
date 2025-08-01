-- license:BSD-3-Clause
-- copyright-holders:Vas Crabb
local exports = {
	name = 'viewswitch',
	version = '0.0.4',
	description = 'Quick view switch plugin',
	license = 'BSD-3-Clause',
	author = { name = 'Vas Crabb' } }

local viewswitch = exports

local stop_subscription

function viewswitch.startplugin()
	local switch_hotkeys = { }
	local cycle_hotkeys = { }
	local excluded_views = { }
	local plugin_settings = { }

	local input_manager
	local ui_manager = { menu_active = true, ui_active = true }
	local render_targets
	local menu_handler

	local function get_next_view(target, current_view, increment)
		local view_names = target.view_names
		local count = #view_names
		local target_index = target.index
		local excluded = excluded_views[target_index] or { }
		
		-- if no exclusions, use original logic
		if not next(excluded) then
			local index = current_view + increment
			return (index < 1) and count or (index > count) and 1 or index
		end
		
		-- find next non-excluded view
		local tries = 0
		local index = current_view
		repeat
			index = index + increment
			if index < 1 then
				index = count
			elseif index > count then
				index = 1
			end
			tries = tries + 1
		until (not excluded[index]) or (tries >= count)
		
		-- if all views are excluded, return current view
		if tries >= count then
			return current_view
		end
		
		return index
	end

	local function frame_done()
		if ui_manager.ui_active and (not ui_manager.menu_active) then
			for k, hotkey in pairs(switch_hotkeys) do
				if input_manager:seq_pressed(hotkey.sequence) then
					render_targets[hotkey.target].view_index = hotkey.view
				end
			end
			for k, hotkey in pairs(cycle_hotkeys) do
				if input_manager:seq_pressed(hotkey.sequence) then
					if not hotkey.pressed then
						local target = render_targets[hotkey.target]
						local next_view = get_next_view(target, target.view_index, hotkey.increment)
						target.view_index = next_view
						hotkey.pressed = true
					end
				else
					hotkey.pressed = false
				end
			end
		end
	end

	local function start()
		local persister = require('viewswitch/viewswitch_persist')
		plugin_settings = persister:load_plugin_settings()
		switch_hotkeys, cycle_hotkeys = persister:load_settings(plugin_settings.config_mode)
		excluded_views = persister:load_excluded_views(plugin_settings.config_mode)

		local machine = manager.machine
		input_manager = machine.input
		ui_manager = manager.ui
		render_targets = machine.render.targets
	end

	local function stop()
		local persister = require('viewswitch/viewswitch_persist')
		persister:save_plugin_settings(plugin_settings)
		persister:save_settings(switch_hotkeys, cycle_hotkeys, plugin_settings.config_mode)
		persister:save_excluded_views(excluded_views, plugin_settings.config_mode)

		menu_handler = nil
		render_targets = nil
		ui_manager = { menu_active = true, ui_active = true }
		input_manager = nil
		switch_hotkeys = { }
		cycle_hotkeys = { }
		excluded_views = { }
		plugin_settings = { }
	end

	local function menu_callback(index, event)
		return menu_handler:handle_event(index, event)
	end

	local function menu_populate()
		if not menu_handler then
			local status, msg = pcall(function () menu_handler = require('viewswitch/viewswitch_menu') end)
			if not status then
				emu.print_error(string.format('Error loading quick view switch menu: %s', msg))
			end
			if menu_handler then
				menu_handler:init(switch_hotkeys, cycle_hotkeys, excluded_views, plugin_settings)
			end
		end
		if menu_handler then
			return menu_handler:populate()
		else
			return { { 'Failed to load quick view switch menu', '', 'off' } }
		end
	end

	emu.register_frame_done(frame_done)
	emu.register_prestart(start)
	stop_subscription = emu.add_machine_stop_notifier(stop)
	emu.register_menu(menu_callback, menu_populate, 'Quick View Switch')
end

return exports