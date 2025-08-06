-- SFA Game Module for Character Variants Plugin
local sfa = {}

-- Character variants for SFA with separate P1/P2 states
local character_variants = {
    -- Ryu: 2 variants
    [0x00] = {
        name = "ryu",
        p1_states = {0x00, 0x30},  -- Ryu 01 + Ryu 02
        p2_states = {0x00, 0x32}   -- Ryu 01 + Ryu 02 (P2)
    },
    -- Ken: 2 variants
    [0x01] = {
        name = "ken",
        p1_states = {0x01, 0x31},  -- Ken 01 + Ken 02
        p2_states = {0x01, 0x33}   -- Ken 01 + Ken 02 (P2)
    },
    -- Akuma: 5 variants
    [0x02] = {
        name = "akuma",
        p1_states = {0x02, 0x32, 0x33, 0x34, 0x35},  -- Akuma 01-05
        p2_states = {0x02, 0x34, 0x35, 0x36, 0x37}   -- Akuma 01-05 (P2)
    },
    -- Charlie: 2 variants
    [0x03] = {
        name = "charlie",
        p1_states = {0x03, 0x36},  -- Charlie 01 + Charlie 02
        p2_states = {0x03, 0x38}   -- Charlie 01 + Charlie 02 (P2)
    },
    -- Chun Li: 2 variants
    [0x04] = {
        name = "chun_li",
        p1_states = {0x04, 0x37},  -- Chun Li 01 + Chun Li 02
        p2_states = {0x04, 0x39}   -- Chun Li 01 + Chun Li 02 (P2)
    },
    -- Adon: 2 variants
    [0x05] = {
        name = "adon",
        p1_states = {0x05, 0x38},  -- Adon 01 + Adon 02
        p2_states = {0x05, 0x3A}   -- Adon 01 + Adon 02 (P2)
    },
    -- Sodom: 2 variants
    [0x06] = {
        name = "sodom",
        p1_states = {0x06, 0x39},  -- Sodom 01 + Sodom 02
        p2_states = {0x06, 0x3B}   -- Sodom 01 + Sodom 02 (P2)
    },
    -- Guy: 3 variants
    [0x07] = {
        name = "guy",
        p1_states = {0x07, 0x3A, 0x3B},  -- Guy 01 + Guy 02 + Guy 03
        p2_states = {0x07, 0x3C, 0x3D}   -- Guy 01 + Guy 02 + Guy 03 (P2)
    },
    -- Birdie: 2 variants
    [0x08] = {
        name = "birdie",
        p1_states = {0x08, 0x3C},  -- Birdie 01 + Birdie 02
        p2_states = {0x08, 0x3E}   -- Birdie 01 + Birdie 02 (P2)
    },
    -- Rose: 2 variants
    [0x09] = {
        name = "rose",
        p1_states = {0x09, 0x3D},  -- Rose 01 + Rose 02
        p2_states = {0x09, 0x3F}   -- Rose 01 + Rose 02 (P2)
    },
    -- M. Bison: 3 variants
    [0x0A] = {
        name = "m_bison",
        p1_states = {0x0A, 0x3E, 0x3F},  -- M Bison 01 + M Bison 02 + M Bison 03
        p2_states = {0x0A, 0x40, 0x41}   -- M Bison 01 + M Bison 02 + M Bison 03 (P2)
    },
    -- Sagat: 2 variants
    [0x0B] = {
        name = "sagat",
        p1_states = {0x0B, 0x40},  -- Sagat 01 + Sagat 02
        p2_states = {0x0B, 0x42}   -- Sagat 01 + Sagat 02 (P2)
    },
    -- Dan: 2 variants
    [0x0C] = {
        name = "dan",
        p1_states = {0x0C, 0x41},  -- Dan 01 + Dan 02
        p2_states = {0x0C, 0x43}   -- Dan 01 + Dan 02 (P2)
    }
}

-- Memory addresses for SFA (based on cheat file)
local memory_addresses = {
    game_timer = 0xFFAE09,    -- Timer from "Infinite Time" cheat
    p1_char = 0xFF84A2,       -- P1 character from "P1 Select Character" cheat
    p2_char = 0xFF88A2,       -- P2 character from "P2 Select Character" cheat
    p1_energy = 0xFF8441,     -- P1 energy addresses
    p2_energy = 0xFF8841,     -- P2 energy addresses
    p1_power = 0xFF84BF,      -- P1 power addresses
    p2_power = 0xFF88BF,      -- P2 power addresses
    background = 0xFFAE00     -- Background selector
}

-- Variant override memory - using safer addresses in RAM area
local variant_memory = {
    p1_override_active = 0xFFFF10,
    p1_override_state = 0xFFFF11,
    p2_override_active = 0xFFFF12,
    p2_override_state = 0xFFFF13,
}

-- State tracking
local p1_current_variant = {}
local p2_current_variant = {}
local p1_last_character = nil
local p2_last_character = nil

-- Get current characters (based on SFA memory layout)
local function get_current_characters()
    if not manager or not manager.machine then
        return nil, nil
    end
    
    local machine = manager.machine
    local cpu = machine.devices[":maincpu"]
    if not cpu then return nil, nil end
    
    local mem = cpu.spaces["program"]
    if not mem then return nil, nil end
    
    local p1_char, p2_char = 0x20, 0x20
    
    -- Check if game is active using timer
    local timer = mem:read_u8(memory_addresses.game_timer)
    
    -- If timer is active (not 0 and not max), read character data
    if timer > 0 and timer < 99 then
        p1_char = mem:read_u8(memory_addresses.p1_char)
        p2_char = mem:read_u8(memory_addresses.p2_char)
    end
    
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
        print(string.format("SFA: Cleared P%d variant override", player))
    else
        print(string.format("SFA: Failed to clear P%d variant override", player))
    end
