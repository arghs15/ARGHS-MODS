-- HSF2 Game Module for Character Variants Plugin
local hsf2 = {}

-- Character variants for HSF2 with separate P1/P2 states
local character_variants = {
    -- Ryu: 2 variants
    [0x00] = {
        name = "ryu",
        p1_states = {0x00, 0x30},  -- Ryu 01 + Ryu 02
        p2_states = {0x00, 0x32}   -- Ryu 01 + Ryu 02 (P2)
    },
    -- E. Honda: 2 variants
    [0x01] = {
        name = "e_honda",
        p1_states = {0x01, 0x31},  -- E Honda 01 + E Honda 02
        p2_states = {0x01, 0x33}   -- E Honda 01 + E Honda 02 (P2)
    },
    -- Blanka: 2 variants
    [0x02] = {
        name = "blanka",
        p1_states = {0x02, 0x32},  -- Blanka 01 + Blanka 02
        p2_states = {0x02, 0x34}   -- Blanka 01 + Blanka 02 (P2)
    },
    -- Guile: 2 variants
    [0x03] = {
        name = "guile",
        p1_states = {0x03, 0x33},  -- Guile 01 + Guile 02
        p2_states = {0x03, 0x35}   -- Guile 01 + Guile 02 (P2)
    },
    -- Ken: 2 variants
    [0x04] = {
        name = "ken",
        p1_states = {0x04, 0x34},  -- Ken 01 + Ken 02
        p2_states = {0x04, 0x36}   -- Ken 01 + Ken 02 (P2)
    },
    -- Chun-Li: 2 variants
    [0x05] = {
        name = "chun_li",
        p1_states = {0x05, 0x35},  -- Chun Li 01 + Chun Li 02
        p2_states = {0x05, 0x37}   -- Chun Li 01 + Chun Li 02 (P2)
    },
    -- Zangief: 3 variants
    [0x06] = {
        name = "zangief",
        p1_states = {0x06, 0x36, 0x37},  -- Zangief 01 + Zangief 02 + Zangief 03
        p2_states = {0x06, 0x38, 0x39}   -- Zangief 01 + Zangief 02 + Zangief 03 (P2)
    },
    -- Dhalsim: 2 variants
    [0x07] = {
        name = "dhalsim",
        p1_states = {0x07, 0x38},  -- Dhalsim 01 + Dhalsim 02
        p2_states = {0x07, 0x3A}   -- Dhalsim 01 + Dhalsim 02 (P2)
    },
    -- M. Bison: 1 variant
    [0x08] = {
        name = "m_bison",
        p1_states = {0x08},  -- M Bison 01 only
        p2_states = {0x08}   -- M Bison 01 only
    },
    -- Sagat: 1 variant
    [0x09] = {
        name = "sagat",
        p1_states = {0x09},  -- Sagat 01 only
        p2_states = {0x09}   -- Sagat 01 only
    },
    -- Balrog: 2 variants
    [0x0A] = {
        name = "balrog",
        p1_states = {0x0A, 0x39},  -- Balrog 01 + Balrog 02
        p2_states = {0x0A, 0x3B}   -- Balrog 01 + Balrog 02 (P2)
    },
    -- Vega: 2 variants
    [0x0B] = {
        name = "vega",
        p1_states = {0x0B, 0x3A},  -- Vega 01 + Vega 02
        p2_states = {0x0B, 0x3C}   -- Vega 01 + Vega 02 (P2)
    },
    -- Cammy: 2 variants
    [0x0C] = {
        name = "cammy",
        p1_states = {0x0C, 0x3B},  -- Cammy 01 + Cammy 02
        p2_states = {0x0C, 0x3D}   -- Cammy 01 + Cammy 02 (P2)
    },
    -- T. Hawk: 2 variants
    [0x0D] = {
        name = "t_hawk",
        p1_states = {0x0D, 0x3C},  -- T Hawk 01 + T Hawk 02
        p2_states = {0x0D, 0x3E}   -- T Hawk 01 + T Hawk 02 (P2)
    },
    -- Fei Long: 2 variants
    [0x0E] = {
        name = "fei_long",
        p1_states = {0x0E, 0x3D},  -- Fei Long 01 + Fei Long 02
        p2_states = {0x0E, 0x3F}   -- Fei Long 01 + Fei Long 02 (P2)
    },
    -- Dee Jay: 1 variant
    [0x0F] = {
        name = "dee_jay",
        p1_states = {0x0F},  -- Dee Jay 01 only
        p2_states = {0x0F}   -- Dee Jay 01 only
    },
    -- Akuma: 3 variants
    [0x10] = {
        name = "akuma",
        p1_states = {0x10, 0x3E, 0x3F},  -- Akuma 01 + Akuma 02 + Akuma 03
        p2_states = {0x10, 0x40, 0x41}   -- Akuma 01 + Akuma 02 + Akuma 03 (P2)
    }
}

