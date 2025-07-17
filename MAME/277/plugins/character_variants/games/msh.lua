-- MSH Game Module for Character Variants Plugin
local msh = {}

-- Character variants with separate P1 and P2 states
local character_variants = {
    -- Anita: 01, 02
    [0x18] = {
        name = "anita",
        p1_states = {0x18, 0x34},
        p2_states = {0x18, 0x36}
    },
    -- Blackheart: 01, 02  
    [0x0C] = {
        name = "blackheart",
        p1_states = {0x0C, 0x38},
        p2_states = {0x0C, 0x3A}
    },
    -- Dr Doom: 01, 02
    [0x14] = {
        name = "dr_doom", 
        p1_states = {0x14, 0x3C},
        p2_states = {0x14, 0x3E}
    },
    -- Iron Man: 01, 02
    [0x06] = {
        name = "iron_man",
        p1_states = {0x06, 0x40},
        p2_states = {0x06, 0x42}
    },
    -- Psylocke: 01, 02, 03
    [0x0A] = {
        name = "psylocke",
        p1_states = {0x0A, 0x44, 0x46},
        p2_states = {0x0A, 0x48, 0x4A}
    },
    -- Thanos: 01, 02, 03
    [0x16] = {
        name = "thanos",
        p1_states = {0x16, 0x50, 0x52},
        p2_states = {0x16, 0x54, 0x56}
    },
    -- Wolverine: 01, 02
    [0x08] = {
        name = "wolverine",
        p1_states = {0x08, 0x58},
        p2_states = {0x08, 0x5A}
    }
}

-- Memory addresses
local memory_addresses = {
    game_active = 0xFFD581,
    p1_char = 0xFF4051,
    p2_char = 0xFF4451
}

-- Variant override memory
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
    
    local p1_char, p2_char = 0x00, 0x00
    
    if mem:read_u8(memory_addresses.game_active) > 0 then
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
    
    if player == 1 then
        mem:write_u8(variant_memory.p1_override_active, 0)
    else
        mem:write_u8(variant_memory.p2_override_active, 0)
    end
    
    print(string.format("MSH: Cleared P%d variant override", player))
end

-- Trigger variant display
local function trigger_variant_display(player, variant_state)
    if not manager or not manager.machine then return end
    
    local machine = manager.machine
    local cpu = machine.devices[":maincpu"]
    if not cpu then return end
    
    local mem = cpu.spaces["program"]
    if not mem then return end
    
    if player == 1 then
        mem:write_u8(variant_memory.p1_override_active, 1)
        mem:write_u8(variant_memory.p1_override_state, variant_state)
    else
        mem:write_u8(variant_memory.p2_override_active, 1)
        mem:write_u8(variant_memory.p2_override_state, variant_state)
    end
    
    print(string.format("MSH: P%d variant set to 0x%02X", player, variant_state))
end

-- Cycle character variant
local function cycle_character_variant(player, character_id)
    if not character_variants[character_id] then
        print(string.format("MSH: P%d character 0x%02X has no variants", player, character_id))
        return
    end
    
    local char_data = character_variants[character_id]
    local states = (player == 1) and char_data.p1_states or char_data.p2_states
    
    if #states <= 1 then
        print(string.format("MSH: P%d %s has only one variant", 
              player, char_data.name))
        return
    end
    
    local variant_table = (player == 1) and p1_current_variant or p2_current_variant
    
    if not variant_table[character_id] then
        variant_table[character_id] = 1
    end
    
    variant_table[character_id] = (variant_table[character_id] % #states) + 1
    
    local variant_state = states[variant_table[character_id]]
    print(string.format("MSH: P%d %s variant %d/%d (state 0x%02X)", 
          player, char_data.name, 
          variant_table[character_id], #states, variant_state))
    
    trigger_variant_display(player, variant_state)
end

-- Module API
function msh.init()
    print("MSH module initialized")
    p1_current_variant = {}
    p2_current_variant = {}
    p1_last_character = nil
    p2_last_character = nil
    return true
end

function msh.update()
    local p1_char, p2_char = get_current_characters()
    
    if not p1_char or not p2_char then
        return
    end
    
    -- Only clear overrides when switching to a DIFFERENT character (not just any change)
    if p1_char ~= p1_last_character then
        -- Only clear if we're switching from one real character to a different real character
        if p1_last_character and p1_last_character ~= 0x00 and p1_last_character ~= 0x1E and
           p1_char ~= 0x00 and p1_char ~= 0x1E and
           p1_char ~= p1_last_character then
            print(string.format("MSH: P1 switched from 0x%02X to 0x%02X - clearing override", p1_last_character, p1_char))
            clear_variant_override(1)
        end
        p1_last_character = p1_char
    end
    
    if p2_char ~= p2_last_character then
        -- Only clear if we're switching from one real character to a different real character
        if p2_last_character and p2_last_character ~= 0x00 and p2_last_character ~= 0x1E and
           p2_char ~= 0x00 and p2_char ~= 0x1E and
           p2_char ~= p2_last_character then
            print(string.format("MSH: P2 switched from 0x%02X to 0x%02X - clearing override", p2_last_character, p2_char))
            clear_variant_override(2)
        end
        p2_last_character = p2_char
    end
end

function msh.cycle_p1_variant()
    local p1_char, _ = get_current_characters()
    if p1_char and p1_char ~= 0x00 then
        cycle_character_variant(1, p1_char)
    end
end

function msh.cycle_p2_variant()
    local _, p2_char = get_current_characters()
    if p2_char and p2_char ~= 0x00 then
        cycle_character_variant(2, p2_char)
    end
end

function msh.cycle_both_variants()
    msh.cycle_p1_variant()
    msh.cycle_p2_variant()
end

function msh.cleanup()
    print("MSH module cleanup")
    p1_current_variant = {}
    p2_current_variant = {}
    p1_last_character = nil
    p2_last_character = nil
end

return msh