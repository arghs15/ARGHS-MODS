-- SFA3 Game Module for Character Variants Plugin
local sfa3 = {}

-- Character variants for SFA3 with complex P1/P2 state patterns
local character_variants = {
    -- Ryu: 3 variants (+4 offset pattern)
    [0x00] = {
        name = "ryu",
        p1_states = {0x00, 0x9C, 0x9E},  -- Ryu 01, Ryu 02, Ryu 03
        p2_states = {0x00, 0xA0, 0xA2}   -- Ryu 01, Ryu 02, Ryu 03 (P2)
    },
    -- Ken: 2 variants (+2 offset pattern)
    [0x01] = {
        name = "ken",
        p1_states = {0x01, 0x7C},  -- Ken 01, Ken 02
        p2_states = {0x01, 0x7E}   -- Ken 01, Ken 02 (P2)
    },
    -- Akuma: 4 variants (+6 offset pattern)
    [0x02] = {
        name = "akuma",
        p1_states = {0x02, 0x38, 0x3A, 0x3C},  -- Akuma 01-04
        p2_states = {0x02, 0x3E, 0x40, 0x42}   -- Akuma 01-04 (P2)
    },
    -- Charlie: 1 variant (no variants found in layout)
    [0x03] = {
        name = "charlie",
        p1_states = {0x03},  -- Charlie 01 only
        p2_states = {0x03}   -- Charlie 01 only
    },
    -- Chun-Li: 2 variants (+2 offset pattern)
    [0x04] = {
        name = "chun_li",
        p1_states = {0x04, 0x50},  -- Chun Li 01, Chun Li 02
        p2_states = {0x04, 0x52}   -- Chun Li 01, Chun Li 02 (P2)
    },
    -- Adon: 2 variants (+2 offset pattern)
    [0x05] = {
        name = "adon",
        p1_states = {0x05, 0x34},  -- Adon 01, Adon 02
        p2_states = {0x05, 0x36}   -- Adon 01, Adon 02 (P2)
    },
    -- Sodom: 2 variants (+2 offset pattern)
    [0x06] = {
        name = "sodom",
        p1_states = {0x06, 0xAC},  -- Sodom 01, Sodom 02
        p2_states = {0x06, 0xAE}   -- Sodom 01, Sodom 02 (P2)
    },
    -- Guy: 2 variants (+2 offset pattern)
    [0x07] = {
        name = "guy",
        p1_states = {0x07, 0x70},  -- Guy 01, Guy 02
        p2_states = {0x07, 0x72}   -- Guy 01, Guy 02 (P2)
    },
    -- Birdie: 2 variants (+2 offset pattern)
    [0x08] = {
        name = "birdie",
        p1_states = {0x08, 0x44},  -- Birdie 01, Birdie 02
        p2_states = {0x08, 0x46}   -- Birdie 01, Birdie 02 (P2)
    },
    -- Rose: 2 variants (+2 offset pattern)
    [0x09] = {
        name = "rose",
        p1_states = {0x09, 0x98},  -- Rose 01, Rose 02
        p2_states = {0x09, 0x9A}   -- Rose 01, Rose 02 (P2)
    },
    -- M.Bison: 3 variants (+4 offset pattern)
    [0x0A] = {
        name = "m_bison",
        p1_states = {0x0A, 0x88, 0x8A},  -- M Bison 01-03
        p2_states = {0x0A, 0x8C, 0x8E}   -- M Bison 01-03 (P2)
    },
    -- Sagat: 2 variants (+2 offset pattern)
    [0x0B] = {
        name = "sagat",
        p1_states = {0x0B, 0xA4},  -- Sagat 01, Sagat 02
        p2_states = {0x0B, 0xA6}   -- Sagat 01, Sagat 02 (P2)
    },
    -- Dan: 3 variants (+4 offset pattern)
    [0x0C] = {
        name = "dan",
        p1_states = {0x0C, 0x58, 0x5A},  -- Dan 01-03
        p2_states = {0x0C, 0x5C, 0x5E}   -- Dan 01-03 (P2)
    },
    -- Sakura: 2 variants (+2 offset pattern)
    [0x0D] = {
        name = "sakura",
        p1_states = {0x0D, 0xA8},  -- Sakura 01, Sakura 02
        p2_states = {0x0D, 0xAA}   -- Sakura 01, Sakura 02 (P2)
    },
    -- Rolento: 3 variants (+4 offset pattern)
    [0x0E] = {
        name = "rolento",
        p1_states = {0x0E, 0x90, 0x92},  -- Rolento 01-03
        p2_states = {0x0E, 0x94, 0x96}   -- Rolento 01-03 (P2)
    },
    -- Dhalsim: 3 variants (+4 offset pattern)
    [0x0F] = {
        name = "dhalsim",
        p1_states = {0x0F, 0x60, 0x62},  -- Dhalsim 01-03
        p2_states = {0x0F, 0x64, 0x66}   -- Dhalsim 01-03 (P2)
    },
    -- Zangief: 2 variants (+2 offset pattern)
    [0x10] = {
        name = "zangief",
        p1_states = {0x10, 0xBC},  -- Zangief 01, Zangief 02
        p2_states = {0x10, 0xBE}   -- Zangief 01, Zangief 02 (P2)
    },
    -- Gen: 3 variants (+2 offset pattern)
    [0x11] = {
        name = "gen",
        p1_states = {0x11, 0x13, 0x6C},  -- Gen 01, Gen 02, Gen 03
        p2_states = {0x11, 0x13, 0x6E}   -- Gen 01, Gen 02, Gen 03 (P2)
    },
    -- Balrog: 3 variants (+1 offset pattern - unique!)
    [0x15] = {
        name = "balrog",
        p1_states = {0x15, 0xC0, 0xC2},  -- Balrog 01-03
        p2_states = {0x15, 0xC1, 0xC3}   -- Balrog 01-03 (P2)
    },
    -- Cammy: 2 variants (+2 offset pattern)
    [0x16] = {
        name = "cammy",
        p1_states = {0x16, 0x4C},  -- Cammy 01, Cammy 02
        p2_states = {0x16, 0x4E}   -- Cammy 01, Cammy 02 (P2)
    },
    -- E.Honda: 2 variants (+2 offset pattern)
    [0x18] = {
        name = "e_honda",
        p1_states = {0x18, 0x68},  -- E Honda 01, E Honda 02
        p2_states = {0x18, 0x6A}   -- E Honda 01, E Honda 02 (P2)
    },
    -- Blanka: 2 variants (+2 offset pattern)
    [0x19] = {
        name = "blanka",
        p1_states = {0x19, 0x48},  -- Blanka 01, Blanka 02
        p2_states = {0x19, 0x4A}   -- Blanka 01, Blanka 02 (P2)
    },
    -- R.Mika: 3 variants (+4 offset pattern)
    [0x1A] = {
        name = "r_mika",
        p1_states = {0x1A, 0x80, 0x82},  -- R Mika 01-03
        p2_states = {0x1A, 0x84, 0x86}   -- R Mika 01-03 (P2)
    },
    -- Cody: 2 variants (+2 offset pattern)
    [0x1B] = {
        name = "cody",
        p1_states = {0x1B, 0x54},  -- Cody 01, Cody 02
        p2_states = {0x1B, 0x56}   -- Cody 01, Cody 02 (P2)
    },
    -- Vega: 4 variants (+6 offset pattern)
    [0x1C] = {
        name = "vega",
        p1_states = {0x1C, 0xB0, 0xB2, 0xB4},  -- Vega 01-04
        p2_states = {0x1C, 0xB6, 0xB8, 0xBA}   -- Vega 01-04 (P2)
    },
    -- Karin: 3 variants (+4 offset pattern)
    [0x1D] = {
        name = "karin",
        p1_states = {0x1D, 0x74, 0x76},  -- Karin 01-03
        p2_states = {0x1D, 0x78, 0x7A}   -- Karin 01-03 (P2)
    },
    -- Juli: 2 variants (+1 offset pattern - unique!)
    [0x1E] = {
        name = "juli",
        p1_states = {0x1E, 0xC4},  -- Juli 01, Juli 02
        p2_states = {0x1E, 0xC5}   -- Juli 01, Juli 02 (P2)
    },
    -- Juni: 3 variants (+1 offset pattern - unique!)
    [0x1F] = {
        name = "juni",
        p1_states = {0x1F, 0xC6, 0xC8},  -- Juni 01-03
        p2_states = {0x1F, 0xC7, 0xC9}   -- Juni 01-03 (P2)
    }
}

