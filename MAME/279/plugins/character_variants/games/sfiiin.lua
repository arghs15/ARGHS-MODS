-- SFIIIN Game Module for Character Variants Plugin (SIMPLIFIED)
local sfiiin = {}

-- Character variants (same structure as MSHVSF/SFIII2N - single states)
local character_variants = {
    -- Alex: 01, 02
    [0x01] = {
        name = "alex",
        states = {0x01, 0x11}
    },
    -- Dudley: 01, 02
    [0x02] = {
        name = "dudley",
        states = {0x02, 0x12}
    },
    -- Elena: 01, 02
    [0x03] = {
        name = "elena",
        states = {0x03, 0x13}
    },
    -- Gill: 01, 02
    [0x04] = {
        name = "gill",
        states = {0x04, 0x14}
    },
    -- Ibuki: 01, 02
    [0x05] = {
        name = "ibuki",
        states = {0x05, 0x15}
    },
    -- Ken: 01, 02
    [0x06] = {
        name = "ken",
        states = {0x06, 0x16}
    },
    -- Necro: 01, 02, 03
    [0x07] = {
        name = "necro",
        states = {0x07, 0x17, 0x27}
    },
    -- Oro: 01, 02
    [0x08] = {
        name = "oro",
        states = {0x08, 0x18}
    },
    -- Ryu: 01, 02
    [0x09] = {
        name = "ryu",
        states = {0x09, 0x19}
    },
    -- Sean: 01, 02
    [0x0A] = {
        name = "sean",
        states = {0x0A, 0x1A}
    },
    -- Yang/Yun: 01, 02
    [0x0B] = {
        name = "yang_yun",
        states = {0x0B, 0x1B}
    },
}

-- Memory addresses from cheat file
local memory_addresses = {
    p1_char_id = 0x2012C7D,
    p2_char_id = 0x2012C7F,
    p1_char_bank = 0x2012E2F,
    p2_char_bank = 0x2012E31,
}

-- Use SFIIIN-specific memory range (based on cheat file addresses)
local variant_memory = {
    p1_override_active = 0x206CE20,  -- Near background music address
    p1_override_state = 0x206CE21,
    p2_override_active = 0x206CE22,
    p2_override_state = 0x206CE23,
}

-- State tracking
local p1_current_variant = {}
local p2_current_variant = {}
local p1_last_character = nil
local p2_last_character = nil

-- Simplified character mapping (based on layout script logic)
local function map_character_id(char_id, char_bank)
    if char_bank == 0x01 then
        local bank1_map = {
            [0x00] = 0x05,  -- Ibuki
            [0x01] = 0x07,  -- Necro
            [0x02] = 0x0A,  -- Sean
            [0x03] = 0x08,  -- Oro
            [0x04] = 0x03,  -- Elena
        }
        return bank1_map[char_id] or 0x00
    else
        local bank0_map = {
            [0x00] = 0x09,  -- Ryu
            [0x01] = 0x02,  -- Dudley  
            [0x02] = 0x01,  -- Alex
            [0x03] = 0x0B,  -- Yun
            [0x04] = 0x06,  -- Ken
            [0x14] = 0x04,  -- Gill
        }
        return bank0_map[char_id] or 0x00
    end
end

-- Simplified character detection
local function get_current_characters()
    if not manager or not manager.machine then
        return nil, nil
    end
    
    local machine = manager.machine
    local cpu = machine.devices[":maincpu"]
    if not cpu then return nil, nil end
    
    local mem = cpu.spaces["program"]
    if not mem then return nil, nil end
    
    -- Read character data directly
    local p1_char_id = mem:read_u8(memory_addresses.p1_char_id)
    local p2_char_id = mem:read_u8(memory_addresses.p2_char_id)
    local p1_char_bank = mem:read_u8(memory_addresses.p1_char_bank)
    local p2_char_bank = mem:read_u8(memory_addresses.p2_char_bank)
    
    -- Map to internal character IDs
    local p1_char = map_character_id(p1_char_id, p1_char_bank)
    local p2_char = map_character_id(p2_char_id, p2_char_bank)
    
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
    
    print(string.format("SFIIIN: Cleared P%d variant override", player))
end

