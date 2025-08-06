-- XMCOTA Game Module for Character Variants Plugin
local xmcota = {}

-- Character variants with left/right state pairs (matching corrected layout file)
local character_variants = {
    -- Wolverine: 01, 02
    [0x00] = {
        name = "wolverine",
        states = {
            {left = 0x00, right = 0x00},  -- Wolverine 01
            {left = 0x30, right = 0x32}   -- Wolverine 02
        }
    },
    -- Psylocke: 01, 02
    [0x02] = {
        name = "psylocke",
        states = {
            {left = 0x02, right = 0x02},  -- Psylocke 01
            {left = 0x34, right = 0x36}   -- Psylocke 02
        }
    },
    -- Colossus: 01, 02
    [0x04] = {
        name = "colossus",
        states = {
            {left = 0x04, right = 0x04},  -- Colossus 01
            {left = 0x38, right = 0x3A}   -- Colossus 02
        }
    },
    -- Cyclops: 01, 02
    [0x06] = {
        name = "cyclops",
        states = {
            {left = 0x06, right = 0x06},  -- Cyclops 01
            {left = 0x3C, right = 0x3E}   -- Cyclops 02
        }
    },
    -- Storm: 01, 02
    [0x08] = {
        name = "storm",
        states = {
            {left = 0x08, right = 0x08},  -- Storm 01
            {left = 0x40, right = 0x42}   -- Storm 02
        }
    },
    -- Iceman: 01, 02
    [0x0A] = {
        name = "iceman",
        states = {
            {left = 0x0A, right = 0x0A},  -- Iceman 01
            {left = 0x44, right = 0x46}   -- Iceman 02
        }
    },
    -- Spiral: 01, 02, 03
    [0x0C] = {
        name = "spiral",
        states = {
            {left = 0x0C, right = 0x0C},  -- Spiral 01
            {left = 0x48, right = 0x4A},  -- Spiral 02
            {left = 0x70, right = 0x72}   -- Spiral 03
        }
    },
    -- Silver Samurai: 01, 02
    [0x0E] = {
        name = "silver_samurai",
        states = {
            {left = 0x0E, right = 0x0E},  -- Silver Samurai 01
            {left = 0x4C, right = 0x4E}   -- Silver Samurai 02
        }
    },
    -- Omega Red: 01, 02
    [0x10] = {
        name = "omega_red",
        states = {
            {left = 0x10, right = 0x10},  -- Omega Red 01
            {left = 0x50, right = 0x52}   -- Omega Red 02
        }
    },
    -- Sentinel: 01, 02
    [0x12] = {
        name = "sentinel",
        states = {
            {left = 0x12, right = 0x12},  -- Sentinel 01
            {left = 0x54, right = 0x56}   -- Sentinel 02
        }
    },
    -- Juggernaut (Boss): 01, 02
    [0x14] = {
        name = "juggernaut",
        states = {
            {left = 0x14, right = 0x14},  -- Juggernaut 01
            {left = 0x58, right = 0x5A}   -- Juggernaut 02
        }
    },
    -- Magneto (Boss): 01, 02
    [0x16] = {
        name = "magneto",
        states = {
            {left = 0x16, right = 0x16},  -- Magneto 01
            {left = 0x5C, right = 0x5E}   -- Magneto 02
        }
    },
    -- Gouki/Akuma (Boss): 01, 02
    [0x18] = {
        name = "gouki",
        states = {
            {left = 0x18, right = 0x18},  -- Gouki 01
            {left = 0x60, right = 0x62}   -- Gouki 02
        }
    }
}

-- Memory addresses for XMCOTA (from cheat file)
local memory_addresses = {
    p1_char = 0xFF4051,     -- P1 Select Character address
    p2_char = 0xFF4451,     -- P2 Select Character address
    game_state = 0xFF4800,  -- Game state (from Hide Background cheat)
    timer = 0xFF4808        -- Timer address
}

-- Variant override memory (standard for Capcom games)
local variant_memory = {
    p1_override_active = 0xFF9000,
    p1_override_state = 0xFF9001,
    p2_override_active = 0xFF9002,
    p2_override_state = 0xFF9003,
}

