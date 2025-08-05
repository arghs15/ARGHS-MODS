-- SAMSHO3 Game Module for Character Variants Plugin (DIRECT METHOD)
local samsho3 = {}

-- Character variants mapping
local character_variants = {
    [0x00] = {
        name = "haohmaru",
        variants = {0x00, 0x20, 0x21, 0x22}
    },
    [0x01] = {
        name = "nakoruru",
        variants = {0x01, 0x23, 0x24, 0x25, 0x26, 0x27}
    },
    [0x02] = {
        name = "rimururu",
        variants = {0x02, 0x28, 0x29, 0x2A}
    },
    [0x03] = {
        name = "hanzo_hattori",
        variants = {0x03, 0x2B, 0x2C, 0x2D}
    },
    [0x04] = {
        name = "galford_d_weller",
        variants = {0x04, 0x2E, 0x2F, 0x30}
    },
    [0x05] = {
        name = "kyoshiro_senryo",
        variants = {0x05, 0x31, 0x32}
    },
    [0x06] = {
        name = "ukyo_tachibana",
        variants = {0x06, 0x33}
    },
    [0x07] = {
        name = "genjuro_kibagami",
        variants = {0x07, 0x34, 0x35}
    },
    [0x08] = {
        name = "basara_kubikiri",
        variants = {0x08, 0x36, 0x37, 0x38}
    },
    [0x09] = {
        name = "shizumaru_hisame",
        variants = {0x09, 0x39}
    },
    [0x0A] = {
        name = "gaira_kafuin",
        variants = {0x0A, 0x3A, 0x3B}
    },
    [0x0B] = {
        name = "amakusa_shirou_tokisada",
        variants = {0x0B, 0x3C, 0x3D, 0x3E}
    },
    [0x0D] = {
        name = "zankuro_minazuki",
        variants = {0x0D, 0x3F, 0x40}
    }
}

-- Memory addresses for SAMSHO3
local memory_addresses = {
    p1_char = 0x108470,
    p2_char = 0x108471,
    -- Alternative P2 addresses to try (based on 0x100 offset pattern from cheats)
    p2_char_alt1 = 0x108570,  -- P1 + 0x100
    p2_char_alt2 = 0x108571,  -- P1 + 0x101  
    p2_char_alt3 = 0x108670,  -- Near P2 energy
    p2_char_alt4 = 0x108671,  -- Near P2 energy + 1
}

-- State tracking
local p1_current_variant = {}
local p2_current_variant = {}
local p1_last_character = nil
local p2_last_character = nil

-- Track when we're overriding (so layout knows to use the character memory directly)
local p1_override_active = false
local p2_override_active = false

-- Debug counter
local debug_frame_counter = 0

-- Safe memory access function
local function get_memory_space()
    if not manager or not manager.machine then
        return nil
    end
    
    local machine = manager.machine
    local cpu = machine.devices[":maincpu"]
    if not cpu then 
        return nil
    end
    
    local mem = cpu.spaces["program"]
    if not mem then 
        return nil
    end
    
    return mem
end

