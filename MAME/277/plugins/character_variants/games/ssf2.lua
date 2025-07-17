-- SSF2 Game Module for Character Variants Plugin
local ssf2 = {}

-- Character variants for SSF2 with separate P1/P2 states
local character_variants = {
    -- Ryu: 1 variant (only Ryu 01 available)
    [0x00] = {
        name = "ryu",
        p1_states = {0x00},  -- Ryu 01 only
        p2_states = {0x00}   -- Ryu 01 only
    },
    -- E. Honda: 2 variants
    [0x01] = {
        name = "e_honda",
        p1_states = {0x01, 0x30},  -- E Honda 01 + E Honda 02
        p2_states = {0x01, 0x32}   -- E Honda 01 + E Honda 02 (P2)
    },
    -- Blanka: 1 variant (only Blanka 01 available)
    [0x02] = {
        name = "blanka",
        p1_states = {0x02},  -- Blanka 01 only
        p2_states = {0x02}   -- Blanka 01 only
    },
    -- Guile: 2 variants
    [0x03] = {
        name = "guile",
        p1_states = {0x03, 0x31},  -- Guile 01 + Guile 02
        p2_states = {0x03, 0x33}   -- Guile 01 + Guile 02 (P2)
    },
    -- Ken: 1 variant (only Ken 01 available)
    [0x04] = {
        name = "ken",
        p1_states = {0x04},  -- Ken 01 only
        p2_states = {0x04}   -- Ken 01 only
    },
    -- Chun-Li: 2 variants
    [0x05] = {
        name = "chun_li",
        p1_states = {0x05, 0x32},  -- Chun Li 01 + Chun Li 02
        p2_states = {0x05, 0x34}   -- Chun Li 01 + Chun Li 02 (P2)
    },
    -- Zangief: 3 variants
    [0x06] = {
        name = "zangief",
        p1_states = {0x06, 0x33, 0x34},  -- Zangief 01 + Zangief 02 + Zangief 03
        p2_states = {0x06, 0x35, 0x36}   -- Zangief 01 + Zangief 02 + Zangief 03 (P2)
    },
    -- Dhalsim: 2 variants
    [0x07] = {
        name = "dhalsim",
        p1_states = {0x07, 0x35},  -- Dhalsim 01 + Dhalsim 02
        p2_states = {0x07, 0x37}   -- Dhalsim 01 + Dhalsim 02 (P2)
    },
    -- Balrog: 1 variant (only Balrog 01 available)
    [0x08] = {
        name = "balrog",
        p1_states = {0x08},  -- Balrog 01 only
        p2_states = {0x08}   -- Balrog 01 only
    },
    -- Sagat: 1 variant (only Sagat 01 available)
    [0x09] = {
        name = "sagat",
        p1_states = {0x09},  -- Sagat 01 only
        p2_states = {0x09}   -- Sagat 01 only
    },
    -- Vega: 2 variants
    [0x0A] = {
        name = "vega",
        p1_states = {0x0A, 0x36},  -- Vega 01 + Vega 02
        p2_states = {0x0A, 0x38}   -- Vega 01 + Vega 02 (P2)
    },
    -- M. Bison: 1 variant (only M Bison 01 available)
    [0x0B] = {
        name = "m_bison",
        p1_states = {0x0B},  -- M Bison 01 only
        p2_states = {0x0B}   -- M Bison 01 only
    },
    -- Cammy: 1 variant (only Cammy 01 available)
    [0x0C] = {
        name = "cammy",
        p1_states = {0x0C},  -- Cammy 01 only
        p2_states = {0x0C}   -- Cammy 01 only
    },
    -- T. Hawk: 2 variants
    [0x0D] = {
        name = "t_hawk",
        p1_states = {0x0D, 0x37},  -- T Hawk 01 + T Hawk 02
        p2_states = {0x0D, 0x39}   -- T Hawk 01 + T Hawk 02 (P2)
    },
    -- Fei Long: 1 variant (only Fei Long 01 available)
    [0x0E] = {
        name = "fei_long",
        p1_states = {0x0E},  -- Fei Long 01 only
        p2_states = {0x0E}   -- Fei Long 01 only
    },
    -- Dee Jay: 1 variant (only Dee Jay 01 available)
    [0x0F] = {
        name = "dee_jay",
        p1_states = {0x0F},  -- Dee Jay 01 only
        p2_states = {0x0F}   -- Dee Jay 01 only
    }
}