-- Memory addresses for HSF2 (based on cheat file)
local memory_addresses = {
    game_timer = 0xFF8BFC,    -- Timer from "Infinite Time" cheat (16-bit)
    p1_char = 0xFF8667,       -- P1 character from "P1 Select Character" cheat
    p2_char = 0xFF8A67,       -- P2 character from "P2 Select Character" cheat
    p1_energy1 = 0xFF8366,    -- P1 energy addresses
    p1_energy2 = 0xFF84F8,
    p2_energy1 = 0xFF8766,    -- P2 energy addresses
    p2_energy2 = 0xFF88F8,
    p1_power = 0xFF85F0,      -- P1 power addresses
    p2_power = 0xFF89F0,      -- P2 power addresses
    background = 0xFF8B64     -- Background selector
}

-- Variant override memory - using different range for HSF2
local variant_memory = {
    p1_override_active = 0xFFFF20,
    p1_override_state = 0xFFFF21,
    p2_override_active = 0xFFFF22,
    p2_override_state = 0xFFFF23,
}

-- State tracking
local p1_current_variant = {}
local p2_current_variant = {}
local p1_last_character = nil
local p2_last_character = nil

-- Get current characters (based on HSF2 memory layout)
local function get_current_characters()
    if not manager or not manager.machine then
        return nil, nil
    end
    
    local machine = manager.machine
    local cpu = machine.devices[":maincpu"]
    if not cpu then return nil, nil end
    
    local mem = cpu.spaces["program"]
    if not mem then return nil, nil end
    
    -- Always read character data - HSF2 seems to always have valid character IDs
    local p1_char = mem:read_u8(memory_addresses.p1_char)
    local p2_char = mem:read_u8(memory_addresses.p2_char)
    
    -- Only return blank if characters are clearly invalid (beyond normal range)
    if p1_char > 0x10 then p1_char = 0x20 end
    if p2_char > 0x10 then p2_char = 0x20 end
    
    return p1_char, p2_char
end

-- Clear variant override
local function clear_variant_override(player)
    if not manager or not manager.machine then return end
    
    local machine = manager.machine
    local cpu = machine.devices[":maincpu"]
    if not cpu then return end
    
    local mem = cpu.spaces["program"]
    if not mem then return end
    
    local override_addr = (player == 1) and variant_memory.p1_override_active or variant_memory.p2_override_active
    
    if pcall(function() 
        mem:write_u8(override_addr, 0)
    end) then
        print(string.format("HSF2: Cleared P%d variant override", player))
    else
        print(string.format("HSF2: Failed to clear P%d variant override", player))
    end
end

-- Trigger variant display
local function trigger_variant_display(player, variant_state)
    if not manager or not manager.machine then 
        print("HSF2: No manager or machine")
        return false
    end
    
    local machine = manager.machine
    local cpu = machine.devices[":maincpu"]
    if not cpu then 
        print("HSF2: No CPU device")
        return false
    end
    
    local mem = cpu.spaces["program"]
    if not mem then 
        print("HSF2: No memory space")
        return false
    end
    
    local override_addr, state_addr
    
    if player == 1 then
        override_addr = variant_memory.p1_override_active
        state_addr = variant_memory.p1_override_state
    else
        override_addr = variant_memory.p2_override_active
        state_addr = variant_memory.p2_override_state
    end
    
    -- Try to write with better error handling
    local write_success = false
    local error_msg = ""
    
    write_success, error_msg = pcall(function() 
        mem:write_u8(override_addr, 1)
        mem:write_u8(state_addr, variant_state)
        return true
    end)
    
    if write_success then
        -- Verify the write worked
        local verify_success, verify_msg = pcall(function()
            local check_override = mem:read_u8(override_addr)
            local check_state = mem:read_u8(state_addr)
            return check_override == 1 and check_state == variant_state
        end)
        
        if verify_success and verify_msg then
            print(string.format("HSF2: P%d variant set to 0x%02X - SUCCESS", player, variant_state))
            return true
        else
            print(string.format("HSF2: P%d variant write failed verification", player))
            return false
        end
    else
        print(string.format("HSF2: Memory write failed - %s", tostring(error_msg)))
        return false
    end
end

