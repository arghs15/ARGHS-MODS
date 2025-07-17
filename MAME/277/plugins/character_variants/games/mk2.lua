-- MK2 Game Module for Character Variants Plugin
local mk2 = {}

-- Character variants for MK2 (based on cheat file states + available images)
-- Using custom state values starting from 0x30 to avoid conflicts with game character IDs
local character_variants = {
    -- Kung Lao: 2 variants
    [0x00] = {
        name = "kung_lao",
        states = {0x00, 0x30}  -- Kung Lao 01, Kung Lao 02
    },
    -- Liu Kang: 2 variants
    [0x01] = {
        name = "liu_kang",
        states = {0x01, 0x31}  -- Liu Kang 01, Liu Kang 02
    },
    -- Johnny Cage: 2 variants
    [0x02] = {
        name = "johnny_cage",
        states = {0x02, 0x32}  -- Johnny Cage 01, Johnny Cage 02
    },
    -- Baraka: 2 variants
    [0x03] = {
        name = "baraka",
        states = {0x03, 0x33}  -- Baraka 01, Baraka 02
    },
    -- Kitana: 2 variants
    [0x04] = {
        name = "kitana",
        states = {0x04, 0x34}  -- Kitana 01, Kitana 02
    },
    -- Mileena: 1 variant
    [0x05] = {
        name = "mileena",
        states = {0x05}  -- Mileena 01
    },
    -- Shang Tsung: 3 variants
    [0x06] = {
        name = "shang_tsung",
        states = {0x06, 0x35, 0x36}  -- Shang Tsung 01, 02, 03
    },
    -- Raiden: 2 variants
    [0x07] = {
        name = "raiden",
        states = {0x07, 0x37}  -- Raiden 01, Raiden 02
    },
    -- Sub-Zero: 2 variants
    [0x08] = {
        name = "sub_zero",
        states = {0x08, 0x38}  -- Sub Zero 01, Sub Zero 02
    },
    -- Reptile: 2 variants
    [0x09] = {
        name = "reptile",
        states = {0x09, 0x39}  -- Reptile 01, Reptile 02
    },
    -- Scorpion: 2 variants
    [0x0A] = {
        name = "scorpion",
        states = {0x0A, 0x3A}  -- Scorpion 01, Scorpion 02
    },
    -- Jax: 2 variants
    [0x0B] = {
        name = "jax",
        states = {0x0B, 0x3B}  -- Jax 01, Jax 02
    },
    -- Kintaro: 1 variant (no image available)
    [0x0C] = {
        name = "kintaro",
        states = {0x0C}  -- Kintaro (blank)
    },
    -- Shao Kahn: 1 variant (no image available)
    [0x0D] = {
        name = "shao_kahn",
        states = {0x0D}  -- Shao Kahn (blank)
    },
    -- Smoke: 1 variant (no image available)
    [0x0E] = {
        name = "smoke",
        states = {0x0E}  -- Smoke (blank)
    },
    -- Noob Saibot: 1 variant (no image available)
    [0x0F] = {
        name = "noob_saibot",
        states = {0x0F}  -- Noob Saibot (blank)
    },
    -- Jade: 1 variant (no image available)
    [0x10] = {
        name = "jade",
        states = {0x10}  -- Jade (blank)
    }
}

-- Memory addresses for MK2 (from actual cheat file)
local memory_addresses = {
    p1_char = 0x1060280,        -- P1 Select Character (from cheat file)
    p2_char = 0x1060E50,        -- P2 Select Character (from cheat file)
    p1_energy = 0x105E500,      -- P1 Infinite Energy (from cheat file)
    p2_energy = 0x105E440,      -- P2 Infinite Energy (from cheat file)
    p1_energy2 = 0x10602F0,     -- P1 Energy secondary address
    p2_energy2 = 0x1060EC0,     -- P2 Energy secondary address
    game_timer = 0x00033F4,     -- Infinite Time (from cheat file)
    fatality_timer = 0x0003EAC, -- Infinite Fatality Time (from cheat file)
}

-- Variant override memory (using wider spacing to avoid memory conflicts)
local variant_memory = {
    p1_override_active = 0x1061700,
    p1_override_state = 0x1061710,   -- 16 bytes apart
    p2_override_active = 0x1061720,  -- 32 bytes apart  
    p2_override_state = 0x1061730,   -- 16 bytes apart
}

-- State tracking
local p1_current_variant = {}
local p2_current_variant = {}
local p1_last_character = nil
local p2_last_character = nil

-- Get current characters (using MK2 character selection addresses from cheat file)
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
    
    -- Validate character range (0x00-0x10 based on MK2 character list from cheat file)
    if p1_char > 0x10 then p1_char = 0x20 end
    if p2_char > 0x10 then p2_char = 0x20 end
    
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
        mem:write_u8(variant_memory.p1_override_state, 0)
        print(string.format("MK2: Cleared P1 variant override"))
    else
        mem:write_u8(variant_memory.p2_override_active, 0)
        mem:write_u8(variant_memory.p2_override_state, 0)
        print(string.format("MK2: Cleared P2 variant override"))
    end
end

