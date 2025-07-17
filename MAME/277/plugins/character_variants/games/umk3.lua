-- UMK3 Game Module for Character Variants Plugin
local umk3 = {}

-- Character variants for UMK3 (based on cheat file states + available images)
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
    -- Smoke: 2 variants
    [0x0E] = {
        name = "smoke",
        states = {0x0E, 0x41}  -- Smoke 01, Smoke 02
    },
    -- Kitana: 2 variants
    [0x0F] = {
        name = "kitana",
        states = {0x0F, 0x42}  -- Kitana 01, Kitana 02
    },
    -- Jade: 1 variant (no image available)
    [0x10] = {
        name = "jade",
        states = {0x10}  -- Jade (blank)
    },
    -- Mileena: 1 variant
    [0x11] = {
        name = "mileena",
        states = {0x11}  -- Mileena 01
    },
    -- Scorpion: 1 variant (no image available)
    [0x12] = {
        name = "scorpion",
        states = {0x12}  -- Scorpion (blank)
    },
    -- Reptile: 1 variant (no image available)
    [0x13] = {
        name = "reptile",
        states = {0x13}  -- Reptile (blank)
    },
    -- Ermac: 3 variants
    [0x14] = {
        name = "ermac",
        states = {0x14, 0x43, 0x44}  -- Ermac 01, 02, 03
    },
    -- Classic Sub-Zero: 1 variant
    [0x15] = {
        name = "classic_sub_zero",
        states = {0x15}  -- Classic Sub Zero 01
    },
    -- Human Smoke: 1 variant
    [0x16] = {
        name = "human_smoke",
        states = {0x16}  -- Human Smoke 01
    },
    -- Noob Saibot: 1 variant (no image available)
    [0x17] = {
        name = "noob_saibot",
        states = {0x17}  -- Noob Saibot (blank)
    },
    -- Motaro: 1 variant (no image available)
    [0x18] = {
        name = "motaro",
        states = {0x18}  -- Motaro (blank)
    },
    -- Shao Kahn: 1 variant (no image available)
    [0x19] = {
        name = "shao_kahn",
        states = {0x19}  -- Shao Kahn (blank)
    }
}

-- Memory addresses for UMK3 (from actual cheat file)
local memory_addresses = {
    p1_char = 0x01060A30,       -- P1 Select Character (from cheat file)
    p2_char = 0x010615E0,       -- P2 Select Character (from cheat file)
    p1_energy = 0x1060A60,      -- P1 Infinite Energy (from cheat file)
    p2_energy = 0x1061610,      -- P2 Infinite Energy (from cheat file)
    p1_turbo = 0x1060A70,       -- P1 Infinite Turbo (from cheat file)
    p2_turbo = 0x1061620,       -- P2 Infinite Turbo (from cheat file)
    -- Try to find stable "in-battle" character addresses
    p1_battle_char = 0x1060A10,    -- P1 character during battle
    p2_battle_char = 0x10615C0,    -- P2 character during battle
}

-- Variant override memory (using wider spacing to avoid memory conflicts)
local variant_memory = {
    p1_override_active = 0x1062800,
    p1_override_state = 0x1062810,   -- 16 bytes apart
    p2_override_active = 0x1062820,  -- 32 bytes apart  
    p2_override_state = 0x1062830,   -- 16 bytes apart
}

-- State tracking - simplified
local p1_current_variant = {}
local p2_current_variant = {}
local p1_battle_character = nil
local p2_battle_character = nil
local in_battle = false

-- Simple battle detection - only update when actually fighting
local function get_battle_characters()
    if not manager or not manager.machine then
        return nil, nil, false
    end
    
    local machine = manager.machine
    local cpu = machine.devices[":maincpu"]
    if not cpu then return nil, nil, false end
    
    local mem = cpu.spaces["program"]
    if not mem then return nil, nil, false end
    
    -- Read energy levels to detect if we're in battle
    local p1_energy = mem:read_u8(memory_addresses.p1_energy)
    local p2_energy = mem:read_u8(memory_addresses.p2_energy)
    
    -- If both players have energy, we're probably in battle
    local battle_active = (p1_energy > 0 and p2_energy > 0 and p1_energy <= 0xA6 and p2_energy <= 0xA6)
    
    if not battle_active then
        return nil, nil, false
    end
    
    -- Try multiple character addresses to find the most stable one
    -- First try selection addresses (might be more current)
    local p1_char = mem:read_u8(memory_addresses.p1_char)
    local p2_char = mem:read_u8(memory_addresses.p2_char)
    
    -- If selection addresses are invalid, try battle addresses
    if p1_char == 0xFF or p1_char > 0x19 then
        p1_char = mem:read_u8(memory_addresses.p1_battle_char)
    end
    if p2_char == 0xFF or p2_char > 0x19 then
        p2_char = mem:read_u8(memory_addresses.p2_battle_char)
    end
    
    -- Final validation
    if p1_char == 0xFF or p1_char > 0x19 then p1_char = 0x20 end
    if p2_char == 0xFF or p2_char > 0x19 then p2_char = 0x20 end
    
    return p1_char, p2_char, battle_active
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
    
    print(string.format("UMK3: Cleared P%d variant override", player))
