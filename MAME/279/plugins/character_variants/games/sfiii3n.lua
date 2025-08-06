-- SFIII3N Game Module for Character Variants Plugin
local sfiii3n = {}

-- Character variants for SFIII3N with identical P1/P2 states (like SFA2)
local character_variants = {
    -- Alex: 2 variants
    [0x01] = {
        name = "alex",
        p1_states = {0x01, 0x34},  -- Alex 01, Alex 02
        p2_states = {0x01, 0x34}   -- Same states for P2!
    },
    -- Dudley: 2 variants
    [0x04] = {
        name = "dudley",
        p1_states = {0x04, 0x38},  -- Dudley 01, Dudley 02
        p2_states = {0x04, 0x38}   -- Same states for P2!
    },
    -- Hugo: 2 variants
    [0x06] = {
        name = "hugo",
        p1_states = {0x06, 0x3C},  -- Hugo 01, Hugo 02
        p2_states = {0x06, 0x3C}   -- Same states for P2!
    },
    -- Ibuki: 2 variants
    [0x07] = {
        name = "ibuki",
        p1_states = {0x07, 0x40},  -- Ibuki 01, Ibuki 02
        p2_states = {0x07, 0x40}   -- Same states for P2!
    },
    -- Oro: 2 variants
    [0x09] = {
        name = "oro",
        p1_states = {0x09, 0x44},  -- Oro 01, Oro 02
        p2_states = {0x09, 0x44}   -- Same states for P2!
    },
    -- Yang: 2 variants
    [0x0A] = {
        name = "yang",
        p1_states = {0x0A, 0x4C},  -- Yang 01, Yang 02
        p2_states = {0x0A, 0x4C}   -- Same states for P2!
    },
    -- Akuma: 2 variants (special consecutive states)
    [0x0E] = {
        name = "akuma",
        p1_states = {0x0E, 0x0F},  -- Akuma 01, Akuma 02
        p2_states = {0x0E, 0x0F}   -- Same states for P2!
    },
    -- Q: 2 variants
    [0x12] = {
        name = "q",
        p1_states = {0x12, 0x48},  -- Q 01, Q 02
        p2_states = {0x12, 0x48}   -- Same states for P2!
    },
    -- Characters with only one variant (no alternates)
    [0x00] = {
        name = "gill",
        p1_states = {0x00},  -- Gill 01 only
        p2_states = {0x00}   -- Same states for P2!
    },
    [0x02] = {
        name = "ryu",
        p1_states = {0x02},  -- Ryu 01 only
        p2_states = {0x02}   -- Same states for P2!
    },
    [0x03] = {
        name = "yun",
        p1_states = {0x03},  -- Yun 01 only
        p2_states = {0x03}   -- Same states for P2!
    },
    [0x05] = {
        name = "necro",
        p1_states = {0x05},  -- Necro 01 only
        p2_states = {0x05}   -- Same states for P2!
    },
    [0x08] = {
        name = "elena",
        p1_states = {0x08},  -- Elena 01 only
        p2_states = {0x08}   -- Same states for P2!
    },
    [0x0B] = {
        name = "ken",
        p1_states = {0x0B},  -- Ken 01 only
        p2_states = {0x0B}   -- Same states for P2!
    },
    [0x0C] = {
        name = "sean",
        p1_states = {0x0C},  -- Sean 01 only
        p2_states = {0x0C}   -- Same states for P2!
    },
    [0x0D] = {
        name = "urien",
        p1_states = {0x0D},  -- Urien 01 only
        p2_states = {0x0D}   -- Same states for P2!
    },
    [0x10] = {
        name = "chun_li",
        p1_states = {0x10},  -- Chun Li 01 only
        p2_states = {0x10}   -- Same states for P2!
    },
    [0x11] = {
        name = "makoto",
        p1_states = {0x11},  -- Makoto 01 only
        p2_states = {0x11}   -- Same states for P2!
    },
    [0x13] = {
        name = "twelve",
        p1_states = {0x13},  -- Twelve 01 only
        p2_states = {0x13}   -- Same states for P2!
    },
    [0x14] = {
        name = "remy",
        p1_states = {0x14},  -- Remy 01 only
        p2_states = {0x14}   -- Same states for P2!
    }
}

-- Memory addresses
local memory_addresses = {
    game_active = {0x20154c6, 0x20154c7, 0x20154c8, 0x20154c9},
    p1_char = 0x2011387,
    p2_char = 0x2011388
}

-- Variant override memory - USING KNOWN WRITABLE RANGE FROM CHEATS
local variant_memory = {
    p1_override_active = 0x2007FF0,
    p1_override_state = 0x2007FF1,
    p2_override_active = 0x2007FF2,
    p2_override_state = 0x2007FF3,
}

-- State tracking
local p1_current_variant = {}
local p2_current_variant = {}
local p1_last_character = nil
local p2_last_character = nil