-- Trigger variant display - SAFE APPROACH
-- Use override memory that doesn't conflict with active game memory
local function trigger_variant_display(player, variant_state)
    if not manager or not manager.machine then return end
    
    local machine = manager.machine
    local cpu = machine.devices[":maincpu"]
    if not cpu then return end
    
    local mem = cpu.spaces["program"]
    if not mem then return end
    
    -- Write to our override memory (safe areas)
    if player == 1 then
        mem:write_u8(variant_memory.p1_override_active, 1)
        mem:write_u8(variant_memory.p1_override_state, variant_state)
        print(string.format("MK2: P1 variant set to 0x%02X", variant_state))
    else
        mem:write_u8(variant_memory.p2_override_active, 1)
        mem:write_u8(variant_memory.p2_override_state, variant_state)
        print(string.format("MK2: P2 variant set to 0x%02X", variant_state))
    end
    
    -- Verify the write worked
    local active_check, state_check
    if player == 1 then
        active_check = mem:read_u8(variant_memory.p1_override_active)
        state_check = mem:read_u8(variant_memory.p1_override_state)
    else
        active_check = mem:read_u8(variant_memory.p2_override_active)
        state_check = mem:read_u8(variant_memory.p2_override_state)
    end
    print(string.format("MK2: P%d verification - active: %d, state: 0x%02X", player, active_check, state_check))
end

-- Cycle character variant
local function cycle_character_variant(player, character_id)
    if not character_variants[character_id] then
        print(string.format("MK2: P%d character 0x%02X has no variants", player, character_id))
        return
    end
    
    local states = character_variants[character_id].states
    
    if #states <= 1 then
        print(string.format("MK2: P%d %s has only one variant", 
              player, character_variants[character_id].name))
        return
    end
    
    local variant_table = (player == 1) and p1_current_variant or p2_current_variant
    
    if not variant_table[character_id] then
        variant_table[character_id] = 1
    end
    
    variant_table[character_id] = (variant_table[character_id] % #states) + 1
    
    local variant_state = states[variant_table[character_id]]
    print(string.format("MK2: P%d %s variant %d/%d (state 0x%02X)", 
          player, character_variants[character_id].name, 
          variant_table[character_id], #states, variant_state))
    
    trigger_variant_display(player, variant_state)
end

-- Module API
function mk2.init()
    print("MK2 module initialized")
    p1_current_variant = {}
    p2_current_variant = {}
    p1_last_character = nil
    p2_last_character = nil
    return true
end

function mk2.update()
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
            print(string.format("MK2: P1 switched from 0x%02X to 0x%02X - clearing override", p1_last_character, p1_char))
            clear_variant_override(1)
        end
        p1_last_character = p1_char
    end
    
    if p2_char ~= p2_last_character then
        if p2_last_character and p2_last_character ~= 0x20 and
           p2_char ~= 0x20 and
           p2_char ~= p2_last_character and
           not p2_override_active then
            print(string.format("MK2: P2 switched from 0x%02X to 0x%02X - clearing override", p2_last_character, p2_char))
            clear_variant_override(2)
        end
        p2_last_character = p2_char
    end
end

function mk2.cycle_p1_variant()
    local p1_char, _ = get_current_characters()
    if p1_char and p1_char ~= 0x20 and p1_char <= 0x10 then
        cycle_character_variant(1, p1_char)
    else
        print("MK2: P1 character is invalid or not detected")
    end
end

function mk2.cycle_p2_variant()
    local _, p2_char = get_current_characters()
    if p2_char and p2_char ~= 0x20 and p2_char <= 0x10 then
        cycle_character_variant(2, p2_char)
    else
        print("MK2: P2 character is invalid or not detected")
    end
end

function mk2.cycle_both_variants()
    mk2.cycle_p1_variant()
    mk2.cycle_p2_variant()
end

function mk2.cleanup()
    print("MK2 module cleanup")
    p1_current_variant = {}
    p2_current_variant = {}
    p1_last_character = nil
    p2_last_character = nil
end

-- Debug function to show current game state
function mk2.debug_state()
    if not manager or not manager.machine then
        print("MK2: No manager or machine available")
        return
    end
    
    local machine = manager.machine
    local cpu = machine.devices[":maincpu"]
    if not cpu then
        print("MK2: No CPU device")
        return
    end
    
    local mem = cpu.spaces["program"]
    if not mem then
        print("MK2: No memory space")
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
    
    print(string.format("MK2 Debug - P1: 0x%02X, P2: 0x%02X, P1 Energy: %d, P2 Energy: %d", 
          p1_char, p2_char, p1_energy, p2_energy))
    print(string.format("MK2 Override - P1: %d/0x%02X, P2: %d/0x%02X", 
          p1_override, p1_override_state, p2_override, p2_override_state))
    
    -- Show character names
    if character_variants[p1_char] then
        print(string.format("MK2 P1: %s", character_variants[p1_char].name))
    end
    if character_variants[p2_char] then
        print(string.format("MK2 P2: %s", character_variants[p2_char].name))
    end
    
    -- Show memory addresses being used
    print(string.format("MK2 Memory - P1 override: 0x%X/0x%X, P2 override: 0x%X/0x%X", 
          variant_memory.p1_override_active, variant_memory.p1_override_state,
          variant_memory.p2_override_active, variant_memory.p2_override_state))
end

return mk2