end

-- Trigger variant display (simplified)
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
        print(string.format("UMK3: P1 variant set to 0x%02X", variant_state))
    else
        mem:write_u8(variant_memory.p2_override_active, 1)
        mem:write_u8(variant_memory.p2_override_state, variant_state)
        print(string.format("UMK3: P2 variant set to 0x%02X", variant_state))
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
    print(string.format("UMK3: P%d verification - active: %d, state: 0x%02X", player, active_check, state_check))
end

-- Cycle character variant (simplified)
local function cycle_character_variant(player, character_id)
    if not character_variants[character_id] then
        print(string.format("UMK3: P%d character 0x%02X has no variants", player, character_id))
        return
    end
    
    local states = character_variants[character_id].states
    
    if #states <= 1 then
        print(string.format("UMK3: P%d %s has only one variant", 
              player, character_variants[character_id].name))
        return
    end
    
    local variant_table = (player == 1) and p1_current_variant or p2_current_variant
    
    if not variant_table[character_id] then
        variant_table[character_id] = 1
    end
    
    variant_table[character_id] = (variant_table[character_id] % #states) + 1
    
    local variant_state = states[variant_table[character_id]]
    print(string.format("UMK3: P%d %s variant %d/%d (state 0x%02X)", 
          player, character_variants[character_id].name, 
          variant_table[character_id], #states, variant_state))
    
    trigger_variant_display(player, variant_state)
end

-- Module API
function umk3.init()
    print("UMK3 module initialized")
    p1_current_variant = {}
    p2_current_variant = {}
    p1_battle_character = nil
    p2_battle_character = nil
    in_battle = false
    return true
end

function umk3.update()
    local p1_char, p2_char, battle_active = get_battle_characters()
    
    if not battle_active then
        -- Not in battle - clear portraits if we were previously in battle
        if in_battle then
            print("UMK3: Exiting battle mode")
            clear_variant_override(1)
            clear_variant_override(2)
            in_battle = false
            p1_battle_character = nil
            p2_battle_character = nil
        end
        return
    end
    
    -- We're in battle
    if not in_battle then
        print("UMK3: Entering battle mode")
        in_battle = true
    end
    
    -- Check if battle characters have changed (new round/fight)
    if p1_char ~= p1_battle_character then
        if p1_char and p1_char ~= 0x20 then
            print(string.format("UMK3: P1 battle character: 0x%02X (%s)", 
                  p1_char, character_variants[p1_char] and character_variants[p1_char].name or "unknown"))
            p1_battle_character = p1_char
            -- Clear any existing variant override for new character
            clear_variant_override(1)
        end
    end
    
    if p2_char ~= p2_battle_character then
        if p2_char and p2_char ~= 0x20 then
            print(string.format("UMK3: P2 battle character: 0x%02X (%s)", 
                  p2_char, character_variants[p2_char] and character_variants[p2_char].name or "unknown"))
            p2_battle_character = p2_char
            -- Clear any existing variant override for new character
            clear_variant_override(2)
        end
    end
end

function umk3.cycle_p1_variant()
    -- Get current character in real-time instead of using stored value
    local p1_char, p2_char, battle_active = get_battle_characters()
    
    if not battle_active then
        print("UMK3: Must be in battle to cycle P1 variant")
        print(string.format("UMK3: Debug - battle_active: %s", tostring(battle_active)))
        return
    end
    
    if not p1_char or p1_char == 0x20 or p1_char > 0x19 then
        print(string.format("UMK3: P1 character invalid: 0x%02X", p1_char or 0xFF))
        return
    end
    
    print(string.format("UMK3: Cycling P1 variant for current character: 0x%02X (%s)", 
          p1_char, character_variants[p1_char] and character_variants[p1_char].name or "unknown"))
    cycle_character_variant(1, p1_char)
end

function umk3.cycle_p2_variant()
    -- Get current character in real-time instead of using stored value
    local p1_char, p2_char, battle_active = get_battle_characters()
    
    if not battle_active then
        print("UMK3: Must be in battle to cycle P2 variant")
        print(string.format("UMK3: Debug - battle_active: %s", tostring(battle_active)))
        return
    end
    
    if not p2_char or p2_char == 0x20 or p2_char > 0x19 then
        print(string.format("UMK3: P2 character invalid: 0x%02X", p2_char or 0xFF))
        return
    end
    
    print(string.format("UMK3: Cycling P2 variant for current character: 0x%02X (%s)", 
          p2_char, character_variants[p2_char] and character_variants[p2_char].name or "unknown"))
    cycle_character_variant(2, p2_char)
end

function umk3.cycle_both_variants()
    umk3.cycle_p1_variant()
    umk3.cycle_p2_variant()
end

-- Add manual override functions for testing
function umk3.force_cycle_p1_variant()
    local p1_char, p2_char, battle_active = get_battle_characters()
    if p1_char and p1_char ~= 0x20 and p1_char <= 0x19 then
        print(string.format("UMK3: Force cycling P1 variant (char: 0x%02X)", p1_char))
        cycle_character_variant(1, p1_char)
    else
        print(string.format("UMK3: Cannot force cycle P1 - invalid character: 0x%02X", p1_char or 0xFF))
    end
end

function umk3.force_cycle_p2_variant()
    local p1_char, p2_char, battle_active = get_battle_characters()
    if p2_char and p2_char ~= 0x20 and p2_char <= 0x19 then
        print(string.format("UMK3: Force cycling P2 variant (char: 0x%02X)", p2_char))
        cycle_character_variant(2, p2_char)
    else
        print(string.format("UMK3: Cannot force cycle P2 - invalid character: 0x%02X", p2_char or 0xFF))
    end
end

function umk3.cleanup()
    print("UMK3 module cleanup")
    p1_current_variant = {}
    p2_current_variant = {}
    p1_battle_character = nil
    p2_battle_character = nil
    in_battle = false
end

-- Debug function to show current game state
function umk3.debug_state()
    if not manager or not manager.machine then
        print("UMK3: No manager or machine available")
        return
    end
    
    local machine = manager.machine
    local cpu = machine.devices[":maincpu"]
    if not cpu then
        print("UMK3: No CPU device")
        return
    end
    
    local mem = cpu.spaces["program"]
    if not mem then
        print("UMK3: No memory space")
        return
    end
    
    local p1_char, p2_char, battle_active = get_battle_characters()
    local p1_energy = mem:read_u8(memory_addresses.p1_energy)
    local p2_energy = mem:read_u8(memory_addresses.p2_energy)
    
    -- Check override memory
    local p1_override = mem:read_u8(variant_memory.p1_override_active)
    local p1_override_state = mem:read_u8(variant_memory.p1_override_state)
    local p2_override = mem:read_u8(variant_memory.p2_override_active)
    local p2_override_state = mem:read_u8(variant_memory.p2_override_state)
    
    print(string.format("UMK3 Debug - P1: 0x%02X, P2: 0x%02X, P1 Energy: %d, P2 Energy: %d, Battle: %s", 
          p1_char or 0xFF, p2_char or 0xFF, p1_energy, p2_energy, tostring(battle_active)))
    print(string.format("UMK3 Override - P1: %d/0x%02X, P2: %d/0x%02X", 
          p1_override, p1_override_state, p2_override, p2_override_state))
    print(string.format("UMK3 Battle State - In Battle: %s, P1: %s, P2: %s", 
          tostring(in_battle), 
          p1_battle_character and string.format("0x%02X", p1_battle_character) or "nil",
          p2_battle_character and string.format("0x%02X", p2_battle_character) or "nil"))
    
    -- Show character names and image availability
    if p1_char and character_variants[p1_char] then
        local has_image = "YES"
        if p1_char == 0x10 or p1_char == 0x12 or p1_char == 0x13 or p1_char == 0x17 or p1_char == 0x18 or p1_char == 0x19 then
            has_image = "NO (blank.png)"
        end
        print(string.format("UMK3 P1: %s (Image: %s)", character_variants[p1_char].name, has_image))
    end
    if p2_char and character_variants[p2_char] then
        local has_image = "YES"
        if p2_char == 0x10 or p2_char == 0x12 or p2_char == 0x13 or p2_char == 0x17 or p2_char == 0x18 or p2_char == 0x19 then
            has_image = "NO (blank.png)"
        end
        print(string.format("UMK3 P2: %s (Image: %s)", character_variants[p2_char].name, has_image))
    end
    
    -- Show memory addresses being used
    print(string.format("UMK3 Memory - P1 override: 0x%X/0x%X, P2 override: 0x%X/0x%X", 
          variant_memory.p1_override_active, variant_memory.p1_override_state,
          variant_memory.p2_override_active, variant_memory.p2_override_state))
    
    -- Character ID mapping for reference
    print("UMK3 Character IDs:")
    print("0x00=Kano, 0x01=Sonya, 0x02=Jax, 0x03=Nightwolf, 0x04=Sub-Zero, 0x05=Stryker")
    print("0x06=Sindel, 0x07=Sektor, 0x08=Cyrax, 0x09=Kung Lao, 0x0A=Kabal, 0x0B=Sheeva")
    print("0x0C=Shang Tsung, 0x0D=Liu Kang, 0x0E=Smoke, 0x0F=Kitana, 0x10=Jade*, 0x11=Mileena")
    print("0x12=Scorpion*, 0x13=Reptile*, 0x14=Ermac, 0x15=Classic Sub-Zero, 0x16=Human Smoke")
    print("0x17=Noob Saibot*, 0x18=Motaro*, 0x19=Shao Kahn* (*=missing image)")
end

return umk3