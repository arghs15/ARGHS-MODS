-- MK Game Module for Character Variants Plugin
local mk = {}

-- Character variants for MK (based on cheat file states + available images)
-- Note: MK only has single variants for each character based on available images
local character_variants = {
    -- Johnny Cage: 1 variant
    [0x00] = {
        name = "johnny_cage",
        states = {0x00}  -- Johnny Cage 01
    },
    -- Kano: 1 variant
    [0x01] = {
        name = "kano",
        states = {0x01}  -- Kano 01
    },
    -- Raiden: 1 variant
    [0x02] = {
        name = "raiden",
        states = {0x02}  -- Raiden 01
    },
    -- Liu Kang: 1 variant
    [0x03] = {
        name = "liu_kang",
        states = {0x03}  -- Liu Kang 01
    },
    -- Scorpion: 1 variant
    [0x04] = {
        name = "scorpion",
        states = {0x04}  -- Scorpion 01
    },
    -- Sub-Zero: 1 variant
    [0x05] = {
        name = "sub_zero",
        states = {0x05}  -- Sub Zero 01
    },
    -- Sonya Blade: 1 variant
    [0x06] = {
        name = "sonya",
        states = {0x06}  -- Sonia 01
    },
    -- Goro: 1 variant (no image available)
    [0x07] = {
        name = "goro",
        states = {0x07}  -- Goro (blank)
    },
    -- Shang Tsung: 1 variant (no image available)
    [0x08] = {
        name = "shang_tsung",
        states = {0x08}  -- Shang Tsung (blank)
    }
}

-- Memory addresses for MK (from cheat file)
local memory_addresses = {
    p1_energy = 0x1051300,     -- P1 Infinite Energy
    p2_energy = 0x10515E0,     -- P2 Infinite Energy
    p1_char = 0x1051290,       -- P1 Select Character
    p2_char = 0x1051570,       -- P2 Select Character
    game_timer = 0x0093F12,    -- Infinite Time (for game state detection)
}

-- Variant override memory (using area near energy addresses that should be writable)
local variant_memory = {
    p1_override_active = 0x1051400,
    p1_override_state = 0x1051401,
    p2_override_active = 0x1051402,
    p2_override_state = 0x1051403,
}

-- State tracking
local p1_current_variant = {}
local p2_current_variant = {}
local p1_last_character = nil
local p2_last_character = nil

-- Get current characters (using MK character selection addresses from cheat file)
local function get_current_characters()
    if not manager or not manager.machine then
        return nil, nil
    end
    
    local machine = manager.machine
    local cpu = machine.devices[":maincpu"]
    if not cpu then return nil, nil end
    
    local mem = cpu.spaces["program"]
    if not mem then return nil, nil end
    
    -- Read character selection directly from cheat addresses
    local p1_char = mem:read_u8(memory_addresses.p1_char)
    local p2_char = mem:read_u8(memory_addresses.p2_char)
    
    -- Validate character range (0x00-0x08 based on cheat file)
    if p1_char > 0x08 then p1_char = 0x20 end
    if p2_char > 0x08 then p2_char = 0x20 end
    
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
    
    print(string.format("MK: Cleared P%d variant override", player))
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
    
    print(string.format("MK: P%d variant set to 0x%02X", player, variant_state))
end