-- Check if game is active
local function is_game_active()
    if not manager or not manager.machine then
        return false
    end
    
    local machine = manager.machine
    local cpu = machine.devices[":maincpu"]
    if not cpu then return false end
    
    local mem = cpu.spaces["program"]
    if not mem then return false end
    
    -- Check any of the game active memory addresses
    for _, addr in ipairs(memory_addresses.game_active) do
        if mem:read_u8(addr) > 0 then
            return true
        end
    end
    
    return false
end

-- Get current characters
local function get_current_characters()
    if not manager or not manager.machine then
        return nil, nil
    end
    
    local machine = manager.machine
    local cpu = machine.devices[":maincpu"]
    if not cpu then return nil, nil end
    
    local mem = cpu.spaces["program"]
    if not mem then return nil, nil end
    
    local p1_char, p2_char = 0xFF, 0xFF
    
    if is_game_active() then
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
        print(string.format("SFIII3N: Cleared P%d variant override", player))
        
        -- Verify the clear worked
        local check = mem:read_u8(override_addr)
        if check ~= 0 then
            print(string.format("SFIII3N: WARNING - Override clear failed, still reads 0x%02X", check))
        end
    else
        print(string.format("SFIII3N: Failed to clear P%d variant override", player))
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
        print(string.format("SFIII3N: P%d variant set to 0x%02X", player, variant_state))
        return true
    else
        print(string.format("SFIII3N: P%d variant write failed", player))
        return false
    end
end

-- Cycle character variant
local function cycle_character_variant(player, character_id)
    if not character_variants[character_id] then
        print(string.format("SFIII3N: P%d character 0x%02X has no variants", player, character_id))
        return
    end
    
    local char_data = character_variants[character_id]
    local states = (player == 1) and char_data.p1_states or char_data.p2_states
    
    if #states <= 1 then
        print(string.format("SFIII3N: P%d %s has only one variant", 
              player, char_data.name))
        return
    end
    
    local variant_table = (player == 1) and p1_current_variant or p2_current_variant
    
    if not variant_table[character_id] then
        variant_table[character_id] = 1
    end
    
    variant_table[character_id] = (variant_table[character_id] % #states) + 1
    
    local variant_state = states[variant_table[character_id]]
    print(string.format("SFIII3N: P%d %s variant %d/%d (state 0x%02X)", 
          player, char_data.name, 
          variant_table[character_id], #states, variant_state))
    
    trigger_variant_display(player, variant_state)
end

-- Module API
function sfiii3n.init()
    print("SFIII3N module initialized")
    p1_current_variant = {}
    p2_current_variant = {}
    p1_last_character = nil
    p2_last_character = nil
    return true
end

function sfiii3n.update()
    local p1_char, p2_char = get_current_characters()
    
    if not p1_char or not p2_char then
        return
    end
    
    -- Only clear overrides when switching to a DIFFERENT character (not just any change)
    if p1_char ~= p1_last_character then
        -- Only clear if we're switching from one real character to a different real character
        if p1_last_character and p1_last_character ~= 0xFF and
           p1_char ~= 0xFF and
           p1_char ~= p1_last_character then
            print(string.format("SFIII3N: P1 switched from 0x%02X to 0x%02X - clearing override", p1_last_character, p1_char))
            clear_variant_override(1)
        end
        p1_last_character = p1_char
    end
    
    if p2_char ~= p2_last_character then
        -- Only clear if we're switching from one real character to a different real character
        if p2_last_character and p2_last_character ~= 0xFF and
           p2_char ~= 0xFF and
           p2_char ~= p2_last_character then
            print(string.format("SFIII3N: P2 switched from 0x%02X to 0x%02X - clearing override", p2_last_character, p2_char))
            clear_variant_override(2)
        end
        p2_last_character = p2_char
    end
end

function sfiii3n.cycle_p1_variant()
    local p1_char, _ = get_current_characters()
    print(string.format("SFIII3N: P1 character detected as 0x%02X", p1_char or 0))
    if p1_char and p1_char ~= 0xFF then
        cycle_character_variant(1, p1_char)
    else
        print("SFIII3N: P1 character is invalid or not detected")
    end
end

function sfiii3n.cycle_p2_variant()
    local _, p2_char = get_current_characters()
    print(string.format("SFIII3N: P2 character detected as 0x%02X", p2_char or 0))
    if p2_char and p2_char ~= 0xFF then
        cycle_character_variant(2, p2_char)
    else
        print("SFIII3N: P2 character is invalid or not detected")
    end
end

function sfiii3n.cycle_both_variants()
    sfiii3n.cycle_p1_variant()
    sfiii3n.cycle_p2_variant()
end

function sfiii3n.cleanup()
    print("SFIII3N module cleanup")
    p1_current_variant = {}
    p2_current_variant = {}
    p1_last_character = nil
    p2_last_character = nil
end

return sfiii3n