-- MK3 Game Module for Character Variants Plugin
local mk3 = {}

-- Character variants for MK3 (based on cheat file states + available images)
-- Using custom state values starting from 0x30 to avoid conflicts with game character IDs
local character_variants = {
    -- Kano: 2 variants
    [0x00] = {
        name = "kano",
        states = {0x00, 0x30}  -- Kano 01, Kano 02
    },
    -- Sonya: 2 variants
    [0x01] = {
        name = "sonya",
        states = {0x01, 0x31}  -- Sonya 01, Sonya 02
    },
    -- Jax: 3 variants
    [0x02] = {
        name = "jax",
        states = {0x02, 0x32, 0x33}  -- Jax 01, Jax 02, Jax 03
    },
    -- Nightwolf: 2 variants
    [0x03] = {
        name = "nightwolf",
        states = {0x03, 0x34}  -- Nightwolf 01, Nightwolf 02
    },
    -- Sub-Zero: 2 variants
    [0x04] = {
        name = "sub_zero",
        states = {0x04, 0x35}  -- Sub Zero 01, Sub Zero 02
    },
    -- Stryker: 2 variants
    [0x05] = {
        name = "stryker",
        states = {0x05, 0x36}  -- Stryker 01, Stryker 02
    },
    -- Sindel: 2 variants
    [0x06] = {
        name = "sindel",
        states = {0x06, 0x37}  -- Sindel 01, Sindel 02
    },
    -- Sektor: 2 variants
    [0x07] = {
        name = "sektor",
        states = {0x07, 0x38}  -- Sektor 01, Sektor 02
    },
    -- Cyrax: 2 variants
    [0x08] = {
        name = "cyrax",
        states = {0x08, 0x39}  -- Cyrax 01, Cyrax 02
    },
    -- Kung Lao: 2 variants
    [0x09] = {
        name = "kung_lao",
        states = {0x09, 0x3A}  -- Kung Lao 01, Kung Lao 02
    },
    -- Kabal: 2 variants
    [0x0A] = {
        name = "kabal",
        states = {0x0A, 0x3B}  -- Kabal 01, Kabal 02
    },
    -- Sheeva: 2 variants
    [0x0B] = {
        name = "sheeva",
        states = {0x0B, 0x3C}  -- Sheeva 01, Sheeva 02
    },
    -- Shang Tsung: 4 variants
    [0x0C] = {
        name = "shang_tsung",
        states = {0x0C, 0x3D, 0x3E, 0x3F}  -- Shang Tsung 01, 02, 03, 04
    },
    -- Liu Kang: 2 variants
    [0x0D] = {
        name = "liu_kang",
        states = {0x0D, 0x40}  -- Liu Kang 01, Liu Kang 02
    },
    -- Smoke: 3 variants
    [0x0E] = {
        name = "smoke",
        states = {0x0E, 0x41, 0x42}  -- Smoke 01, Smoke 02, Smoke 03
    },
    -- Motaro: 1 variant (no image available)
    [0x0F] = {
        name = "motaro",
        states = {0x0F}  -- Motaro (blank)
    },
    -- Shao Kahn: 1 variant (no image available)
    [0x10] = {
        name = "shao_kahn",
        states = {0x10}  -- Shao Kahn (blank)
    },
    -- Noob Saibot: 1 variant (no image available)
    [0x11] = {
        name = "noob_saibot",
        states = {0x11}  -- Noob Saibot (blank)
    }
}

-- Memory addresses for MK3 (from actual cheat file)
local memory_addresses = {
    p1_char = 0x1060A10,        -- P1 Select Character (from cheat file)
    p2_char = 0x10615C0,        -- P2 Select Character (from cheat file)
    p1_energy = 0x1060A40,      -- P1 Infinite Energy (from cheat file)
    p2_energy = 0x10615F0,      -- P2 Infinite Energy (from cheat file)
    game_timer = 0x00016AA,     -- Infinite Time (from cheat file)
}

-- Variant override memory (using wider spacing to avoid memory conflicts)
local variant_memory = {
    p1_override_active = 0x1062800,
    p1_override_state = 0x1062810,   -- 16 bytes apart
    p2_override_active = 0x1062820,  -- 32 bytes apart  
    p2_override_state = 0x1062830,   -- 16 bytes apart
}

-- State tracking
local p1_current_variant = {}
local p2_current_variant = {}
local p1_last_character = nil
local p2_last_character = nil

-- Get current characters (using MK3 character selection addresses from cheat file)
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
    
    -- Validate character range (0x00-0x11 based on MK3 character list from cheat file)
    if p1_char > 0x11 then p1_char = 0x20 end
    if p2_char > 0x11 then p2_char = 0x20 end
    
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
    else
        mem:write_u8(variant_memory.p2_override_active, 0)
        mem:write_u8(variant_memory.p2_override_state, 0)
    end
    
    print(string.format("MK3: Cleared P%d variant override", player))