-- Cycle character variant
local function cycle_character_variant(player, character_id)
    if not character_variants[character_id] then
        print(string.format("MK: P%d character 0x%02X has no variants", player, character_id))
        return
    end
    
    local states = character_variants[character_id].states
    
    if #states <= 1 then
        print(string.format("MK: P%d %s has only one variant", 
              player, character_variants[character_id].name))
        return
    end
    
    local variant_table = (player == 1) and p1_current_variant or p2_current_variant
    
    if not variant_table[character_id] then
        variant_table[character_id] = 1
    end
    
    variant_table[character_id] = (variant_table[character_id] % #states) + 1
    
    local variant_state = states[variant_table[character_id]]
    print(string.format("MK: P%d %s variant %d/%d (state 0x%02X)", 
          player, character_variants[character_id].name, 
          variant_table[character_id], #states, variant_state))
    
    trigger_variant_display(player, variant_state)
end

-- Module API
function mk.init()
    print("MK module initialized")
    p1_current_variant = {}
    p2_current_variant = {}
    p1_last_character = nil
    p2_last_character = nil
    return true
end

function mk.update()
    local p1_char, p2_char = get_current_characters()
    
    if not p1_char or not p2_char then
        return
    end
    
    -- Check if overrides are currently active (prevent clearing active overrides)
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
    
    -- Only clear overrides if they're NOT currently active
    if p1_char ~= p1_last_character then
        if p1_last_character and p1_last_character ~= 0x20 and
           p1_char ~= 0x20 and
           p1_char ~= p1_last_character and
           not p1_override_active then
            print(string.format("MK: P1 switched from 0x%02X to 0x%02X - clearing override", p1_last_character, p1_char))
            clear_variant_override(1)
        end
        p1_last_character = p1_char
    end
    
    if p2_char ~= p2_last_character then
        if p2_last_character and p2_last_character ~= 0x20 and
           p2_char ~= 0x20 and
           p2_char ~= p2_last_character and
           not p2_override_active then
            print(string.format("MK: P2 switched from 0x%02X to 0x%02X - clearing override", p2_last_character, p2_char))
            clear_variant_override(2)
        end
        p2_last_character = p2_char
    end
end

function mk.cycle_p1_variant()
    local p1_char, _ = get_current_characters()
    if p1_char and p1_char ~= 0x20 and p1_char <= 0x08 then
        cycle_character_variant(1, p1_char)
    else
        print("MK: P1 character is invalid or not detected")
    end
end

function mk.cycle_p2_variant()
    local _, p2_char = get_current_characters()
    if p2_char and p2_char ~= 0x20 and p2_char <= 0x08 then
        cycle_character_variant(2, p2_char)
    else
        print("MK: P2 character is invalid or not detected")
    end
end

function mk.cycle_both_variants()
    mk.cycle_p1_variant()
    mk.cycle_p2_variant()
end

function mk.cleanup()
    print("MK module cleanup")
    p1_current_variant = {}
    p2_current_variant = {}
    p1_last_character = nil
    p2_last_character = nil
end

-- Debug function to show current game state
function mk.debug_state()
    if not manager or not manager.machine then
        print("MK: No manager or machine available")
        return
    end
    
    local machine = manager.machine
    local cpu = machine.devices[":maincpu"]
    if not cpu then
        print("MK: No CPU device")
        return
    end
    
    local mem = cpu.spaces["program"]
    if not mem then
        print("MK: No memory space")
        return
    end
    
    local p1_char = mem:read_u8(memory_addresses.p1_char)
    local p2_char = mem:read_u8(memory_addresses.p2_char)
    local p1_energy = mem:read_u8(memory_addresses.p1_energy)
    local p2_energy = mem:read_u8(memory_addresses.p2_energy)
    
    -- Check override memory
    local p1_override = mem:read_u8(variant_memory.p1_override_active)
    local p1_override_state = mem:read_u8(variant_memory.p1_override_state)
    local p2_override = mem:read_u8(variant_memory.p2_override_active)
    local p2_override_state = mem:read_u8(variant_memory.p2_override_state)
    
    print(string.format("MK Debug - P1: 0x%02X, P2: 0x%02X, P1 Energy: %d, P2 Energy: %d", 
          p1_char, p2_char, p1_energy, p2_energy))
    print(string.format("MK Override - P1: %d/0x%02X, P2: %d/0x%02X", 
          p1_override, p1_override_state, p2_override, p2_override_state))
    
    -- Show character names
    if character_variants[p1_char] then
        print(string.format("MK P1: %s", character_variants[p1_char].name))
    end
    if character_variants[p2_char] then
        print(string.format("MK P2: %s", character_variants[p2_char].name))
    end
end

return mk