end

-- Trigger variant display
local function trigger_variant_display(player, variant_state)
    if not manager or not manager.machine then 
        print("SFA: No manager or machine")
        return false
    end
    
    local machine = manager.machine
    local cpu = machine.devices[":maincpu"]
    if not cpu then 
        print("SFA: No CPU device")
        return false
    end
    
    local mem = cpu.spaces["program"]
    if not mem then 
        print("SFA: No memory space")
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
            print(string.format("SFA: P%d variant set to 0x%02X - SUCCESS", player, variant_state))
            return true
        else
            print(string.format("SFA: P%d variant write failed verification", player))
            return false
        end
    else
        print(string.format("SFA: Memory write failed - %s", tostring(error_msg)))
        return false
    end
end

-- Cycle character variant
local function cycle_character_variant(player, character_id)
    if not character_variants[character_id] then
        print(string.format("SFA: P%d character 0x%02X has no variants", player, character_id))
        return
    end
    
    local char_data = character_variants[character_id]
    local states = (player == 1) and char_data.p1_states or char_data.p2_states
    
    if #states <= 1 then
        print(string.format("SFA: P%d %s has only one variant", 
              player, char_data.name))
        return
    end
    
    local variant_table = (player == 1) and p1_current_variant or p2_current_variant
    
    if not variant_table[character_id] then
        variant_table[character_id] = 1
    end
    
    variant_table[character_id] = (variant_table[character_id] % #states) + 1
    
    local variant_state = states[variant_table[character_id]]
    print(string.format("SFA: P%d %s variant %d/%d (state 0x%02X)", 
          player, char_data.name, 
          variant_table[character_id], #states, variant_state))
    
    trigger_variant_display(player, variant_state)
end

-- Module API
function sfa.init()
    print("SFA module initialized")
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
                        mem:write_u8(0xFFFF10 + i, 0)
                    end
                    print("SFA: Cleared variant override memory")
                end)
            end
        end
    end
    
    return true
end

function sfa.update()
    local p1_char, p2_char = get_current_characters()
    
    if not p1_char or not p2_char then
        return
    end
    
    -- Handle P1 character changes
    if p1_char ~= p1_last_character then
        if p1_last_character and p1_last_character ~= 0x20 and
           p1_char ~= 0x20 and
           p1_char ~= p1_last_character then
            print(string.format("SFA: P1 switched from 0x%02X to 0x%02X - clearing override", p1_last_character, p1_char))
            clear_variant_override(1)
        end
        p1_last_character = p1_char
    end
    
    -- Handle P2 character changes
    if p2_char ~= p2_last_character then
        if p2_last_character and p2_last_character ~= 0x20 and
           p2_char ~= 0x20 and
           p2_char ~= p2_last_character then
            print(string.format("SFA: P2 switched from 0x%02X to 0x%02X - clearing override", p2_last_character, p2_char))
            clear_variant_override(2)
        end
        p2_last_character = p2_char
    end
end

function sfa.cycle_p1_variant()
    local p1_char, _ = get_current_characters()
    print(string.format("SFA: P1 character detected as 0x%02X", p1_char or 0))
    if p1_char and p1_char ~= 0x20 then
        cycle_character_variant(1, p1_char)
    else
        print("SFA: P1 character is invalid or not detected")
    end
end

function sfa.cycle_p2_variant()
    local _, p2_char = get_current_characters()
    print(string.format("SFA: P2 character detected as 0x%02X", p2_char or 0))
    if p2_char and p2_char ~= 0x20 then
        cycle_character_variant(2, p2_char)
    else
        print("SFA: P2 character is invalid or not detected")
    end
end

function sfa.cycle_both_variants()
    sfa.cycle_p1_variant()
    sfa.cycle_p2_variant()
end

function sfa.cleanup()
    print("SFA module cleanup")
    p1_current_variant = {}
    p2_current_variant = {}
    p1_last_character = nil
    p2_last_character = nil
end

-- Debug function to show current game state
function sfa.debug_state()
    if not manager or not manager.machine then
        print("SFA: No manager or machine available")
        return
    end
    
    local machine = manager.machine
    local cpu = machine.devices[":maincpu"]
    if not cpu then
        print("SFA: No CPU device")
        return
    end
    
    local mem = cpu.spaces["program"]
    if not mem then
        print("SFA: No memory space")
        return
    end
    
    local timer = mem:read_u8(memory_addresses.game_timer)
    local p1_char = mem:read_u8(memory_addresses.p1_char)
    local p2_char = mem:read_u8(memory_addresses.p2_char)
    local p1_energy = mem:read_u8(memory_addresses.p1_energy)
    local p2_energy = mem:read_u8(memory_addresses.p2_energy)
    
    print(string.format("SFA Debug - Timer: %d, P1: 0x%02X, P2: 0x%02X, P1 Energy: %d, P2 Energy: %d", 
          timer, p1_char, p2_char, p1_energy, p2_energy))
end

return sfa