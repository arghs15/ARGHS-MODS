-- MVSC Game Module for Character Variants Plugin
local mvsc = {}

-- Character variants (extracted from the layout with correct L/R pairings)
local character_variants = {
    -- Hulk: 01, 02
    [0x06] = {
        name = "hulk",
        states = {
            {left = 0x06, right = 0x06},  -- Hulk 01
            {left = 0x38, right = 0x3A}   -- Hulk 02
        }
    },
    -- Mega Man: 01, 02
    [0x20] = {
        name = "mega_man",
        states = {
            {left = 0x20, right = 0x20},  -- Mega Man 01
            {left = 0x3C, right = 0x3E}   -- Mega Man 02
        }
    },
    -- Roll: 01, 02, 03
    [0x10] = {
        name = "roll",
        states = {
            {left = 0x10, right = 0x10},  -- Roll 01
            {left = 0x40, right = 0x44},  -- Roll 02
            {left = 0x42, right = 0x46}   -- Roll 03
        }
    },
    -- Shadow Lady: 01, 02
    [0x2A] = {
        name = "shadow_lady",
        states = {
            {left = 0x2A, right = 0x2A},  -- Shadow Lady 01
            {left = 0x48, right = 0x4A}   -- Shadow Lady 02
        }
    },
    -- Strider Hiryu: 01, 02, 03
    [0x1C] = {
        name = "strider_hiryu",
        states = {
            {left = 0x1C, right = 0x1C},  -- Strider Hiryu 01
            {left = 0x4C, right = 0x50},  -- Strider Hiryu 02
            {left = 0x4E, right = 0x52}   -- Strider Hiryu 03
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
    -- Orange Hulk: 01, 02, 03
    [0x26] = {
        name = "orange_hulk",
        states = {
            {left = 0x26, right = 0x26},  -- Orange Hulk 01
            {left = 0x58, right = 0x5C},  -- Orange Hulk 02
            {left = 0x5A, right = 0x5E}   -- Orange Hulk 03
        }
    },
    -- Lilith: 01, 02
    [0x2C] = {
        name = "lilith",
        states = {
            {left = 0x2C, right = 0x2C},  -- Lilith 01
            {left = 0x60, right = 0x62}   -- Lilith 02
        }
    },
    -- Hyper Venom: 01, 02
    [0x24] = {
        name = "hyper_venom",
        states = {
            {left = 0x24, right = 0x24},  -- Hyper Venom 01
            {left = 0x34, right = 0x36}   -- Hyper Venom 02
        }
    },
    -- Mega War Machine: 01, 02
    [0x28] = {
        name = "mega_war_machine",
        states = {
            {left = 0x28, right = 0x28},  -- Mega War Machine 01
            {left = 0x6C, right = 0x6E}   -- Mega War Machine 02
        }
    }
}

-- Memory addresses for MVSC (from the script section)
local memory_addresses = {
    game_state1 = 0xFF0080,
    game_active = 0xFF0000,
    special_state = 0xFF92F1,
    p1_active = 0xFF3000,
    p2_active = 0xFF3400,
    p1_char_addr1 = 0xFF3053,  -- Primary P1 address
    p2_char_addr1 = 0xFF3453,  -- Primary P2 address
    p1_char_addr2 = 0xFF3853,  -- Secondary P1 address
    p2_char_addr2 = 0xFF3C53   -- Secondary P2 address
}

-- Variant override memory (same for all games)
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

-- Get current characters (using MVSC's complex logic from the script)
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
    
    -- Use the exact logic from MVSC's layout script
    if mem:read_u8(memory_addresses.game_state1) == 1 then
        p1_char = mem:read_u8(memory_addresses.p1_char_addr1)
        p2_char = mem:read_u8(memory_addresses.p2_char_addr1)
    elseif (mem:read_u8(memory_addresses.game_active) ~= 0 and mem:read_u8(memory_addresses.special_state) == 2) then
        p1_char = 0x00
        p2_char = 0x00
    elseif (mem:read_u8(memory_addresses.game_active) ~= 0 and 
            mem:read_u8(memory_addresses.p1_active) == 1 and 
            mem:read_u8(memory_addresses.p2_active) == 1) then
        p1_char = mem:read_u8(memory_addresses.p1_char_addr1)
        p2_char = mem:read_u8(memory_addresses.p2_char_addr1)
    elseif (mem:read_u8(memory_addresses.game_active) ~= 0 and 
            mem:read_u8(memory_addresses.p1_active) == 1 and 
            mem:read_u8(memory_addresses.p2_active) == 0) then
        p1_char = mem:read_u8(memory_addresses.p1_char_addr1)
        p2_char = mem:read_u8(memory_addresses.p2_char_addr2)
    elseif (mem:read_u8(memory_addresses.game_active) ~= 0 and 
            mem:read_u8(memory_addresses.p1_active) == 0 and 
            mem:read_u8(memory_addresses.p2_active) == 1) then
        p1_char = mem:read_u8(memory_addresses.p1_char_addr2)
        p2_char = mem:read_u8(memory_addresses.p2_char_addr1)
    elseif (mem:read_u8(memory_addresses.game_active) ~= 0 and 
            mem:read_u8(memory_addresses.p1_active) == 0 and 
            mem:read_u8(memory_addresses.p2_active) == 0) then
        p1_char = mem:read_u8(memory_addresses.p1_char_addr2)
        p2_char = mem:read_u8(memory_addresses.p2_char_addr2)
    else
        p1_char = 0x00
        p2_char = 0x00
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
    
    print(string.format("MVSC: Cleared P%d variant override", player))
end

-- Trigger variant display
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
    
    print(string.format("MVSC: P%d variant set to 0x%02X", player, variant_state))
end

-- Cycle character variant
local function cycle_character_variant(player, character_id)
    if not character_variants[character_id] then
        print(string.format("MVSC: P%d character 0x%02X has no variants", player, character_id))
        return
    end
    
    local states = character_variants[character_id].states
    
    if #states <= 1 then
        print(string.format("MVSC: P%d %s has only one variant", 
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
    
    print(string.format("MVSC: P%d %s variant %d/%d (left: 0x%02X, right: 0x%02X, using: 0x%02X)", 
          player, character_variants[character_id].name, 
          variant_index, #states, state_pair.left, state_pair.right, display_state))
    
    trigger_variant_display(player, variant_index, states)
end

-- Module API
function mvsc.init()
    print("MVSC module initialized")
    p1_current_variant = {}
    p2_current_variant = {}
    p1_last_character = nil
    p2_last_character = nil
    return true
end

function mvsc.update()
    local p1_char, p2_char = get_current_characters()
    
    if not p1_char or not p2_char then
        return
    end
    
    -- Only clear overrides when switching to a DIFFERENT character
    if p1_char ~= p1_last_character then
        if p1_last_character and p1_last_character ~= 0x00 and
           p1_char ~= 0x00 and
           p1_char ~= p1_last_character then
            print(string.format("MVSC: P1 switched from 0x%02X to 0x%02X - clearing override", p1_last_character, p1_char))
            clear_variant_override(1)
        end
        p1_last_character = p1_char
    end
    
    if p2_char ~= p2_last_character then
        if p2_last_character and p2_last_character ~= 0x00 and
           p2_char ~= 0x00 and
           p2_char ~= p2_last_character then
            print(string.format("MVSC: P2 switched from 0x%02X to 0x%02X - clearing override", p2_last_character, p2_char))
            clear_variant_override(2)
        end
        p2_last_character = p2_char
    end
end

function mvsc.cycle_p1_variant()
    local p1_char, _ = get_current_characters()
    if p1_char and p1_char ~= 0x00 then
        cycle_character_variant(1, p1_char)
    end
end

function mvsc.cycle_p2_variant()
    local _, p2_char = get_current_characters()
    if p2_char and p2_char ~= 0x00 then
        cycle_character_variant(2, p2_char)
    end
end

function mvsc.cycle_both_variants()
    mvsc.cycle_p1_variant()
    mvsc.cycle_p2_variant()
end

function mvsc.cleanup()
    print("MVSC module cleanup")
    p1_current_variant = {}
    p2_current_variant = {}
    p1_last_character = nil
    p2_last_character = nil
end

return mvsc