-- State tracking
local p1_current_variant = {}
local p2_current_variant = {}
local p1_last_character = nil
local p2_last_character = nil

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
    
    local p1_char = mem:read_u8(memory_addresses.p1_char)
    local p2_char = mem:read_u8(memory_addresses.p2_char)
    
    -- Validate characters (0x00-0x18 are valid, anything else is blank)
    if p1_char > 0x18 then p1_char = 0x20 end
    if p2_char > 0x18 then p2_char = 0x20 end
    
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
    
    if player == 1 then
        mem:write_u8(variant_memory.p1_override_active, 0)
    else
        mem:write_u8(variant_memory.p2_override_active, 0)
    end
    
    print(string.format("XMCOTA: Cleared P%d variant override", player))
end

-- Trigger variant display (using left/right state pairs)
local function trigger_variant_display(player, variant_index, variant_states)
    if not manager or not manager.machine then return end
    
    local machine = manager.machine
    local cpu = machine.devices[":maincpu"]
    if not cpu then return end
    
    local mem = cpu.spaces["program"]
    if not mem then return end
    
    -- Get the appropriate state pair
    local state_pair = variant_states[variant_index]
    local variant_state = (player == 1) and state_pair.left or state_pair.right
    
    if player == 1 then
        mem:write_u8(variant_memory.p1_override_active, 1)
        mem:write_u8(variant_memory.p1_override_state, variant_state)
    else
        mem:write_u8(variant_memory.p2_override_active, 1)
        mem:write_u8(variant_memory.p2_override_state, variant_state)
    end
    
    print(string.format("XMCOTA: P%d variant set to 0x%02X", player, variant_state))
end

-- Cycle character variant
local function cycle_character_variant(player, character_id)
    if not character_variants[character_id] then
        print(string.format("XMCOTA: P%d character 0x%02X has no variants", player, character_id))
        return
    end
    
    local states = character_variants[character_id].states
    
    if #states <= 1 then
        print(string.format("XMCOTA: P%d %s has only one variant", 
              player, character_variants[character_id].name))
        return
    end
    
    local variant_table = (player == 1) and p1_current_variant or p2_current_variant
    
    if not variant_table[character_id] then
        variant_table[character_id] = 1
    end
    
    variant_table[character_id] = (variant_table[character_id] % #states) + 1
    
    local variant_index = variant_table[character_id]
    local state_pair = states[variant_index]
    local display_state = (player == 1) and state_pair.left or state_pair.right
    
    print(string.format("XMCOTA: P%d %s variant %d/%d (left: 0x%02X, right: 0x%02X, using: 0x%02X)", 
          player, character_variants[character_id].name, 
          variant_index, #states, state_pair.left, state_pair.right, display_state))
    
    trigger_variant_display(player, variant_index, states)
end

-- Module API
function xmcota.init()
    print("XMCOTA module initialized")
    p1_current_variant = {}
    p2_current_variant = {}
    p1_last_character = nil
    p2_last_character = nil
    return true
end

function xmcota.update()
    local p1_char, p2_char = get_current_characters()
    
    if not p1_char or not p2_char then
        return
    end
    
    -- Only clear overrides when switching to a DIFFERENT character
    if p1_char ~= p1_last_character then
        if p1_last_character and p1_last_character ~= 0x20 and
           p1_char ~= 0x20 and
           p1_char ~= p1_last_character then
            print(string.format("XMCOTA: P1 switched from 0x%02X to 0x%02X - clearing override", p1_last_character, p1_char))
            clear_variant_override(1)
        end
        p1_last_character = p1_char
    end
    
    if p2_char ~= p2_last_character then
        if p2_last_character and p2_last_character ~= 0x20 and
           p2_char ~= 0x20 and
           p2_char ~= p2_last_character then
            print(string.format("XMCOTA: P2 switched from 0x%02X to 0x%02X - clearing override", p2_last_character, p2_char))
            clear_variant_override(2)
        end
        p2_last_character = p2_char
    end
end

function xmcota.cycle_p1_variant()
    local p1_char, _ = get_current_characters()
    if p1_char and p1_char ~= 0x20 then
        cycle_character_variant(1, p1_char)
    end
end

function xmcota.cycle_p2_variant()
    local _, p2_char = get_current_characters()
    if p2_char and p2_char ~= 0x20 then
        cycle_character_variant(2, p2_char)
    end
end

function xmcota.cycle_both_variants()
    xmcota.cycle_p1_variant()
    xmcota.cycle_p2_variant()
end

function xmcota.cleanup()
    print("XMCOTA module cleanup")
    p1_current_variant = {}
    p2_current_variant = {}
    p1_last_character = nil
    p2_last_character = nil
end

return xmcota