-- Character Variants Plugin for MAME - MODULAR SYSTEM
local exports = {}
exports.name = "character_variants"
exports.version = "6.0"
exports.description = "Modular character variant cycling with per-ROM modules"
exports.license = "MIT"
exports.author = { name = "Custom" }

function exports.startplugin()
    print("Character Variants Plugin (MODULAR) initializing...")
    
    -- Configuration
    local config = {
        cycle_key = "KEYCODE_F8",
        p1_cycle_button = "JOYCODE_1_BUTTON8",
        p2_cycle_button = "JOYCODE_2_BUTTON8",
    }
    
    -- Global state
    local current_rom = nil
    local rom_module = nil
    local button_states = { p1_prev = false, p2_prev = false, key_prev = false }
    local debounce_frames = 10  -- Reduced from 15 to 10 frames (about 167ms at 60fps)
    local last_button_frame = { p1 = 0, p2 = 0, key = 0 }
    local current_frame = 0
    
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
        
        -- Try to load the ROM-specific module file directly
        local module_path = string.format("plugins/character_variants/games/%s.lua", rom_name)
        
        -- Read the module file
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
        
        local success, module = pcall(module_func)
        if not success then
            print(string.format("Failed to execute module for %s: %s", rom_name, module))
            return nil
        end
        
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
        
        -- Check input states
        local p1_button_state = false
        local p2_button_state = false
        local key_state = false
        
        if input.seq_pressed then
            local p1_seq = input:seq_from_tokens(config.p1_cycle_button)
            if p1_seq then p1_button_state = input:seq_pressed(p1_seq) end
            
            local p2_seq = input:seq_from_tokens(config.p2_cycle_button)
            if p2_seq then p2_button_state = input:seq_pressed(p2_seq) end
            
            local key_seq = input:seq_from_tokens(config.cycle_key)
            if key_seq then key_state = input:seq_pressed(key_seq) end
        end
        
        -- Handle button presses with debouncing
        if p1_button_state and not button_states.p1_prev and 
           (current_frame - last_button_frame.p1) > debounce_frames then
            if rom_module.cycle_p1_variant then
                print(string.format("DEBUG: P1 button pressed at frame %d", current_frame))
                rom_module.cycle_p1_variant()
                last_button_frame.p1 = current_frame
            end
        elseif p1_button_state and not button_states.p1_prev then
            print(string.format("DEBUG: P1 button debounced (frame %d, last %d, diff %d)", 
                  current_frame, last_button_frame.p1, current_frame - last_button_frame.p1))
        end
        
        if p2_button_state and not button_states.p2_prev and 
           (current_frame - last_button_frame.p2) > debounce_frames then
            if rom_module.cycle_p2_variant then
                print(string.format("DEBUG: P2 button pressed at frame %d", current_frame))
                rom_module.cycle_p2_variant()
                last_button_frame.p2 = current_frame
            end
        elseif p2_button_state and not button_states.p2_prev then
            print(string.format("DEBUG: P2 button debounced (frame %d, last %d, diff %d)", 
                  current_frame, last_button_frame.p2, current_frame - last_button_frame.p2))
        end
        
        if key_state and not button_states.key_prev and 
           (current_frame - last_button_frame.key) > debounce_frames then
            if rom_module.cycle_both_variants then
                print(string.format("DEBUG: F8 key pressed at frame %d", current_frame))
                rom_module.cycle_both_variants()
            elseif rom_module.cycle_p1_variant and rom_module.cycle_p2_variant then
                print(string.format("DEBUG: F8 key pressed (individual cycling) at frame %d", current_frame))
                rom_module.cycle_p1_variant()
                rom_module.cycle_p2_variant()
            end
            last_button_frame.key = current_frame
        elseif key_state and not button_states.key_prev then
            print(string.format("DEBUG: F8 key debounced (frame %d, last %d, diff %d)", 
                  current_frame, last_button_frame.key, current_frame - last_button_frame.key))
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
    
    print("Modular Character Variants Plugin loaded!")
    print("Supports ROM-specific modules in plugins/character_variants/games/")
    print("Controls:")
    print("  P1: " .. config.p1_cycle_button .. " (Right Bumper)")
    print("  P2: " .. config.p2_cycle_button .. " (Right Bumper)")
    print("  Both: " .. config.cycle_key .. " (F8)")
end

return exports