end

-- Trigger variant display
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
        print(string.format("MK3: P1 variant set to 0x%02X", variant_state))
    else
        mem:write_u8(variant_memory.p2_override_active, 1)
        mem:write_u8(variant_memory.p2_override_state, variant_state)
        print(string.format("MK3: P2 variant set to 0x%02X", variant_state))
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
    print(string.format("MK3: P%d verification - active: %d, state: 0x%02X", player, active_check, state_check))
end

-- Cycle character variant
local function cycle_character_variant(player, character_id)
    if not character_variants[character_id] then
        print(string.format("MK3: P%d character 0x%02X has no variants", player, character_id))
        return
    end
    
    local states = character_variants[character_id].states
    
    if #states <= 1 then
        print(string.format("MK3: P%d %s has only one variant", 
              player, character_variants[character_id].name))
        return
    end
    
    local variant_table = (player == 1) and p1_current_variant or p2_current_variant
    
    if not variant_table[character_id] then
        variant_table[character_id] = 1
    end
    
    variant_table[character_id] = (variant_table[character_id] % #states) + 1
    
    local variant_state = states[variant_table[character_id]]
    print(string.format("MK3: P%d %s variant %d/%d (state 0x%02X)", 
          player, character_variants[character_id].name, 
          variant_table[character_id], #states, variant_state))
    
    trigger_variant_display(player, variant_state)
end

-- Module API
function mk3.init()
    print("MK3 module initialized")
    p1_current_variant = {}
    p2_current_variant = {}
    p1_last_character = nil
    p2_last_character = nil
    return true
end

function mk3.update()
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
            print(string.format("MK3: P1 switched from 0x%02X to 0x%02X - clearing override", p1_last_character, p1_char))
            clear_variant_override(1)
        end
        p1_last_character = p1_char
    end
    
    if p2_char ~= p2_last_character then
        if p2_last_character and p2_last_character ~= 0x20 and
           p2_char ~= 0x20 and
           p2_char ~= p2_last_character and
           not p2_override_active then
            print(string.format("MK3: P2 switched from 0x%02X to 0x%02X - clearing override", p2_last_character, p2_char))
            clear_variant_override(2)
        end
        p2_last_character = p2_char
    end
end

function mk3.cycle_p1_variant()
    local p1_char, _ = get_current_characters()
    if p1_char and p1_char ~= 0x20 and p1_char <= 0x11 then
        cycle_character_variant(1, p1_char)
    else
        print("MK3: P1 character is invalid or not detected")
    end
end

function mk3.cycle_p2_variant()
    local _, p2_char = get_current_characters()
    if p2_char and p2_char ~= 0x20 and p2_char <= 0x11 then
        cycle_character_variant(2, p2_char)
    else
        print("MK3: P2 character is invalid or not detected")
    end
end

function mk3.cycle_both_variants()
    mk3.cycle_p1_variant()
    mk3.cycle_p2_variant()
end

function mk3.cleanup()
    print("MK3 module cleanup")
    p1_current_variant = {}
    p2_current_variant = {}
    p1_last_character = nil
    p2_last_character = nil
end

-- Debug function to show current game state
function mk3.debug_state()
    if not manager or not manager.machine then
        print("MK3: No manager or machine available")
        return
    end
    
    local machine = manager.machine
    local cpu = machine.devices[":maincpu"]
    if not cpu then
        print("MK3: No CPU device")
        return
    end
    
    local mem = cpu.spaces["program"]
    if not mem then
        print("MK3: No memory space")
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
    
    print(string.format("MK3 Debug - P1: 0x%02X, P2: 0x%02X, P1 Energy: %d, P2 Energy: %d", 
          p1_char, p2_char, p1_energy, p2_energy))
    print(string.format("MK3 Override - P1: %d/0x%02X, P2: %d/0x%02X", 
          p1_override, p1_override_state, p2_override, p2_override_state))
    
    -- Show character names
    if character_variants[p1_char] then
        print(string.format("MK3 P1: %s", character_variants[p1_char].name))
    end
    if character_variants[p2_char] then
        print(string.format("MK3 P2: %s", character_variants[p2_char].name))
    end
    
    -- Show memory addresses being used
    print(string.format("MK3 Memory - P1 override: 0x%X/0x%X, P2 override: 0x%X/0x%X", 
          variant_memory.p1_override_active, variant_memory.p1_override_state,
          variant_memory.p2_override_active, variant_memory.p2_override_state))
end

return mk3