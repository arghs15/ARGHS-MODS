-- SAMSHO3 Game Module - Character Tracking Approach
local samsho3 = {}

-- Character variants mapping
local character_variants = {
    [0x00] = { name = "haohmaru", variants = {0x00, 0x20, 0x21, 0x22} },
    [0x01] = { name = "nakoruru", variants = {0x01, 0x23, 0x24, 0x25, 0x26, 0x27} },
    [0x02] = { name = "rimururu", variants = {0x02, 0x28, 0x29, 0x2A} },
    [0x03] = { name = "hanzo_hattori", variants = {0x03, 0x2B, 0x2C, 0x2D} },
    [0x04] = { name = "galford_d_weller", variants = {0x04, 0x2E, 0x2F, 0x30} },
    [0x05] = { name = "kyoshiro_senryo", variants = {0x05, 0x31, 0x32} },
    [0x06] = { name = "ukyo_tachibana", variants = {0x06, 0x33} },
    [0x07] = { name = "genjuro_kibagami", variants = {0x07, 0x34, 0x35} },
    [0x08] = { name = "basara_kubikiri", variants = {0x08, 0x36, 0x37, 0x38} },
    [0x09] = { name = "shizumaru_hisame", variants = {0x09, 0x39} },
    [0x0A] = { name = "gaira_kafuin", variants = {0x0A, 0x3A, 0x3B} },
    [0x0B] = { name = "amakusa_shirou_tokisada", variants = {0x0B, 0x3C, 0x3D, 0x3E} },
    [0x0D] = { name = "zankuro_minazuki", variants = {0x0D, 0x3F, 0x40} }
}

-- Memory addresses
local memory_addresses = {
    p1_char = 0x108470,
    p2_char = 0x108471  -- We'll track this ourselves instead of relying on reading it
}

-- State tracking - WE control P2 character tracking
local p1_current_variant = {}
local p2_current_variant = {}
local p1_last_character = nil
local p2_last_character = nil

-- NEW: Manual P2 tracking
local p2_selected_character = nil  -- What character P2 actually selected
local p2_current_display = nil     -- What we're currently displaying for P2

-- Convert variant state back to base character ID
local function get_base_character(char_value)
    if char_value <= 0x0D then return char_value
    elseif char_value >= 0x20 and char_value <= 0x22 then return 0x00  -- Haohmaru
    elseif char_value >= 0x23 and char_value <= 0x27 then return 0x01  -- Nakoruru
    elseif char_value >= 0x28 and char_value <= 0x2A then return 0x02  -- Rimururu
    elseif char_value >= 0x2B and char_value <= 0x2D then return 0x03  -- Hanzo
    elseif char_value >= 0x2E and char_value <= 0x30 then return 0x04  -- Galford
    elseif char_value >= 0x31 and char_value <= 0x32 then return 0x05  -- Kyoshiro
    elseif char_value == 0x33 then return 0x06                         -- Ukyo
    elseif char_value >= 0x34 and char_value <= 0x35 then return 0x07  -- Genjuro
    elseif char_value >= 0x36 and char_value <= 0x38 then return 0x08  -- Basara
    elseif char_value == 0x39 then return 0x09                         -- Shizumaru
    elseif char_value >= 0x3A and char_value <= 0x3B then return 0x0A  -- Gaira
    elseif char_value >= 0x3C and char_value <= 0x3E then return 0x0B  -- Amakusa
    elseif char_value >= 0x3F and char_value <= 0x40 then return 0x0D  -- Zankuro
    else return 0x00 end
end

-- Get P1 character reliably, track P2 ourselves
local function get_current_characters()
    if not manager or not manager.machine then return nil, nil end
    
    local machine = manager.machine
    local cpu = machine.devices[":maincpu"]
    if not cpu then return nil, nil end
    
    local mem = cpu.spaces["program"]
    if not mem then return nil, nil end
    
    -- P1 is reliable
    local p1_raw = mem:read_u8(memory_addresses.p1_char)
    local p1_base = get_base_character(p1_raw)
    
    -- For P2, only detect NEW character selection (not re-detect same character)
    local p2_raw = mem:read_u8(memory_addresses.p2_char)
    
    -- Only update P2 tracking if:
    -- 1. It's a valid character ID (0-13)
    -- 2. It's different from what we currently have tracked
    -- 3. We don't have a P2 character tracked yet, OR the raw value is a base character (not variant)
    if p2_raw <= 0x0D and p2_raw ~= p2_selected_character and 
       (not p2_selected_character or p2_raw <= 0x0D) then
        print(string.format("SAMSHO3: P2 character selection detected: 0x%02X", p2_raw))
        p2_selected_character = p2_raw
        p2_current_display = p2_raw  -- Reset to base character
        -- Clear P2 variant tracking when character changes
        p2_current_variant = {}
    end
    
    -- Return P1 from memory, P2 from our tracking
    return p1_base, p2_selected_character
