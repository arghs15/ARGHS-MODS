-- license:BSD-3-Clause
-- copyright-holders:Custom

-- constants

local MENU_TYPES = {
	MAIN = 0,
	HOTKEYS = 1 }

-- helper functions

local function general_input_setting(token)
	return manager.ui:get_general_input_setting(manager.machine.ioport:token_to_input_type(token))
end

-- globals

local menu_stack

local commonui

local hotkeys
local plugin_settings

local hotkey_done
local hotkey_poll

-- hotkeys menu

local function handle_hotkeys(index, event)
	if hotkey_poll then
		-- special handling for entering hotkey
		if hotkey_poll.poller:poll() then
			if hotkey_poll.poller.sequence then
				local hotkey = hotkeys[hotkey_poll.index]
				if hotkey then
					hotkey.sequence = hotkey_poll.poller.sequence
					hotkey.config = manager.machine.input:seq_to_tokens(hotkey_poll.poller.sequence)
				end
			end
			hotkey_poll = nil
			return true
		end
		return false
	end

	if (event == 'back') or ((event == 'select') and (index == hotkey_done)) then
		hotkey_done = nil
		table.remove(menu_stack)
		return true
	else
		-- find which hotkey this index corresponds to
		local hotkey_index = index - 2  -- subtract header lines
		if hotkey_index > 0 and hotkey_index <= #hotkeys then
			if event == 'select' then
				if not commonui then
					commonui = require('commonui')
				end
				hotkey_poll = { index = hotkey_index, poller = commonui.switch_polling_helper() }
				return true
			elseif event == 'clear' then
				-- reset to default
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
	end
	return false
end

local function populate_hotkeys()
	local items = { }

	table.insert(items, { 'Character Variants Hotkeys', '', 'off' })
	table.insert(items, { string.format('Press %s to clear hotkey', general_input_setting('UI_CLEAR')), '', 'off' })

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
		if hotkey_poll and (hotkey_poll.index == i) then
			flags = 'lr'
		end
		table.insert(items, { action_name, seq_name, flags })
	end

	table.insert(items, { '---', '', '' })
	table.insert(items, { 'Done', '', '' })
	hotkey_done = #items

	if hotkey_poll then
		return hotkey_poll.poller:overlay(items)
	else
		return items
	end
end

-- main menu

local function handle_main(index, event)
	if event == 'select' then
		if index == 3 then
			table.insert(menu_stack, MENU_TYPES.HOTKEYS)
			return true
		end
	end
	return false
end

local function populate_main()
	local items = { }

	table.insert(items, { 'Character Variants', '', 'off' })
	table.insert(items, { '---', '', '' })
	table.insert(items, { 'Configure hotkeys', '', '' })

	return items
end

-- entry points

local lib = { }

function lib:init(hotkey_list, settings)
	menu_stack = { MENU_TYPES.MAIN }
	hotkeys = hotkey_list
	plugin_settings = settings or { }
end

function lib:handle_event(index, event)
	local current = menu_stack[#menu_stack]
	if current == MENU_TYPES.MAIN then
		return handle_main(index, event)
	elseif current == MENU_TYPES.HOTKEYS then
		return handle_hotkeys(index, event)
	end
end

function lib:populate()
	local current = menu_stack[#menu_stack]
	if current == MENU_TYPES.MAIN then
		return populate_main()
	elseif current == MENU_TYPES.HOTKEYS then
		return populate_hotkeys()
	end
end

return lib