-- Get current characters
local function get_current_characters()
    local mem = get_memory_space()
    if not mem then
        return nil, nil
    end
    
    debug_frame_counter = debug_frame_counter + 1
    
    local success, p1_char, p2_char = pcall(function()
        local p1_raw = mem:read_u8(memory_addresses.p1_char)
        local p2_raw = mem:read_u8(memory_addresses.p2_char)
        
        -- Read full values for both (needed for variant cycling)
        local p1 = p1_raw
        local p2 = p2_raw
        
        -- Every 120 frames, show debug info
        if debug_frame_counter % 120 == 0 then
            print(string.format("SAMSHO3 DEBUG: P1_raw=0x%02X, P2_raw=0x%02X", p1_raw, p2_raw))
        end
        
        return p1, p2
    end)
    
    if not success then
        return nil, nil
    end
    
    -- Get base character IDs for variant tracking
    local p1_base = p1_char
    local p2_base = p2_char
    
    -- For P1: extract base from variant states (if needed)
    if p1_char >= 0x20 then
        if p1_char >= 0x20 and p1_char <= 0x22 then p1_base = 0x00      -- Haohmaru
        elseif p1_char >= 0x23 and p1_char <= 0x27 then p1_base = 0x01  -- Nakoruru
        elseif p1_char >= 0x28 and p1_char <= 0x2A then p1_base = 0x02  -- Rimururu
        elseif p1_char >= 0x2B and p1_char <= 0x2D then p1_base = 0x03  -- Hanzo
        elseif p1_char >= 0x2E and p1_char <= 0x30 then p1_base = 0x04  -- Galford
        elseif p1_char >= 0x31 and p1_char <= 0x32 then p1_base = 0x05  -- Kyoshiro
        elseif p1_char == 0x33 then p1_base = 0x06                      -- Ukyo
        elseif p1_char >= 0x34 and p1_char <= 0x35 then p1_base = 0x07  -- Genjuro
        elseif p1_char >= 0x36 and p1_char <= 0x38 then p1_base = 0x08  -- Basara
        elseif p1_char == 0x39 then p1_base = 0x09                      -- Shizumaru
        elseif p1_char >= 0x3A and p1_char <= 0x3B then p1_base = 0x0A  -- Gaira
        elseif p1_char >= 0x3C and p1_char <= 0x3E then p1_base = 0x0B  -- Amakusa
        elseif p1_char >= 0x3F and p1_char <= 0x40 then p1_base = 0x0D  -- Zankuro
        else p1_base = 0x1E end -- Invalid
    elseif p1_char > 0x0D then
        -- Check if P1 has color/style flags - extract base character
        local p1_masked = p1_char & 0x0F
        if p1_masked <= 0x0D then
            p1_base = p1_masked
        else
            p1_base = 0x1E -- Invalid
        end
    end
    
    -- For P2: Same logic as P1
    if p2_char >= 0x20 then
        if p2_char >= 0x20 and p2_char <= 0x22 then p2_base = 0x00      -- Haohmaru
        elseif p2_char >= 0x23 and p2_char <= 0x27 then p2_base = 0x01  -- Nakoruru
        elseif p2_char >= 0x28 and p2_char <= 0x2A then p2_base = 0x02  -- Rimururu
        elseif p2_char >= 0x2B and p2_char <= 0x2D then p2_base = 0x03  -- Hanzo
        elseif p2_char >= 0x2E and p2_char <= 0x30 then p2_base = 0x04  -- Galford
        elseif p2_char >= 0x31 and p2_char <= 0x32 then p2_base = 0x05  -- Kyoshiro
        elseif p2_char == 0x33 then p2_base = 0x06                      -- Ukyo
        elseif p2_char >= 0x34 and p2_char <= 0x35 then p2_base = 0x07  -- Genjuro
        elseif p2_char >= 0x36 and p2_char <= 0x38 then p2_base = 0x08  -- Basara
        elseif p2_char == 0x39 then p2_base = 0x09                      -- Shizumaru
        elseif p2_char >= 0x3A and p2_char <= 0x3B then p2_base = 0x0A  -- Gaira
        elseif p2_char >= 0x3C and p2_char <= 0x3E then p2_base = 0x0B  -- Amakusa
        elseif p2_char >= 0x3F and p2_char <= 0x40 then p2_base = 0x0D  -- Zankuro
        else p2_base = 0x1E end -- Invalid
    elseif p2_char > 0x0D then
        -- Check if P2 has color/style flags - extract base character
        local p2_masked = p2_char & 0x0F
        if p2_masked <= 0x0D then
            p2_base = p2_masked
        else
            p2_base = 0x1E -- Invalid
        end
    end
    
    return p1_base, p2_base
end

