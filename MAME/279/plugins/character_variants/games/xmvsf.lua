-- XMVSF Game Module for Character Variants Plugin
local xmvsf = {}

-- Character variants with left/right state pairs (like MVSC)
local character_variants = {
    -- Wolverine: 01, 02
    [0x00] = {
        name = "wolverine",
        states = {
            {left = 0x00, right = 0x00},  -- Wolverine 01
            {left = 0x50, right = 0x52}   -- Wolverine 02
        }
    },
    -- Cyclops: 01, 02
    [0x02] = {
        name = "cyclops",
        states = {
            {left = 0x02, right = 0x02},  -- Cyclops 01
            {left = 0x40, right = 0x42}   -- Cyclops 02
        }
    },
    -- Storm: 01, 02
    [0x04] = {
        name = "storm",
        states = {
            {left = 0x04, right = 0x04},  -- Storm 01
            {left = 0x4C, right = 0x4E}   -- Storm 02
        }
    },
    -- Magneto: 01, 02
    [0x0E] = {
        name = "magneto",
        states = {
            {left = 0x0E, right = 0x0E},  -- Magneto 01
            {left = 0x48, right = 0x4A}   -- Magneto 02
        }
    },
    -- Akuma: 01, 02
    [0x1E] = {
        name = "akuma",
        states = {
            {left = 0x1E, right = 0x1E},  -- Akuma 01
            {left = 0x34, right = 0x36}   -- Akuma 02
        }
    },
    -- Charlie: 01, 02
    [0x20] = {
        name = "charlie",
        states = {
            {left = 0x20, right = 0x20},  -- Charlie 01
            {left = 0x3C, right = 0x3E}   -- Charlie 02
        }
    },
    -- Cammy: 01, 02
    [0x22] = {
        name = "cammy",
        states = {
            {left = 0x22, right = 0x22},  -- Cammy 01
            {left = 0x38, right = 0x3A}   -- Cammy 02
        }
    },
    -- Zangief: 01, 02
    [0x1A] = {
        name = "zangief",
        states = {
            {left = 0x1A, right = 0x1A},  -- Zangief 01
            {left = 0x54, right = 0x56}   -- Zangief 02
        }
    },
    -- M Bison: 01, 02
    [0x1C] = {
        name = "m_bison",
        states = {
            {left = 0x1C, right = 0x1C},  -- M Bison 01
            {left = 0x44, right = 0x46}   -- M Bison 02
        }
    }
}

-- Memory addresses for XMVSF
local memory_addresses = {
    game_state1 = 0xFF0080,
    game_active = 0xFF0000,
    game_state2 = 0xFFA005,
    p1_active = 0xFF4403,
    p2_active = 0xFF4003,
    p1_char = 0xFF4053,
    p2_char = 0xFF4453
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
    
    local p1_char, p2_char = 0x26, 0x26  -- Default to blank
    
    -- Use XMVSF game detection logic (from layout script)
    if mem:read_u8(memory_addresses.game_state1) == 1 or
       (mem:read_u8(memory_addresses.game_active) ~= 0 and mem:read_u8(memory_addresses.game_state2) == 255) or
       (mem:read_u8(memory_addresses.game_state2) == 100 and 
        mem:read_u8(memory_addresses.p1_active) == 1 and 
        mem:read_u8(memory_addresses.p2_active) == 1) then
        p1_char = mem:read_u8(memory_addresses.p1_char)
        p2_char = mem:read_u8(memory_addresses.p2_char)
    elseif mem:read_u8(memory_addresses.game_state2) == 100 and mem:read_u8(memory_addresses.p2_active) == 0 then
        p1_char = mem:read_u8(memory_addresses.p1_char)
        p2_char = 0x26  -- blank
    elseif mem:read_u8(memory_addresses.game_state2) == 100 and mem:read_u8(memory_addresses.p1_active) == 0 then
        p1_char = 0x26  -- blank
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
    
    print(string.format("XMVSF: Cleared P%d variant override", player))
end

-- Trigger variant display (using left/right state pairs like MVSC)
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
    
    print(string.format("XMVSF: P%d variant set to 0x%02X", player, variant_state))
end

-- Cycle character variant (using left/right logic like MVSC)
local function cycle_character_variant(player, character_id)
    if not character_variants[character_id] then
        print(string.format("XMVSF: P%d character 0x%02X has no variants", player, character_id))
        return
    end
    
    local states = character_variants[character_id].states
    
    if #states <= 1 then
        print(string.format("XMVSF: P%d %s has only one variant", 
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
    
    print(string.format("XMVSF: P%d %s variant %d/%d (left: 0x%02X, right: 0x%02X, using: 0x%02X)", 
          player, character_variants[character_id].name, 
          variant_index, #states, state_pair.left, state_pair.right, display_state))
    
    trigger_variant_display(player, variant_index, states)
end

-- Module API
function xmvsf.init()
    print("XMVSF module initialized")
    p1_current_variant = {}
    p2_current_variant = {}
    p1_last_character = nil
    p2_last_character = nil
    return true
end

function xmvsf.update()
    local p1_char, p2_char = get_current_characters()
    
    if not p1_char or not p2_char then
        return
    end
    
    -- Only clear overrides when switching to a DIFFERENT character
    if p1_char ~= p1_last_character then
        if p1_last_character and p1_last_character ~= 0x26 and
           p1_char ~= 0x26 and
           p1_char ~= p1_last_character then
            print(string.format("XMVSF: P1 switched from 0x%02X to 0x%02X - clearing override", p1_last_character, p1_char))
            clear_variant_override(1)
        end
        p1_last_character = p1_char
    end
    
    if p2_char ~= p2_last_character then
        if p2_last_character and p2_last_character ~= 0x26 and
           p2_char ~= 0x26 and
           p2_char ~= p2_last_character then
            print(string.format("XMVSF: P2 switched from 0x%02X to 0x%02X - clearing override", p2_last_character, p2_char))
            clear_variant_override(2)
        end
        p2_last_character = p2_char
    end
end

function xmvsf.cycle_p1_variant()
    local p1_char, _ = get_current_characters()
    if p1_char and p1_char ~= 0x26 then
        cycle_character_variant(1, p1_char)
    end
end

function xmvsf.cycle_p2_variant()
    local _, p2_char = get_current_characters()
    if p2_char and p2_char ~= 0x26 then
        cycle_character_variant(2, p2_char)
    end
end

function xmvsf.cycle_both_variants()
    xmvsf.cycle_p1_variant()
    xmvsf.cycle_p2_variant()
end

function xmvsf.cleanup()
    print("XMVSF module cleanup")
    p1_current_variant = {}
    p2_current_variant = {}
    p1_last_character = nil
    p2_last_character = nil
end

return xmvsf