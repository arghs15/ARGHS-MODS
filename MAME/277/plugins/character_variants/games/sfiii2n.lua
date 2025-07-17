-- SFIII2N Game Module for Character Variants Plugin (SIMPLIFIED)
local sfiii2n = {}

-- Character variants (same structure as MSHVSF - single states)
local character_variants = {
    -- Ryu: 2 variants
    [0x00] = {
        name = "ryu",
        states = {0x00, 0x30}
    },
    -- Alex: 3 variants
    [0x01] = {
        name = "alex",
        states = {0x01, 0x31, 0x32}
    },
    -- Yun: 2 variants
    [0x02] = {
        name = "yun",
        states = {0x02, 0x33}
    },
    -- Necro: 3 variants
    [0x03] = {
        name = "necro",
        states = {0x03, 0x34, 0x35}
    },
    -- Ibuki: 4 variants
    [0x04] = {
        name = "ibuki",
        states = {0x04, 0x36, 0x37, 0x38}
    },
    -- Hugo: 2 variants
    [0x05] = {
        name = "hugo",
        states = {0x05, 0x39}
    },
    -- Sean: 2 variants
    [0x06] = {
        name = "sean",
        states = {0x06, 0x3A}
    },
    -- Urien: 2 variants
    [0x07] = {
        name = "urien",
        states = {0x07, 0x3B}
    },
    -- Elena: 2 variants
    [0x08] = {
        name = "elena",
        states = {0x08, 0x3C}
    },
    -- Oro: 2 variants
    [0x09] = {
        name = "oro",
        states = {0x09, 0x3D}
    },
    -- Yang: 2 variants
    [0x0A] = {
        name = "yang",
        states = {0x0A, 0x3E}
    },
    -- Dudley: 3 variants
    [0x0B] = {
        name = "dudley",
        states = {0x0B, 0x3F, 0x40}
    },
    -- Ken: 2 variants
    [0x0C] = {
        name = "ken",
        states = {0x0C, 0x41}
    },
    -- Akuma: 3 variants
    [0x0D] = {
        name = "akuma",
        states = {0x0D, 0x0E, 0x42}
    },
    -- Shin Akuma
    [0x0E] = {
        name = "shin_akuma",
        states = {0x0E, 0x0D, 0x42}
    },
    -- Gill: 2 variants
    [0x1A] = {
        name = "gill",
        states = {0x1A, 0x43}
    }
}

-- Memory addresses (simplified)
local memory_addresses = {
    p1_char = 0x20142C1,
    p2_char = 0x20142C3
}

-- Use safer memory range for SFIII2N (away from game data)
local variant_memory = {
    p1_override_active = 0x2073200,
    p1_override_state = 0x2073201,
    p2_override_active = 0x2073202,
    p2_override_state = 0x2073203,
}

-- State tracking
local p1_current_variant = {}
local p2_current_variant = {}
local p1_last_character = nil
local p2_last_character = nil

-- Simplified character detection (like MSHVSF)
local function get_current_characters()
    if not manager or not manager.machine then
        return nil, nil
    end
    
    local machine = manager.machine
    local cpu = machine.devices[":maincpu"]
    if not cpu then return nil, nil end
    
    local mem = cpu.spaces["program"]
    if not mem then return nil, nil end
    
    -- Simple read like other games
    local p1_char = mem:read_u8(memory_addresses.p1_char)
    local p2_char = mem:read_u8(memory_addresses.p2_char)
    
    -- Validate range
    if p1_char > 0x1A then p1_char = 0x20 end
    if p2_char > 0x1A then p2_char = 0x20 end
    
    return p1_char, p2_char
end

-- Simplified clear override (like other games)
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
    
    print(string.format("SFIII2N: Cleared P%d variant override", player))
end

-- Simplified trigger display (like MSHVSF)
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
    
    print(string.format("SFIII2N: P%d variant set to 0x%02X", player, variant_state))
end

-- Simplified cycle function (like MSHVSF)
local function cycle_character_variant(player, character_id)
    if not character_variants[character_id] then
        print(string.format("SFIII2N: P%d character 0x%02X has no variants", player, character_id))
        return
    end
    
    local states = character_variants[character_id].states
    
    if #states <= 1 then
        print(string.format("SFIII2N: P%d %s has only one variant", 
              player, character_variants[character_id].name))
        return
    end
    
    local variant_table = (player == 1) and p1_current_variant or p2_current_variant
    
    if not variant_table[character_id] then
        variant_table[character_id] = 1
    end
    
    variant_table[character_id] = (variant_table[character_id] % #states) + 1
    
    local variant_state = states[variant_table[character_id]]
    print(string.format("SFIII2N: P%d %s variant %d/%d (state 0x%02X)", 
          player, character_variants[character_id].name, 
          variant_table[character_id], #states, variant_state))
    
    trigger_variant_display(player, variant_state)
end

-- Module API (same as other games)
function sfiii2n.init()
    print("SFIII2N module initialized")
    p1_current_variant = {}
    p2_current_variant = {}
    p1_last_character = nil
    p2_last_character = nil
    return true
end

function sfiii2n.update()
    local p1_char, p2_char = get_current_characters()
    
    if not p1_char or not p2_char then
        return
    end
    
    -- Check if overrides are currently active
    local p1_override_active = false
    local p2_override_active = false
    
    if manager and manager.machine then
        local machine = manager.machine
        local cpu = machine.devices[":maincpu"]
        if cpu then
            local mem = cpu.spaces["program"]
            if mem then
                p1_override_active = (mem:read_u8(variant_memory.p1_override_active) == 1)
                p2_override_active = (mem:read_u8(variant_memory.p2_override_active) == 1)
            end
        end
    end
    
    -- Only clear overrides if they're NOT currently active and character actually changed
    if p1_char ~= p1_last_character then
        if p1_last_character and p1_last_character ~= 0x20 and
           p1_char ~= 0x20 and
           p1_char ~= p1_last_character and
           not p1_override_active then  -- Only clear if override is NOT active
            print(string.format("SFIII2N: P1 switched from 0x%02X to 0x%02X - clearing override", p1_last_character, p1_char))
            clear_variant_override(1)
        end
        p1_last_character = p1_char
    end
    
    if p2_char ~= p2_last_character then
        if p2_last_character and p2_last_character ~= 0x20 and
           p2_char ~= 0x20 and
           p2_char ~= p2_last_character and
           not p2_override_active then  -- Only clear if override is NOT active
            print(string.format("SFIII2N: P2 switched from 0x%02X to 0x%02X - clearing override", p2_last_character, p2_char))
            clear_variant_override(2)
        end
        p2_last_character = p2_char
    end
end

function sfiii2n.cycle_p1_variant()
    local p1_char, _ = get_current_characters()
    if p1_char and p1_char ~= 0x20 then
        cycle_character_variant(1, p1_char)
    end
end

function sfiii2n.cycle_p2_variant()
    local _, p2_char = get_current_characters()
    if p2_char and p2_char ~= 0x20 then
        cycle_character_variant(2, p2_char)
    end
end

function sfiii2n.cycle_both_variants()
    sfiii2n.cycle_p1_variant()
    sfiii2n.cycle_p2_variant()
end

function sfiii2n.cleanup()
    print("SFIII2N module cleanup")
    p1_current_variant = {}
    p2_current_variant = {}
    p1_last_character = nil
    p2_last_character = nil
end

return sfiii2n