-- Memory addresses for SFA3 (based on the original layout)
local memory_addresses = {
    game_state1 = 0xff8550,
    game_state2 = 0xff06b8, 
    game_state3 = 0xff8640,
    game_state4 = 0xff86B0,
    game_state5 = 0xFF02EC,
    p1_char = 0xFF8502,
    p2_char = 0xFF8902
}

-- Variant override memory - trying a different range to avoid conflicts
local variant_memory = {
    p1_override_active = 0xFF9100,
    p1_override_state = 0xFF9101,
    p2_override_active = 0xFF9102,
    p2_override_state = 0xFF9103,
}

-- State tracking
local p1_current_variant = {}
local p2_current_variant = {}
local p1_last_character = nil
local p2_last_character = nil

-- Get current characters (based on original SFA3 logic)
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
    
    -- Use SFA3 game detection logic
    if mem:read_u16(memory_addresses.game_state1) > 0 or 
       mem:read_u16(memory_addresses.game_state2) == 65535 or 
       mem:read_u8(memory_addresses.game_state3) == 1 then
        p1_char = mem:read_u8(memory_addresses.p1_char)
        p2_char = mem:read_u8(memory_addresses.p2_char)
    elseif mem:read_u16(memory_addresses.game_state2) ~= 65535 and 
           mem:read_u16(memory_addresses.game_state2) ~= 0 and 
           mem:read_u16(memory_addresses.game_state4) == 0 and 
           mem:read_u16(memory_addresses.game_state5) == 192 and
           mem:read_u16(memory_addresses.game_state2) ~= 57456 then
        p1_char = mem:read_u8(memory_addresses.p1_char)
        p2_char = 0x20
    elseif mem:read_u16(memory_addresses.game_state2) ~= 65535 and 
           mem:read_u16(memory_addresses.game_state2) ~= 0 and 
           mem:read_u16(memory_addresses.game_state4) == 0 and 
           mem:read_u16(memory_addresses.game_state5) == 192 and
           mem:read_u16(memory_addresses.game_state2) == 57456 then
        p1_char = 0x20
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
        print(string.format("SFA3: Cleared P%d variant override", player))
    else
        print(string.format("SFA3: Failed to clear P%d variant override", player))
    end
