-- SSF2XJ Game Module for Character Variants Plugin
local ssf2xj = {}

-- Character variants for SSF2XJ with separate P1/P2 states (same massive offsets as SSF2T!)
local character_variants = {
    -- Ryu: 2 variants (+18 offset pattern)
    [0x00] = {
        name = "ryu",
        p1_states = {0x00, 0x30},  -- Ryu 01 + Ryu 02
        p2_states = {0x00, 0x42}   -- Ryu 01 + Ryu 02 (P2: +18)
    },
    -- E. Honda: 2 variants (+18 offset pattern)
    [0x01] = {
        name = "e_honda",
        p1_states = {0x01, 0x31},  -- E Honda 01 + E Honda 02
        p2_states = {0x01, 0x43}   -- E Honda 01 + E Honda 02 (P2: +18)
    },
    -- Blanka: 2 variants (+18 offset pattern)
    [0x02] = {
        name = "blanka",
        p1_states = {0x02, 0x32},  -- Blanka 01 + Blanka 02
        p2_states = {0x02, 0x44}   -- Blanka 01 + Blanka 02 (P2: +18)
    },
    -- Guile: 2 variants (+18 offset pattern)
    [0x03] = {
        name = "guile",
        p1_states = {0x03, 0x33},  -- Guile 01 + Guile 02
        p2_states = {0x03, 0x45}   -- Guile 01 + Guile 02 (P2: +18)
    },
    -- Ken: 2 variants (+18 offset pattern)
    [0x04] = {
        name = "ken",
        p1_states = {0x04, 0x34},  -- Ken 01 + Ken 02
        p2_states = {0x04, 0x46}   -- Ken 01 + Ken 02 (P2: +18)
    },
    -- Chun Li: 2 variants (+18 offset pattern)
    [0x05] = {
        name = "chun_li",
        p1_states = {0x05, 0x35},  -- Chun Li 01 + Chun Li 02
        p2_states = {0x05, 0x47}   -- Chun Li 01 + Chun Li 02 (P2: +18)
    },
    -- Zangief: 3 variants (+18 offset pattern)
    [0x06] = {
        name = "zangief",
        p1_states = {0x06, 0x36, 0x37},  -- Zangief 01 + Zangief 02 + Zangief 03
        p2_states = {0x06, 0x48, 0x49}   -- Zangief 01 + Zangief 02 + Zangief 03 (P2: +18)
    },
    -- Dhalsim: 2 variants (+18 offset pattern)
    [0x07] = {
        name = "dhalsim",
        p1_states = {0x07, 0x38},  -- Dhalsim 01 + Dhalsim 02
        p2_states = {0x07, 0x4A}   -- Dhalsim 01 + Dhalsim 02 (P2: +18)
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
    -- Balrog: 2 variants (+18 offset pattern)
    [0x0A] = {
        name = "balrog",
        p1_states = {0x0A, 0x39},  -- Balrog 01 + Balrog 02
        p2_states = {0x0A, 0x4B}   -- Balrog 01 + Balrog 02 (P2: +18)
    },
    -- Vega: 2 variants (+18 offset pattern)
    [0x0B] = {
        name = "vega",
        p1_states = {0x0B, 0x3A},  -- Vega 01 + Vega 02
        p2_states = {0x0B, 0x4C}   -- Vega 01 + Vega 02 (P2: +18)
    },
    -- Cammy: 2 variants (+18 offset pattern)
    [0x0C] = {
        name = "cammy",
        p1_states = {0x0C, 0x3B},  -- Cammy 01 + Cammy 02
        p2_states = {0x0C, 0x4D}   -- Cammy 01 + Cammy 02 (P2: +18)
    },
    -- T. Hawk: 2 variants (+18 offset pattern)
    [0x0D] = {
        name = "t_hawk",
        p1_states = {0x0D, 0x3C},  -- T Hawk 01 + T Hawk 02
        p2_states = {0x0D, 0x4E}   -- T Hawk 01 + T Hawk 02 (P2: +18)
    },
    -- Fei Long: 2 variants (+18 offset pattern)
    [0x0E] = {
        name = "fei_long",
        p1_states = {0x0E, 0x3D},  -- Fei Long 01 + Fei Long 02
        p2_states = {0x0E, 0x4F}   -- Fei Long 01 + Fei Long 02 (P2: +18)
    },
    -- Dee Jay: 1 variant
    [0x0F] = {
        name = "dee_jay",
        p1_states = {0x0F},  -- Dee Jay 01 only
        p2_states = {0x0F}   -- Dee Jay 01 only
    },
    -- Akuma: 3 variants (special character ID 0x10, +16 offset pattern)
    [0x10] = {
        name = "akuma",
        p1_states = {0x10, 0x40, 0x41},  -- Akuma 01 + Akuma 02 + Akuma 03
        p2_states = {0x10, 0x50, 0x51}   -- Akuma 01 + Akuma 02 + Akuma 03 (P2: +16)
    }
}

-- Memory addresses for SSF2XJ (based on cheat file)
local memory_addresses = {
    game_timer = 0xFF8DCE,    -- Timer from "Infinite Time" cheat (16-bit)
    p1_char = 0xFF87DF,       -- P1 character from "P1 Select Character" cheat
    p2_char = 0xFF8BDF,       -- P2 character from "P2 Select Character" cheat
    p1_akuma = 0xFF880B,      -- P1 Akuma flag
    p2_akuma = 0xFF8C0B,      -- P2 Akuma flag
    p1_energy1 = 0xFF8478,    -- P1 energy addresses
    p1_energy2 = 0xFF860A,
    p2_energy1 = 0xFF8878,    -- P2 energy addresses
    p2_energy2 = 0xFF8A0A,
    p1_sets = 0xFF87DE,       -- P1 sets won
    p2_sets = 0xFF8BDE,       -- P2 sets won
    background = 0xFFE18A     -- Background selector
}

-- Variant override memory - using different range for SSF2XJ
local variant_memory = {
    p1_override_active = 0xFFFF80,
    p1_override_state = 0xFFFF81,
    p2_override_active = 0xFFFF82,
    p2_override_state = 0xFFFF83,
}

-- State tracking
local p1_current_variant = {}
local p2_current_variant = {}
local p1_last_character = nil
local p2_last_character = nil

-- Get current characters (based on SSF2XJ memory layout)
local function get_current_characters()
    if not manager or not manager.machine then
        return nil, nil
    end
    
    local machine = manager.machine
    local cpu = machine.devices[":maincpu"]
    if not cpu then return nil, nil end
    
    local mem = cpu.spaces["program"]
    if not mem then return nil, nil end
    
    -- Check for Akuma first, then regular characters
    local p1_akuma = mem:read_u8(memory_addresses.p1_akuma)
    local p2_akuma = mem:read_u8(memory_addresses.p2_akuma)
    
    local p1_char, p2_char
    
    if p1_akuma == 1 then
        p1_char = 0x10  -- Akuma special ID
    else
        p1_char = mem:read_u8(memory_addresses.p1_char)
        if p1_char > 0x0F then p1_char = 0x20 end
    end
    
    if p2_akuma == 1 then
        p2_char = 0x10  -- Akuma special ID
    else
        p2_char = mem:read_u8(memory_addresses.p2_char)
        if p2_char > 0x0F then p2_char = 0x20 end
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
        print(string.format("SSF2XJ: Cleared P%d variant override", player))
    else
        print(string.format("SSF2XJ: Failed to clear P%d variant override", player))
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
        print(string.format("SSF2XJ: P%d variant set to 0x%02X", player, variant_state))
        return true
    else
        print(string.format("SSF2XJ: P%d variant write failed", player))
        return false
    end
end

-- Cycle character variant
local function cycle_character_variant(player, character_id)
    if not character_variants[character_id] then
        print(string.format("SSF2XJ: P%d character 0x%02X has no variants", player, character_id))
        return
    end
    
    local char_data = character_variants[character_id]
    local states = (player == 1) and char_data.p1_states or char_data.p2_states
    
    if #states <= 1 then
        if #states == 0 then
            print(string.format("SSF2XJ: P%d %s has no image files available", 
                  player, char_data.name))
        else
            print(string.format("SSF2XJ: P%d %s has only one variant", 
                  player, char_data.name))
        end
        return
    end
    
    local variant_table = (player == 1) and p1_current_variant or p2_current_variant
    
    if not variant_table[character_id] then
        variant_table[character_id] = 1
    end
    
    variant_table[character_id] = (variant_table[character_id] % #states) + 1
    
    local variant_state = states[variant_table[character_id]]
    print(string.format("SSF2XJ: P%d %s variant %d/%d (state 0x%02X)", 
          player, char_data.name, 
          variant_table[character_id], #states, variant_state))
    
    trigger_variant_display(player, variant_state)
end

-- Module API
function ssf2xj.init()
    print("SSF2XJ module initialized")
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
                        mem:write_u8(0xFFFF80 + i, 0)
                    end
                    print("SSF2XJ: Cleared variant override memory")
                end)
            end
        end
    end
    
    return true
end

function ssf2xj.update()
    local p1_char, p2_char = get_current_characters()
    
    if not p1_char or not p2_char then
        return
    end
    
    -- Handle P1 character changes
    if p1_char ~= p1_last_character then
        if p1_last_character and p1_last_character ~= 0x20 and
           p1_char ~= 0x20 and
           p1_char ~= p1_last_character then
            print(string.format("SSF2XJ: P1 switched from 0x%02X to 0x%02X - clearing override", p1_last_character, p1_char))
            clear_variant_override(1)
        end
        p1_last_character = p1_char
    end
    
    -- Handle P2 character changes
    if p2_char ~= p2_last_character then
        if p2_last_character and p2_last_character ~= 0x20 and
           p2_char ~= 0x20 and
           p2_char ~= p2_last_character then
            print(string.format("SSF2XJ: P2 switched from 0x%02X to 0x%02X - clearing override", p2_last_character, p2_char))
            clear_variant_override(2)
        end
        p2_last_character = p2_char
    end
end

function ssf2xj.cycle_p1_variant()
    local p1_char, _ = get_current_characters()
    
    -- Debug: Also check what's actually in memory
    if manager and manager.machine then
        local machine = manager.machine
        local cpu = machine.devices[":maincpu"]
        if cpu then
            local mem = cpu.spaces["program"]
            if mem then
                local actual_char = mem:read_u8(0xFF87DF)
                local actual_akuma = mem:read_u8(0xFF880B)
                print(string.format("SSF2XJ: P1 actual memory char: 0x%02X, akuma: %d, function returned: 0x%02X", 
                      actual_char or 0, actual_akuma or 0, p1_char or 0))
                
                -- Use the actual memory value if function failed
                if p1_char == 0x20 then
                    if actual_akuma == 1 then
                        p1_char = 0x10
                    elseif actual_char and actual_char <= 0x0F then
                        p1_char = actual_char
                    end
                end
            end
        end
    end
    
    print(string.format("SSF2XJ: P1 character detected as 0x%02X", p1_char or 0))
    if p1_char and p1_char ~= 0x20 and (p1_char <= 0x0F or p1_char == 0x10) then
        cycle_character_variant(1, p1_char)
    else
        print("SSF2XJ: P1 character is invalid or not detected")
    end
end

function ssf2xj.cycle_p2_variant()
    local _, p2_char = get_current_characters()
    
    -- Debug: Also check what's actually in memory
    if manager and manager.machine then
        local machine = manager.machine
        local cpu = machine.devices[":maincpu"]
        if cpu then
            local mem = cpu.spaces["program"]
            if mem then
                local actual_char = mem:read_u8(0xFF8BDF)
                local actual_akuma = mem:read_u8(0xFF8C0B)
                print(string.format("SSF2XJ: P2 actual memory char: 0x%02X, akuma: %d, function returned: 0x%02X", 
                      actual_char or 0, actual_akuma or 0, p2_char or 0))
                
                -- Use the actual memory value if function failed
                if p2_char == 0x20 then
                    if actual_akuma == 1 then
                        p2_char = 0x10
                    elseif actual_char and actual_char <= 0x0F then
                        p2_char = actual_char
                    end
                end
            end
        end
    end
    
    print(string.format("SSF2XJ: P2 character detected as 0x%02X", p2_char or 0))
    if p2_char and p2_char ~= 0x20 and (p2_char <= 0x0F or p2_char == 0x10) then
        cycle_character_variant(2, p2_char)
    else
        print("SSF2XJ: P2 character is invalid or not detected")
    end
end

function ssf2xj.cycle_both_variants()
    ssf2xj.cycle_p1_variant()
    ssf2xj.cycle_p2_variant()
end

function ssf2xj.cleanup()
    print("SSF2XJ module cleanup")
    p1_current_variant = {}
    p2_current_variant = {}
    p1_last_character = nil
    p2_last_character = nil
end

-- Debug function to show current game state
function ssf2xj.debug_state()
    if not manager or not manager.machine then
        print("SSF2XJ: No manager or machine available")
        return
    end
    
    local machine = manager.machine
    local cpu = machine.devices[":maincpu"]
    if not cpu then
        print("SSF2XJ: No CPU device")
        return
    end
    
    local mem = cpu.spaces["program"]
    if not mem then
        print("SSF2XJ: No memory space")
        return
    end
    
    local timer = mem:read_u16(memory_addresses.game_timer)
    local p1_char = mem:read_u8(memory_addresses.p1_char)
    local p2_char = mem:read_u8(memory_addresses.p2_char)
    local p1_akuma = mem:read_u8(memory_addresses.p1_akuma)
    local p2_akuma = mem:read_u8(memory_addresses.p2_akuma)
    local p1_energy1 = mem:read_u16(memory_addresses.p1_energy1)
    local p2_energy1 = mem:read_u16(memory_addresses.p2_energy1)
    
    print(string.format("SSF2XJ Debug - Timer: %d, P1: 0x%02X(Akuma:%d), P2: 0x%02X(Akuma:%d), P1 Energy: %d, P2 Energy: %d", 
          timer, p1_char, p1_akuma, p2_char, p2_akuma, p1_energy1, p2_energy1))
end

return ssf2xj