-- Character Variants Plugin for MAME - UNIVERSAL SYSTEM with Configuration Menu
local exports = {}
exports.name = "character_variants" 
exports.version = "7.0"
exports.description = "Universal character variant cycling with per-ROM modules and configurable hotkeys"
exports.license = "MIT"
exports.author = { name = "Custom" }

function exports.startplugin()
    print("Character Variants Plugin (UNIVERSAL with Config Menu) initializing...")
    
    -- Default configuration
    local default_config = {
        cycle_key = "KEYCODE_F8",
        p1_cycle_button = "JOYCODE_1_BUTTON10", 
        p2_cycle_button = "JOYCODE_2_BUTTON10",
    }
    
    -- Global state
    local config = {}
    local current_rom = nil
    local rom_module = nil
    local button_states = { p1_prev = false, p2_prev = false, key_prev = false }
    local debounce_frames = 10
    local last_button_frame = { p1 = 0, p2 = 0, key = 0 }
    local current_frame = 0
    local menu_handler = nil
    
    -- Configuration file management
    local function get_config_path()
        return "plugins/character_variants"
    end
    
    local function get_config_filename()
        return "config.json"
    end
    
    local function load_config()
        local config_path = get_config_path()
        local config_file = config_path .. "/" .. get_config_filename()
        
        -- Try to load existing config
        local file = io.open(config_file, "r")
        if file then
            local content = file:read("*all")
            file:close()
            
            if content and content ~= "" then
                -- Try to parse JSON
                local json = require('json')
                local success, loaded_config = pcall(json.parse, content)
                if success and loaded_config then
                    print("Loaded configuration from " .. config_file)
                    return loaded_config
                else
                    print("Failed to parse config file, using defaults")
                end
            end
        end
        
        print("Using default configuration")
        return default_config
    end
    
    local function save_config()
        local config_path = get_config_path()
        local config_file = config_path .. "/" .. get_config_filename()
        
        -- Ensure directory exists
        local stat = lfs.attributes(config_path)
        if not stat then
            lfs.mkdir(config_path)
        elseif stat.mode ~= 'directory' then
            print("Error: " .. config_path .. " exists but is not a directory")
            return false
        end
        
        -- Save config as JSON
        local json = require('json')
        local json_text = json.stringify(config, { indent = true })
        
        local file = io.open(config_file, "w")
        if file then
            file:write(json_text)
            file:close()
            print("Configuration saved to " .. config_file)
            return true
        else
            print("Failed to save configuration to " .. config_file)
            return false
        end
    end
    
    -- Get current ROM name
    local function get_current_rom()
        if manager and manager.machine and manager.machine.system then
            return manager.machine.system.name
        end
        return nil
    end
    
    -- Load ROM-specific module - try both methods
    local function load_rom_module(rom_name)
        print(string.format("Loading module for ROM: %s", rom_name))
        
        -- Method 1: Try RetroArch require() method
        local success, module = pcall(require, "character_variants.games." .. rom_name)
        if success and module then
            print(string.format("Loaded module via require() for %s", rom_name))
            
            -- Initialize the module
            if module.init then
                local init_success = module.init()
                if init_success then
                    print(string.format("Module for %s initialized successfully", rom_name))
                    return module
                else
                    print(string.format("Failed to initialize module for %s", rom_name))
                    return nil
                end
            end
            
            print(string.format("Module for %s loaded successfully (no init function)", rom_name))
            return module
        end
        
        -- Method 2: Try MAME file I/O method
        if io and io.open then
            local module_path = string.format("plugins/character_variants/games/%s.lua", rom_name)
            
            local module_file = io.open(module_path, "r")
            if not module_file then
                print(string.format("No module file found: %s", module_path))
                return nil
            end
            
            local module_content = module_file:read("*all")
            module_file:close()
            
            if not module_content or module_content == "" then
                print(string.format("Module file is empty: %s", module_path))
                return nil
            end
            
            -- Load and execute the module content
            local module_func, load_error = load(module_content, "@" .. module_path)
            if not module_func then
                print(string.format("Failed to load module content for %s: %s", rom_name, load_error))
                return nil
            end
            
            local exec_success, module = pcall(module_func)
            if not exec_success then
                print(string.format("Failed to execute module for %s: %s", rom_name, module))
                return nil
            end
            
            print(string.format("Loaded module via file I/O for %s", rom_name))
            
            -- Initialize the module
            if module and module.init then
                local init_success = module.init()
                if init_success then
                    print(string.format("Module for %s initialized successfully", rom_name))
                    return module
                else
                    print(string.format("Failed to initialize module for %s", rom_name))
                    return nil
                end
            end
            
            if module then
                print(string.format("Module for %s loaded successfully (no init function)", rom_name))
            end
            
            return module
        end
        
        print(string.format("No module could be loaded for %s (both methods failed)", rom_name))
        return nil
    end
    
    -- Ensure ROM module is loaded
    local function ensure_module_loaded()
        local rom_name = get_current_rom()
        if not rom_name then
            return false
        end
        
        -- Only reload if ROM changed
        if rom_name ~= current_rom then
            print(string.format("ROM changed from %s to %s", 
                  tostring(current_rom), rom_name))
            
            -- Cleanup old module
            if rom_module and rom_module.cleanup then
                rom_module.cleanup()
            end
            
            current_rom = rom_name
            rom_module = load_rom_module(rom_name)
            
            if rom_module then
                print(string.format("Loaded module for %s", rom_name))
            else
                print(string.format("No module available for %s", rom_name))
            end
        end
        
        return rom_module ~= nil
    end
    
    -- Menu handling
    local function menu_callback(index, event)
        if menu_handler then
            return menu_handler:handle_event(index, event, config, save_config)
        end
        return false
    end
    
    local function menu_populate()
        if not menu_handler then
            -- Create simple menu handler inline
            menu_handler = {
                poll_input = nil,
                
                handle_event = function(self, index, event, current_config, save_func)
                    if self.poll_input then
                        -- Handle input polling
                        if self.poll_input.poller:poll() then
                            if self.poll_input.poller.sequence then
                                current_config[self.poll_input.setting] = manager.machine.input:seq_to_tokens(self.poll_input.poller.sequence)
                                save_func()
                                print("Updated " .. self.poll_input.setting .. " to " .. manager.machine.input:seq_name(self.poll_input.poller.sequence))
                            end
                            self.poll_input = nil
                            return true
                        end
                        return false
                    end
                    
                    if event == 'select' then
                        if index == 3 then -- P1 Cycle Button
                            local commonui = require('commonui')
                            self.poll_input = { 
                                setting = "p1_cycle_button", 
                                poller = commonui.switch_polling_helper() 
                            }
                            return true
                        elseif index == 4 then -- P2 Cycle Button
                            local commonui = require('commonui')
                            self.poll_input = { 
                                setting = "p2_cycle_button", 
                                poller = commonui.switch_polling_helper() 
                            }
                            return true
                        elseif index == 5 then -- Cycle Key
                            local commonui = require('commonui')
                            self.poll_input = { 
                                setting = "cycle_key", 
                                poller = commonui.switch_polling_helper() 
                            }
                            return true
                        elseif index == 7 then -- Reset to Defaults
                            for k, v in pairs(default_config) do
                                current_config[k] = v
                            end
                            save_func()
                            print("Reset configuration to defaults")
                            return true
                        end
                    end
                    return false
                end,
                
                populate = function(self, current_config)
                    local items = {}
                    local input = manager.machine.input
                    
                    table.insert(items, { 'Character Variants Configuration', '', 'off' })
                    table.insert(items, { '---', '', '' })
                    
                    -- P1 Cycle Button
                    local p1_seq_name = 'Not Set'
                    if current_config.p1_cycle_button then
                        local seq = input:seq_from_tokens(current_config.p1_cycle_button)
                        if seq then
                            p1_seq_name = input:seq_name(seq)
                        end
                    end
                    local p1_flags = ''
                    if self.poll_input and self.poll_input.setting == "p1_cycle_button" then
                        p1_flags = 'lr'
                    end
                    table.insert(items, { 'P1 Cycle Button', p1_seq_name, p1_flags })
                    
                    -- P2 Cycle Button
                    local p2_seq_name = 'Not Set'
                    if current_config.p2_cycle_button then
                        local seq = input:seq_from_tokens(current_config.p2_cycle_button)
                        if seq then
                            p2_seq_name = input:seq_name(seq)
                        end
                    end
                    local p2_flags = ''
                    if self.poll_input and self.poll_input.setting == "p2_cycle_button" then
                        p2_flags = 'lr'
                    end
                    table.insert(items, { 'P2 Cycle Button', p2_seq_name, p2_flags })
                    
                    -- Cycle Key
                    local key_seq_name = 'Not Set'
                    if current_config.cycle_key then
                        local seq = input:seq_from_tokens(current_config.cycle_key)
                        if seq then
                            key_seq_name = input:seq_name(seq)
                        end
                    end
                    local key_flags = ''
                    if self.poll_input and self.poll_input.setting == "cycle_key" then
                        key_flags = 'lr'
                    end
                    table.insert(items, { 'Cycle Key (Both Players)', key_seq_name, key_flags })
                    
                    table.insert(items, { '---', '', '' })
                    table.insert(items, { 'Reset to Defaults', '', '' })
                    
                    if self.poll_input then
                        return self.poll_input.poller:overlay(items)
                    else
                        return items
                    end
                end
            }
        end
        
        if menu_handler then
            return menu_handler:populate(config)
        else
            return { { 'Failed to load character variants menu', '', 'off' } }
        end
    end
    
    -- Initialize configuration
    config = load_config()
    
    -- Main frame callback
    emu.register_frame_done(function()
        current_frame = current_frame + 1
        
        if not ensure_module_loaded() then
            return false
        end
        
        if not manager or not manager.machine or not manager.machine.input then
            return false
        end
        
        local input = manager.machine.input
        
        -- Update the ROM module (for character tracking, etc.)
        if rom_module.update then
            rom_module.update()
        end
        
        -- Check input states using current config
        local p1_button_state = false
        local p2_button_state = false
        local key_state = false
        
        if input.seq_pressed then
            if config.p1_cycle_button then
                local p1_seq = input:seq_from_tokens(config.p1_cycle_button)
                if p1_seq then p1_button_state = input:seq_pressed(p1_seq) end
            end
            
            if config.p2_cycle_button then
                local p2_seq = input:seq_from_tokens(config.p2_cycle_button)
                if p2_seq then p2_button_state = input:seq_pressed(p2_seq) end
            end
            
            if config.cycle_key then
                local key_seq = input:seq_from_tokens(config.cycle_key)
                if key_seq then key_state = input:seq_pressed(key_seq) end
            end
        end
        
        -- Handle button presses with debouncing
        if p1_button_state and not button_states.p1_prev and 
           (current_frame - last_button_frame.p1) > debounce_frames then
            if rom_module.cycle_p1_variant then
                print(string.format("DEBUG: P1 button pressed at frame %d", current_frame))
                rom_module.cycle_p1_variant()
                last_button_frame.p1 = current_frame
            end
        end
        
        if p2_button_state and not button_states.p2_prev and 
           (current_frame - last_button_frame.p2) > debounce_frames then
            if rom_module.cycle_p2_variant then
                print(string.format("DEBUG: P2 button pressed at frame %d", current_frame))
                rom_module.cycle_p2_variant()
                last_button_frame.p2 = current_frame
            end
        end
        
        if key_state and not button_states.key_prev and 
           (current_frame - last_button_frame.key) > debounce_frames then
            if rom_module.cycle_both_variants then
                print(string.format("DEBUG: Cycle key pressed at frame %d", current_frame))
                rom_module.cycle_both_variants()
            elseif rom_module.cycle_p1_variant and rom_module.cycle_p2_variant then
                print(string.format("DEBUG: Cycle key pressed (individual cycling) at frame %d", current_frame))
                rom_module.cycle_p1_variant()
                rom_module.cycle_p2_variant()
            end
            last_button_frame.key = current_frame
        end
        
        button_states.p1_prev = p1_button_state
        button_states.p2_prev = p2_button_state
        button_states.key_prev = key_state
        
        return false
    end)
    
    -- Reset on game stop
    emu.add_machine_stop_notifier(function()
        if rom_module and rom_module.cleanup then
            rom_module.cleanup()
        end
        
        rom_module = nil
        current_rom = nil
        button_states = { p1_prev = false, p2_prev = false, key_prev = false }
        last_button_frame = { p1 = 0, p2 = 0, key = 0 }
        current_frame = 0
        print("Character variants plugin reset")
    end)
    
    -- Register menu
    emu.register_menu(menu_callback, menu_populate, 'Character Variants')
    
    print("Universal Character Variants Plugin loaded!")
    print("Will try both loading methods:")
    print("  1. RetroArch: require('character_variants.games.romname')")
    print("  2. MAME: plugins/character_variants/games/romname.lua")
    print("Current controls:")
    print("  P1: " .. (config.p1_cycle_button or "Not Set"))
    print("  P2: " .. (config.p2_cycle_button or "Not Set"))
    print("  Both: " .. (config.cycle_key or "Not Set"))
    print("Access 'Character Variants' in plugin menu to configure hotkeys!")
end

return exports