-- Memory addresses for SSF2 (based on cheat file)
local memory_addresses = {
    game_timer = 0xFF8CCE,    -- Timer from "Infinite Time" cheat (16-bit)
    p1_char = 0xFF875F,       -- P1 character from "P1 Select Character" cheat
    p2_char = 0xFF8B5F,       -- P2 character from "P2 Select Character" cheat
    p1_energy1 = 0xFF83F8,    -- P1 energy addresses
    p1_energy2 = 0xFF858A,
    p2_energy1 = 0xFF87F8,    -- P2 energy addresses
    p2_energy2 = 0xFF898A,
    p1_rounds = 0xFF875E,     -- P1 rounds won
    p2_rounds = 0xFF8B5E,     -- P2 rounds won
    background = 0xFFE08B     -- Background selector
}

-- Variant override memory - using different range for SSF2
local variant_memory = {
    p1_override_active = 0xFFFF30,
    p1_override_state = 0xFFFF31,
    p2_override_active = 0xFFFF32,
    p2_override_state = 0xFFFF33,
}

-- State tracking
local p1_current_variant = {}
local p2_current_variant = {}
local p1_last_character = nil
local p2_last_character = nil

-- Get current characters (based on SSF2 memory layout)
local function get_current_characters()
    if not manager or not manager.machine then
        return nil, nil
    end
    
    local machine = manager.machine
    local cpu = machine.devices[":maincpu"]
    if not cpu then return nil, nil end
    
    local mem = cpu.spaces["program"]
    if not mem then return nil, nil end
    
    -- Always read character data - SSF2 seems to always have valid character IDs
    local p1_char = mem:read_u8(memory_addresses.p1_char)
    local p2_char = mem:read_u8(memory_addresses.p2_char)
    
    -- Only return blank if characters are clearly invalid (beyond normal range)
    if p1_char > 0x0F then p1_char = 0x20 end
    if p2_char > 0x0F then p2_char = 0x20 end
    
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
        print(string.format("SSF2: Cleared P%d variant override", player))
    else
        print(string.format("SSF2: Failed to clear P%d variant override", player))
    end
end

-- Trigger variant display (optimized for speed)
local function trigger_variant_display(player, variant_state)
    if not manager or not manager.machine then return false end
    
    local machine = manager.machine
    local cpu = machine.devices[":maincpu"]
    if not cpu then return false end
    
    local mem = cpu.spaces["program"]
    if not mem then return false end
    
    local override_addr, state_addr
    if player == 1 then
        override_addr = variant_memory.p1_override_active
        state_addr = variant_memory.p1_override_state
    else
        override_addr = variant_memory.p2_override_active
        state_addr = variant_memory.p2_override_state
    end
    
    -- Fast write without verification to reduce delay
    local success = pcall(function() 
        mem:write_u8(override_addr, 1)
        mem:write_u8(state_addr, variant_state)
    end)
    
    if success then
        print(string.format("SSF2: P%d variant set to 0x%02X", player, variant_state))
        return true
    else
        print(string.format("SSF2: P%d variant write failed", player))
        return false
    end
end