-- Directly write to character memory (no override system)
local function set_character_variant(player, variant_state)
    local mem = get_memory_space()
    if not mem then return false end
    
    local char_addr = (player == 1) and memory_addresses.p1_char or memory_addresses.p2_char
    
    local success = pcall(function()
        mem:write_u8(char_addr, variant_state)
    end)
    
    if success then
        print(string.format("SAMSHO3: P%d character memory set to 0x%02X - SUCCESS", player, variant_state))
        -- Set override flag so layout knows we changed it
        if player == 1 then
            p1_override_active = true
        else
            p2_override_active = true
        end
        return true
    else
        print(string.format("SAMSHO3: Failed to write P%d character memory", player))
        return false
    end
end

-- Clear override flag when character naturally changes
local function clear_override_flag(player)
    if player == 1 then
        p1_override_active = false
        print("SAMSHO3: P1 override flag cleared")
    else
        p2_override_active = false
        print("SAMSHO3: P2 override flag cleared")
    end
end

-- Cycle character variant
local function cycle_character_variant(player, character_id)
    if not character_variants[character_id] then
        print(string.format("SAMSHO3: P%d character 0x%02X has no variants", player, character_id))
        return
    end
    
    local char_data = character_variants[character_id]
    local variants = char_data.variants
    
    if #variants <= 1 then
        print(string.format("SAMSHO3: P%d %s has only one variant", player, char_data.name))
        return
    end
    
    local variant_table = (player == 1) and p1_current_variant or p2_current_variant
    
    if not variant_table[character_id] then
        variant_table[character_id] = 1
    end
    
    variant_table[character_id] = (variant_table[character_id] % #variants) + 1
    
    local variant_state = variants[variant_table[character_id]]
    
    print(string.format("SAMSHO3: P%d %s variant %d/%d (state 0x%02X)", 
          player, char_data.name, variant_table[character_id], #variants, variant_state))
    
    set_character_variant(player, variant_state)
end

-- Module API
function samsho3.init()
    print("SAMSHO3 module initialized (DIRECT METHOD)")
    p1_current_variant = {}
    p2_current_variant = {}
    p1_last_character = nil
    p2_last_character = nil
    p1_override_active = false
    p2_override_active = false
    
    return true
end

function samsho3.update()
    local p1_char, p2_char = get_current_characters()
    
    if not p1_char or not p2_char then
        return
    end
    
    -- Clear override flags when switching characters naturally
    if p1_char ~= p1_last_character then
        if p1_last_character and p1_last_character ~= 0x1E and
           p1_char ~= 0x1E and
           p1_char ~= p1_last_character and
           not p1_override_active then
            clear_override_flag(1)
        end
        p1_last_character = p1_char
    end
    
    if p2_char ~= p2_last_character then
        if p2_last_character and p2_last_character ~= 0x1E and
           p2_char ~= 0x1E and
           p2_char ~= p2_last_character and
           not p2_override_active then
            clear_override_flag(2)
        end
        p2_last_character = p2_char
    end
    
    -- Reset override flags after some time to prevent getting stuck
    if p1_override_active then
        -- Reset after staying on the same character
        p1_override_active = false
    end
    if p2_override_active then
        p2_override_active = false
    end
end

function samsho3.cycle_p1_variant()
    local p1_char, _ = get_current_characters()
    print(string.format("SAMSHO3: P1 character detected as 0x%02X", p1_char or 0))
    if p1_char and p1_char ~= 0x1E then
        cycle_character_variant(1, p1_char)
    else
        print("SAMSHO3: P1 character is invalid or not detected")
    end
end

function samsho3.cycle_p2_variant()
    local _, p2_char = get_current_characters()
    print(string.format("SAMSHO3: P2 character detected as 0x%02X", p2_char or 0))
    if p2_char and p2_char ~= 0x1E then
        cycle_character_variant(2, p2_char)
    else
        print("SAMSHO3: P2 character is invalid or not detected")
    end
end

function samsho3.cycle_both_variants()
    samsho3.cycle_p1_variant()
    samsho3.cycle_p2_variant()
end

function samsho3.cleanup()
    print("SAMSHO3 module cleanup")
    p1_current_variant = {}
    p2_current_variant = {}
    p1_last_character = nil
    p2_last_character = nil
    p1_override_active = false
    p2_override_active = false
end

return samsho3