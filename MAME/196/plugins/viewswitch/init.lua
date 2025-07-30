-- viewswitch plugin for MAME 0.196
-- ROM-specific config file support for view switching
-- Based on official MAME viewswitch plugin, adapted for 0.196 API

local exports = {}
exports.name = "viewswitch"
exports.version = "0.5.196"
exports.description = "Switch between layout views with ROM-specific hotkeys - MAME 0.196"
exports.license = "MIT"
exports.author = { name = "viewswitch" }

function exports.startplugin()
    local last_key_states = {}
    local input_manager = nil
    local ui_manager = nil
    local render_targets = nil
    local initialized = false
    local switch_hotkeys = {}
    local current_rom = nil
    
    print("Viewswitch plugin initializing for MAME 0.196...")
    
    -- Helper function to get settings path
    local function settings_path()
        -- Use homepath like the original plugin
        local homepath = manager:machine():options().entries.homepath:value():match('([^;]+)')
        return homepath .. '/viewswitch'
    end
    
    -- Helper function to get config filename for current ROM
    local function settings_filename()
        local rom_name = emu.romname()
        return rom_name .. '.cfg'
    end
    
    -- Load ROM-specific configuration
    local function load_settings()
        switch_hotkeys = {}
        current_rom = emu.romname()
        
        if not current_rom or current_rom == "" or current_rom == "___empty" then
            print("Viewswitch: No ROM loaded, skipping config")
            return
        end
        
        local filename = settings_path() .. '/' .. settings_filename()
        print("Viewswitch: Loading config from: " .. filename)
        
        local file = io.open(filename, 'r')
        if file then
            local content = file:read('a')
            file:close()
            
            -- Try parsing as JSON
            local success, json = pcall(function()
                return require('json')
            end)
            
            if success then
                local settings = json.parse(content)
                if settings and settings[1] and settings[1].switch then
                    print("Viewswitch: Found switch hotkeys in config:")
                    for view_name, key_token in pairs(settings[1].switch) do
                        print("  " .. view_name .. " -> " .. key_token)
                        table.insert(switch_hotkeys, {
                            view_name = view_name,
                            key_token = key_token,
                            view_index = nil  -- Will be resolved later
                        })
                    end
                else
                    print("Viewswitch: Invalid config format")
                end
            else
                print("Viewswitch: JSON library not available, config not loaded")
            end
        else
            print("Viewswitch: No config file found for " .. current_rom)
            
            -- Create a default config file for this ROM
            create_default_config()
        end
    end
    
    -- Create default config for current ROM
    local function create_default_config()
        if not current_rom or current_rom == "" then
            return
        end
        
        -- For the forgotten ROM, create config based on the layout file provided
        local default_config = {}
        
        if current_rom == "forgottn" then
            default_config = {
                switch = {
                    ["Bezel"] = "KEYCODE_1PAD",
                    ["Bezel2"] = "KEYCODE_2PAD"
                }
            }
        else
            -- Generic default - just cycle through views
            default_config = {
                switch = {
                    ["View1"] = "KEYCODE_1PAD",
                    ["View2"] = "KEYCODE_2PAD"
                }
            }
        end
        
        -- Try to save the default config
        local success, json = pcall(function()
            return require('json')
        end)
        
        if success then
            local path = settings_path()
            local stat = lfs and lfs.attributes(path)
            
            if not stat then
                if lfs then
                    lfs.mkdir(path)
                else
                    os.execute('mkdir "' .. path .. '"')  -- Windows fallback
                end
            end
            
            local filename = path .. '/' .. settings_filename()
            local file = io.open(filename, 'w')
            if file then
                local config_array = { default_config }
                file:write(json.stringify(config_array, { indent = true }))
                file:close()
                print("Viewswitch: Created default config: " .. filename)
            end
        end
    end
    
    -- Switch to a specific view by name
    local function switch_to_view(view_name)
        if not render_targets or not render_targets[1] then
            print("Viewswitch: No render target available")
            return
        end
        
        local target = render_targets[1]
        print("Viewswitch: Attempting to switch to view: " .. view_name)
        
        -- For MAME 0.196, we need to map view names to indices
        -- Based on your layout: Bezel=0, Bezel2=1
        local view_map = {
            ["Bezel"] = 0,
            ["Bezel2"] = 1,
            ["View1"] = 0,
            ["View2"] = 1
        }
        
        local target_view = view_map[view_name]
        if target_view == nil then
            print("Viewswitch: Unknown view name: " .. view_name)
            return
        end
        
        local success = pcall(function()
            target.view = target_view
        end)
        
        if success then
            print("Viewswitch: Successfully switched to view " .. target_view .. " (" .. view_name .. ")")
        else
            print("Viewswitch: Failed to switch to view: " .. view_name)
        end
    end
    
    local function frame_done()
        if not initialized or #switch_hotkeys == 0 then
            return
        end
        
        if input_manager and input_manager.seq_pressed then
            -- Check each configured hotkey
            for _, hotkey in ipairs(switch_hotkeys) do
                local success, pressed = pcall(function()
                    local seq = input_manager:seq_from_tokens(hotkey.key_token)
                    if seq then
                        return input_manager:seq_pressed(seq)
                    end
                    return false
                end)
                
                local key_id = hotkey.key_token
                local last_state = last_key_states[key_id] or false
                
                if success and pressed and not last_state then
                    print("Viewswitch: Hotkey " .. hotkey.key_token .. " pressed")
                    switch_to_view(hotkey.view_name)
                    last_key_states[key_id] = true
                elseif not pressed then
                    last_key_states[key_id] = false
                end
            end
        end
    end
    
    local function start()
        print("Viewswitch: Starting plugin...")
        
        local machine = manager:machine()
        if machine then
            input_manager = machine:input()
            ui_manager = manager:ui()
            
            if machine:render() then
                local render = machine:render()
                local ui_target = render:ui_target()
                if ui_target then
                    render_targets = { [1] = ui_target }
                    print("Viewswitch: Got UI render target")
                    
                    -- Show current view
                    local current_view = ui_target.view or 0
                    print("Viewswitch: Current view: " .. current_view)
                else
                    print("Viewswitch: No UI target available")
                end
            else
                print("Viewswitch: No render manager available")
            end
        end
        
        -- Load ROM-specific configuration
        load_settings()
        initialized = true
    end
    
    local function stop()
        print("Viewswitch: Stopping plugin...")
        render_targets = nil
        ui_manager = nil
        input_manager = nil
        initialized = false
        switch_hotkeys = {}
        last_key_states = {}
        current_rom = nil
    end
    
    -- Menu support
    local function menu_populate()
        local menu = {}
        menu[1] = {"ROM-specific View Switch", "", "off"}
        
        if current_rom then
            menu[2] = {"ROM: " .. current_rom, "", "off"}
        end
        
        if #switch_hotkeys > 0 then
            menu[3] = {"---", "", ""}
            for i, hotkey in ipairs(switch_hotkeys) do
                menu[3 + i] = {hotkey.view_name .. " (" .. hotkey.key_token .. ")", "", ""}
            end
        else
            menu[3] = {"No hotkeys configured", "", "off"}
        end
        
        return menu
    end
    
    local function menu_callback(index, event)
        if event == "select" then
            local hotkey_index = index - 3
            if hotkey_index > 0 and hotkey_index <= #switch_hotkeys then
                local hotkey = switch_hotkeys[hotkey_index]
                switch_to_view(hotkey.view_name)
                return true
            end
        end
        return false
    end
    
    -- Register callbacks
    emu.register_frame_done(frame_done)
    emu.register_prestart(start)
    emu.register_stop(stop)
    emu.register_menu(menu_callback, menu_populate, "View Switch")
    
    print("Viewswitch plugin loaded successfully for MAME 0.196")
end

return exports