end

-- Trigger variant display
local function trigger_variant_display(player, variant_state)
    if not manager or not manager.machine then 
        print("SFA3: No manager or machine")
        return false
    end
    
    local machine = manager.machine
    local cpu = machine.devices[":maincpu"]
    if not cpu then 
        print("SFA3: No CPU device")
        return false
    end
    
    local mem = cpu.spaces["program"]
    if not mem then 
        print("SFA3: No memory space")
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
            print(string.format("SFA3: P%d variant set to 0x%02X - SUCCESS", player, variant_state))
            return true
        else
            print(string.format("SFA3: P%d variant write failed verification", player))
            return false
        end
    else
        print(string.format("SFA3: Memory write failed - %s", tostring(error_msg)))
        return false
    end
end

-- Cycle character variant
local function cycle_character_variant(player, character_id)
    if not character_variants[character_id] then
        print(string.format("SFA3: P%d character 0x%02X has no variants", player, character_id))
        return
    end
    
    local char_data = character_variants[character_id]
    local states = (player == 1) and char_data.p1_states or char_data.p2_states
    
    if #states <= 1 then
        print(string.format("SFA3: P%d %s has only one variant", 
              player, char_data.name))
        return
    end
    
    local variant_table = (player == 1) and p1_current_variant or p2_current_variant
    
    if not variant_table[character_id] then
        variant_table[character_id] = 1
    end
    
    variant_table[character_id] = (variant_table[character_id] % #states) + 1
    
    local variant_state = states[variant_table[character_id]]
    print(string.format("SFA3: P%d %s variant %d/%d (state 0x%02X)", 
          player, char_data.name, 
          variant_table[character_id], #states, variant_state))
    
    trigger_variant_display(player, variant_state)
end

-- Module API
function sfa3.init()
    print("SFA3 module initialized")
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
                        mem:write_u8(0xFF9100 + i, 0)
                    end
                    print("SFA3: Cleared variant override memory")
                end)
            end
        end
    end
    
    return true
end

function sfa3.update()
    local p1_char, p2_char = get_current_characters()
    
    if not p1_char or not p2_char then
        return
    end
    
    if p1_char ~= p1_last_character then
        if p1_last_character and p1_last_character ~= 0x20 and
           p1_char ~= 0x20 and
           p1_char ~= p1_last_character then
            print(string.format("SFA3: P1 switched from 0x%02X to 0x%02X - clearing override", p1_last_character, p1_char))
            clear_variant_override(1)
        end
        p1_last_character = p1_char
    end
    
    if p2_char ~= p2_last_character then
        if p2_last_character and p2_last_character ~= 0x20 and
           p2_char ~= 0x20 and
           p2_char ~= p2_last_character then
            print(string.format("SFA3: P2 switched from 0x%02X to 0x%02X - clearing override", p2_last_character, p2_char))
            clear_variant_override(2)
        end
        p2_last_character = p2_char
    end
end

function sfa3.cycle_p1_variant()
    local p1_char, _ = get_current_characters()
    print(string.format("SFA3: P1 character detected as 0x%02X", p1_char or 0))
    if p1_char and p1_char ~= 0x20 then
        cycle_character_variant(1, p1_char)
    else
        print("SFA3: P1 character is invalid or not detected")
    end
end

function sfa3.cycle_p2_variant()
    local _, p2_char = get_current_characters()
    print(string.format("SFA3: P2 character detected as 0x%02X", p2_char or 0))
    if p2_char and p2_char ~= 0x20 then
        cycle_character_variant(2, p2_char)
    else
        print("SFA3: P2 character is invalid or not detected")
    end
end

function sfa3.cycle_both_variants()
    sfa3.cycle_p1_variant()
    sfa3.cycle_p2_variant()
end

function sfa3.cleanup()
    print("SFA3 module cleanup")
    p1_current_variant = {}
    p2_current_variant = {}
    p1_last_character = nil
    p2_last_character = nil
end

return sfa3