-- Cycle character variant
local function cycle_character_variant(player, character_id)
    if not character_variants[character_id] then
        print(string.format("HSF2: P%d character 0x%02X has no variants", player, character_id))
        return
    end
    
    local char_data = character_variants[character_id]
    local states = (player == 1) and char_data.p1_states or char_data.p2_states
    
    if #states <= 1 then
        print(string.format("HSF2: P%d %s has only one variant", 
              player, char_data.name))
        return
    end
    
    local variant_table = (player == 1) and p1_current_variant or p2_current_variant
    
    if not variant_table[character_id] then
        variant_table[character_id] = 1
    end
    
    variant_table[character_id] = (variant_table[character_id] % #states) + 1
    
    local variant_state = states[variant_table[character_id]]
    print(string.format("HSF2: P%d %s variant %d/%d (state 0x%02X)", 
          player, char_data.name, 
          variant_table[character_id], #states, variant_state))
    
    trigger_variant_display(player, variant_state)
end

-- Module API
function hsf2.init()
    print("HSF2 module initialized")
    p1_current_variant = {}
    p2_current_variant = {}
    p1_last_character = nil
    p2_last_character = nil
    
    -- Clear memory on startup
    if manager and manager.machine then
        local machine = manager.machine
        local cpu = machine.devices[":maincpu"]
        if cpu then
            local mem = cpu.spaces["program"]
            if mem then
                pcall(function()
                    for i = 0, 15 do
                        mem:write_u8(0xFFFF20 + i, 0)
                    end
                    print("HSF2: Cleared variant override memory")
                end)
            end
        end
    end
    
    return true
end

function hsf2.update()
    local p1_char, p2_char = get_current_characters()
    
    if not p1_char or not p2_char then
        return
    end
    
    -- Handle P1 character changes
    if p1_char ~= p1_last_character then
        if p1_last_character and p1_last_character ~= 0x20 and
           p1_char ~= 0x20 and
           p1_char ~= p1_last_character then
            print(string.format("HSF2: P1 switched from 0x%02X to 0x%02X - clearing override", p1_last_character, p1_char))
            clear_variant_override(1)
        end
        p1_last_character = p1_char
    end
    
    -- Handle P2 character changes
    if p2_char ~= p2_last_character then
        if p2_last_character and p2_last_character ~= 0x20 and
           p2_char ~= 0x20 and
           p2_char ~= p2_last_character then
            print(string.format("HSF2: P2 switched from 0x%02X to 0x%02X - clearing override", p2_last_character, p2_char))
            clear_variant_override(2)
        end
        p2_last_character = p2_char
    end
end

function hsf2.cycle_p1_variant()
    local p1_char, _ = get_current_characters()
    
    -- Debug: Also check what's actually in memory
    if manager and manager.machine then
        local machine = manager.machine
        local cpu = machine.devices[":maincpu"]
        if cpu then
            local mem = cpu.spaces["program"]
            if mem then
                local actual_char = mem:read_u8(0xFF8667)
                print(string.format("HSF2: P1 actual memory char: 0x%02X, function returned: 0x%02X", actual_char or 0, p1_char or 0))
                
                -- Use the actual memory value if function failed
                if p1_char == 0x20 and actual_char and actual_char <= 0x10 then
                    p1_char = actual_char
                end
            end
        end
    end
    
    print(string.format("HSF2: P1 character detected as 0x%02X", p1_char or 0))
    if p1_char and p1_char ~= 0x20 and p1_char <= 0x10 then
        cycle_character_variant(1, p1_char)
    else
        print("HSF2: P1 character is invalid or not detected")
    end
end

function hsf2.cycle_p2_variant()
    local _, p2_char = get_current_characters()
    
    -- Debug: Also check what's actually in memory
    if manager and manager.machine then
        local machine = manager.machine
        local cpu = machine.devices[":maincpu"]
        if cpu then
            local mem = cpu.spaces["program"]
            if mem then
                local actual_char = mem:read_u8(0xFF8A67)
                print(string.format("HSF2: P2 actual memory char: 0x%02X, function returned: 0x%02X", actual_char or 0, p2_char or 0))
                
                -- Use the actual memory value if function failed
                if p2_char == 0x20 and actual_char and actual_char <= 0x10 then
                    p2_char = actual_char
                end
            end
        end
    end
    
    print(string.format("HSF2: P2 character detected as 0x%02X", p2_char or 0))
    if p2_char and p2_char ~= 0x20 and p2_char <= 0x10 then
        cycle_character_variant(2, p2_char)
    else
        print("HSF2: P2 character is invalid or not detected")
    end
end

function hsf2.cycle_both_variants()
    hsf2.cycle_p1_variant()
    hsf2.cycle_p2_variant()
end

function hsf2.cleanup()
    print("HSF2 module cleanup")
    p1_current_variant = {}
    p2_current_variant = {}
    p1_last_character = nil
    p2_last_character = nil
end

-- Debug function to show current game state
function hsf2.debug_state()
    if not manager or not manager.machine then
        print("HSF2: No manager or machine available")
        return
    end
    
    local machine = manager.machine
    local cpu = machine.devices[":maincpu"]
    if not cpu then
        print("HSF2: No CPU device")
        return
    end
    
    local mem = cpu.spaces["program"]
    if not mem then
        print("HSF2: No memory space")
        return
    end
    
    local timer = mem:read_u16(memory_addresses.game_timer)
    local p1_char = mem:read_u8(memory_addresses.p1_char)
    local p2_char = mem:read_u8(memory_addresses.p2_char)
    local p1_energy1 = mem:read_u16(memory_addresses.p1_energy1)
    local p2_energy1 = mem:read_u16(memory_addresses.p2_energy1)
    
    print(string.format("HSF2 Debug - Timer: %d, P1: 0x%02X, P2: 0x%02X, P1 Energy: %d, P2 Energy: %d", 
          timer, p1_char, p2_char, p1_energy1, p2_energy1))
end

return hsf2