end
-- Set character display - only write, don't expect to read it back reliably for P2
local function set_character_display(player, char_id)
    if not manager or not manager.machine then return false end
    
    local machine = manager.machine
    local cpu = machine.devices[":maincpu"]
    if not cpu then return false end
    
    local mem = cpu.spaces["program"]
    if not mem then return false end
    
    local success = pcall(function()
        if player == 1 then
            mem:write_u8(memory_addresses.p1_char, char_id)
        else
            mem:write_u8(memory_addresses.p2_char, char_id)
            -- Track what we wrote for P2
            p2_current_display = char_id
        end
    end)
    
    if success then
        print(string.format("SAMSHO3: P%d character set to 0x%02X - SUCCESS", player, char_id))
        return true
    else
        print(string.format("SAMSHO3: Failed to write P%d character memory", player))
        return false
    end
end

-- Cycle character variant
local function cycle_character_variant(player, character_id)
    print(string.format("SAMSHO3: Attempting to cycle P%d character 0x%02X", player, character_id))
    
    if not character_variants[character_id] then
        print(string.format("SAMSHO3: P%d character 0x%02X has no variants", player, character_id))
        return
    end
    
    local char_data = character_variants[character_id]
    local variants = char_data.variants
    
    print(string.format("SAMSHO3: P%d %s has %d variants", player, char_data.name, #variants))
    
    if #variants <= 1 then
        print(string.format("SAMSHO3: P%d %s has only one variant", player, char_data.name))
        return
    end
    
    local variant_table = (player == 1) and p1_current_variant or p2_current_variant
    
    if not variant_table[character_id] then
        variant_table[character_id] = 1
        print(string.format("SAMSHO3: P%d initialized variant index to 1", player))
    end
    
    variant_table[character_id] = (variant_table[character_id] % #variants) + 1
    local variant_state = variants[variant_table[character_id]]
    
    print(string.format("SAMSHO3: P%d %s variant %d/%d (state 0x%02X)", 
          player, char_data.name, variant_table[character_id], #variants, variant_state))
    
    local success = set_character_display(player, variant_state)
    if not success then
        print(string.format("SAMSHO3: P%d variant cycling failed - could not write to memory", player))
    end
end

-- Get current display character for layout system
function samsho3.get_p2_display_character()
    return p2_current_display or 0x00
end

-- Module API
function samsho3.init()
    print("SAMSHO3 module initialized (TRACKING VERSION)")
    p1_current_variant = {}
    p2_current_variant = {}
    p1_last_character = nil
    p2_last_character = nil
    p2_selected_character = nil
    p2_current_display = nil
    return true
end

function samsho3.update()
    local p1_char, p2_char = get_current_characters()
    
    if not p1_char then return end
    
    -- Handle P1 character changes
    if p1_char ~= p1_last_character then
        if p1_last_character then
            print(string.format("SAMSHO3: P1 switched from 0x%02X to 0x%02X", p1_last_character, p1_char))
            p1_current_variant = {}
        end
        p1_last_character = p1_char
    end
    
    -- Handle P2 character changes
    if p2_char and p2_char ~= p2_last_character then
        if p2_last_character then
            print(string.format("SAMSHO3: P2 switched from 0x%02X to 0x%02X", p2_last_character, p2_char))
            p2_current_variant = {}
        end
        p2_last_character = p2_char
    end
end

function samsho3.cycle_p1_variant()
    local p1_char, _ = get_current_characters()
    if p1_char then
        print(string.format("SAMSHO3: P1 cycling - detected character 0x%02X", p1_char))
        cycle_character_variant(1, p1_char)
    else
        print("SAMSHO3: P1 character not detected")
    end
end

function samsho3.cycle_p2_variant()
    if p2_selected_character then
        print(string.format("SAMSHO3: P2 cycling - using tracked character 0x%02X", p2_selected_character))
        cycle_character_variant(2, p2_selected_character)
    else
        print("SAMSHO3: P2 character not selected yet")
        -- Fallback: try to detect P2 from current memory
        local _, p2_char = get_current_characters() 
        if p2_char then
            print(string.format("SAMSHO3: P2 fallback - detected character 0x%02X", p2_char))
            cycle_character_variant(2, p2_char)
        end
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
    p2_selected_character = nil
    p2_current_display = nil
end

return samsho3