-- Cycle character variant
local function cycle_character_variant(player, character_id)
    if not character_variants[character_id] then
        print(string.format("SSF2: P%d character 0x%02X has no variants", player, character_id))
        return
    end
    
    local char_data = character_variants[character_id]
    local states = (player == 1) and char_data.p1_states or char_data.p2_states
    
    if #states <= 1 then
        print(string.format("SSF2: P%d %s has only one variant", 
              player, char_data.name))
        return
    end
    
    local variant_table = (player == 1) and p1_current_variant or p2_current_variant
    
    if not variant_table[character_id] then
        variant_table[character_id] = 1
    end
    
    variant_table[character_id] = (variant_table[character_id] % #states) + 1
    
    local variant_state = states[variant_table[character_id]]
    print(string.format("SSF2: P%d %s variant %d/%d (state 0x%02X)", 
          player, char_data.name, 
          variant_table[character_id], #states, variant_state))
    
    trigger_variant_display(player, variant_state)
end

-- Module API
function ssf2.init()
    print("SSF2 module initialized")
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
                        mem:write_u8(0xFFFF30 + i, 0)
                    end
                    print("SSF2: Cleared variant override memory")
                end)
            end
        end
    end
    
    return true
end

function ssf2.update()
    local p1_char, p2_char = get_current_characters()
    
    if not p1_char or not p2_char then
        return
    end
    
    -- Handle P1 character changes
    if p1_char ~= p1_last_character then
        if p1_last_character and p1_last_character ~= 0x20 and
           p1_char ~= 0x20 and
           p1_char ~= p1_last_character then
            print(string.format("SSF2: P1 switched from 0x%02X to 0x%02X - clearing override", p1_last_character, p1_char))
            clear_variant_override(1)
        end
        p1_last_character = p1_char
    end
    
    -- Handle P2 character changes
    if p2_char ~= p2_last_character then
        if p2_last_character and p2_last_character ~= 0x20 and
           p2_char ~= 0x20 and
           p2_char ~= p2_last_character then
            print(string.format("SSF2: P2 switched from 0x%02X to 0x%02X - clearing override", p2_last_character, p2_char))
            clear_variant_override(2)
        end
        p2_last_character = p2_char
    end
end

function ssf2.cycle_p1_variant()
    local p1_char, _ = get_current_characters()
    
    -- Debug: Also check what's actually in memory
    if manager and manager.machine then
        local machine = manager.machine
        local cpu = machine.devices[":maincpu"]
        if cpu then
            local mem = cpu.spaces["program"]
            if mem then
                local actual_char = mem:read_u8(0xFF875F)
                print(string.format("SSF2: P1 actual memory char: 0x%02X, function returned: 0x%02X", actual_char or 0, p1_char or 0))
                
                -- Use the actual memory value if function failed
                if p1_char == 0x20 and actual_char and actual_char <= 0x0F then
                    p1_char = actual_char
                end
            end
        end
    end
    
    print(string.format("SSF2: P1 character detected as 0x%02X", p1_char or 0))
    if p1_char and p1_char ~= 0x20 and p1_char <= 0x0F then
        cycle_character_variant(1, p1_char)
    else
        print("SSF2: P1 character is invalid or not detected")
    end
end

function ssf2.cycle_p2_variant()
    local _, p2_char = get_current_characters()
    
    -- Debug: Also check what's actually in memory
    if manager and manager.machine then
        local machine = manager.machine
        local cpu = machine.devices[":maincpu"]
        if cpu then
            local mem = cpu.spaces["program"]
            if mem then
                local actual_char = mem:read_u8(0xFF8B5F)
                print(string.format("SSF2: P2 actual memory char: 0x%02X, function returned: 0x%02X", actual_char or 0, p2_char or 0))
                
                -- Use the actual memory value if function failed
                if p2_char == 0x20 and actual_char and actual_char <= 0x0F then
                    p2_char = actual_char
                end
            end
        end
    end
    
    print(string.format("SSF2: P2 character detected as 0x%02X", p2_char or 0))
    if p2_char and p2_char ~= 0x20 and p2_char <= 0x0F then
        cycle_character_variant(2, p2_char)
    else
        print("SSF2: P2 character is invalid or not detected")
    end
end

function ssf2.cycle_both_variants()
    ssf2.cycle_p1_variant()
    ssf2.cycle_p2_variant()
end

function ssf2.cleanup()
    print("SSF2 module cleanup")
    p1_current_variant = {}
    p2_current_variant = {}
    p1_last_character = nil
    p2_last_character = nil
end

-- Debug function to show current game state
function ssf2.debug_state()
    if not manager or not manager.machine then
        print("SSF2: No manager or machine available")
        return
    end
    
    local machine = manager.machine
    local cpu = machine.devices[":maincpu"]
    if not cpu then
        print("SSF2: No CPU device")
        return
    end
    
    local mem = cpu.spaces["program"]
    if not mem then
        print("SSF2: No memory space")
        return
    end
    
    local timer = mem:read_u16(memory_addresses.game_timer)
    local p1_char = mem:read_u8(memory_addresses.p1_char)
    local p2_char = mem:read_u8(memory_addresses.p2_char)
    local p1_energy1 = mem:read_u16(memory_addresses.p1_energy1)
    local p2_energy1 = mem:read_u16(memory_addresses.p2_energy1)
    
    print(string.format("SSF2 Debug - Timer: %d, P1: 0x%02X, P2: 0x%02X, P1 Energy: %d, P2 Energy: %d", 
          timer, p1_char, p2_char, p1_energy1, p2_energy1))
end

return ssf2