-- Debug version to check memory addresses
local function trigger_variant_display(player, variant_state)
    if not manager or not manager.machine then return end
    
    local machine = manager.machine
    local cpu = machine.devices[":maincpu"]
    if not cpu then return end
    
    local mem = cpu.spaces["program"]
    if not mem then return end
    
    print(string.format("SFIIIN DEBUG: Setting P%d variant to 0x%02X", player, variant_state))
    
    if player == 1 then
        mem:write_u8(variant_memory.p1_override_active, 1)
        mem:write_u8(variant_memory.p1_override_state, variant_state)
        
        -- Verify write
        local check_active = mem:read_u8(variant_memory.p1_override_active)
        local check_state = mem:read_u8(variant_memory.p1_override_state)
        print(string.format("SFIIIN DEBUG: P1 verification - Active: %d, State: 0x%02X", check_active, check_state))
    else
        mem:write_u8(variant_memory.p2_override_active, 1)
        mem:write_u8(variant_memory.p2_override_state, variant_state)
        
        -- Verify write
        local check_active = mem:read_u8(variant_memory.p2_override_active)
        local check_state = mem:read_u8(variant_memory.p2_override_state)
        print(string.format("SFIIIN DEBUG: P2 verification - Active: %d, State: 0x%02X", check_active, check_state))
    end
    
    print(string.format("SFIIIN: P%d variant set to 0x%02X", player, variant_state))
end

-- Cycle character variant
local function cycle_character_variant(player, character_id)
    if not character_variants[character_id] then
        print(string.format("SFIIIN: P%d character 0x%02X has no variants", player, character_id))
        return
    end
    
    local states = character_variants[character_id].states
    
    if #states <= 1 then
        print(string.format("SFIIIN: P%d %s has only one variant", 
              player, character_variants[character_id].name))
        return
    end
    
    local variant_table = (player == 1) and p1_current_variant or p2_current_variant
    
    if not variant_table[character_id] then
        variant_table[character_id] = 1
    end
    
    variant_table[character_id] = (variant_table[character_id] % #states) + 1
    
    local variant_state = states[variant_table[character_id]]
    print(string.format("SFIIIN: P%d %s variant %d/%d (state 0x%02X)", 
          player, character_variants[character_id].name, 
          variant_table[character_id], #states, variant_state))
    
    trigger_variant_display(player, variant_state)
end

-- Module API
function sfiiin.init()
    print("SFIIIN module initialized")
    p1_current_variant = {}
    p2_current_variant = {}
    p1_last_character = nil
    p2_last_character = nil
    return true
end

function sfiiin.update()
    local p1_char, p2_char = get_current_characters()
    
    if not p1_char or not p2_char then
        return
    end
    
    -- Check if overrides are currently active (like SFIII2N fix)
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
        if p1_last_character and p1_last_character ~= 0x00 and
           p1_char ~= 0x00 and
           p1_char ~= p1_last_character and
           not p1_override_active then
            print(string.format("SFIIIN: P1 switched from 0x%02X to 0x%02X - clearing override", p1_last_character, p1_char))
            clear_variant_override(1)
        end
        p1_last_character = p1_char
    end
    
    if p2_char ~= p2_last_character then
        if p2_last_character and p2_last_character ~= 0x00 and
           p2_char ~= 0x00 and
           p2_char ~= p2_last_character and
           not p2_override_active then
            print(string.format("SFIIIN: P2 switched from 0x%02X to 0x%02X - clearing override", p2_last_character, p2_char))
            clear_variant_override(2)
        end
        p2_last_character = p2_char
    end
end

function sfiiin.cycle_p1_variant()
    local p1_char, _ = get_current_characters()
    if p1_char and p1_char ~= 0x00 then
        cycle_character_variant(1, p1_char)
    end
end

function sfiiin.cycle_p2_variant()
    local _, p2_char = get_current_characters()
    if p2_char and p2_char ~= 0x00 then
        cycle_character_variant(2, p2_char)
    end
end

function sfiiin.cycle_both_variants()
    sfiiin.cycle_p1_variant()
    sfiiin.cycle_p2_variant()
end

function sfiiin.cleanup()
    print("SFIIIN module cleanup")
    p1_current_variant = {}
    p2_current_variant = {}
    p1_last_character = nil
    p2_last_character = nil
end

return sfiiin