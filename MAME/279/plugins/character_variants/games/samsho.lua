local samsho = {}

local character_variants = {
    [0x02] = {
        name = "hanzo_hattori",
        variants = {0x02, 0x20, 0x21}
    },
    [0x03] = {
        name = "galford_d_weller",
        variants = {0x03, 0x22, 0x23}
    },
    [0x06] = {
        name = "kyoshiro_senryo",
        variants = {0x06, 0x24}
    },
    [0x01] = {
        name = "nakoruru",
        variants = {0x01, 0x25, 0x26}
    },
    [0x0A] = {
        name = "tam_tam",
        variants = {0x0A, 0x27}
    }
}

local memory_addresses = {
    p1_char = 0x10100B,
    p2_char = 0x10102B
}

local p1_current_variant = {}
local p2_current_variant = {}
local p1_last_character = nil
local p2_last_character = nil
local p1_original_char = nil
local p2_original_char = nil

local function get_current_characters()
    if not manager or not manager.machine then
        return nil, nil
    end
    
    local machine = manager.machine
    local cpu = machine.devices[":maincpu"]
    if not cpu then return nil, nil end
    
    local mem = cpu.spaces["program"]
    if not mem then return nil, nil end
    
    local p1_char = mem:read_u8(memory_addresses.p1_char)
    local p2_char = mem:read_u8(memory_addresses.p2_char)
    
    if p1_char > 0x0C then p1_char = 0x00 end
    if p2_char > 0x0C then p2_char = 0x00 end
    
    return p1_char, p2_char
end

local function set_character_display(player, char_id)
    if not manager or not manager.machine then return end
    
    local machine = manager.machine
    local cpu = machine.devices[":maincpu"]
    if not cpu then return end
    
    local mem = cpu.spaces["program"]
    if not mem then return end
    
    if player == 1 then
        mem:write_u8(memory_addresses.p1_char, char_id)
        local verify = mem:read_u8(memory_addresses.p1_char)
        print(string.format("SAMSHO: P1 display set to 0x%02X (verify: 0x%02X)", char_id, verify))
    else
        mem:write_u8(memory_addresses.p2_char, char_id)
        local verify = mem:read_u8(memory_addresses.p2_char)
        print(string.format("SAMSHO: P2 display set to 0x%02X (verify: 0x%02X)", char_id, verify))
    end
end

local function cycle_character_variant(player, character_id)
    if not character_variants[character_id] then
        print(string.format("SAMSHO: P%d character 0x%02X has no variants", player, character_id))
        return
    end
    
    local char_data = character_variants[character_id]
    local variants = char_data.variants
    
    if #variants <= 1 then
        print(string.format("SAMSHO: P%d %s has only one variant", player, char_data.name))
        return
    end
    
    local variant_table = (player == 1) and p1_current_variant or p2_current_variant
    
    if not variant_table[character_id] then
        variant_table[character_id] = 1
        if player == 1 then
            p1_original_char = character_id
        else
            p2_original_char = character_id
        end
    end
    
    variant_table[character_id] = (variant_table[character_id] % #variants) + 1
    
    local variant_state = variants[variant_table[character_id]]
    print(string.format("SAMSHO: P%d %s variant %d/%d (state 0x%02X)", player, char_data.name, variant_table[character_id], #variants, variant_state))
    
    set_character_display(player, variant_state)
end

function samsho.init()
    print("SAMSHO module initialized")
    p1_current_variant = {}
    p2_current_variant = {}
    p1_last_character = nil
    p2_last_character = nil
    p1_original_char = nil
    p2_original_char = nil
    return true
end

function samsho.update()
    local p1_char, p2_char = get_current_characters()
    
    if not p1_char or not p2_char then
        return
    end
    
    if p1_char ~= p1_last_character then
        if p1_last_character and p1_last_character ~= p1_char then
            print(string.format("SAMSHO: P1 switched from 0x%02X to 0x%02X", p1_last_character, p1_char))
            p1_current_variant = {}
            p1_original_char = nil
        end
        p1_last_character = p1_char
    end
    
    if p2_char ~= p2_last_character then
        if p2_last_character and p2_last_character ~= p2_char then
            print(string.format("SAMSHO: P2 switched from 0x%02X to 0x%02X", p2_last_character, p2_char))
            p2_current_variant = {}
            p2_original_char = nil
        end
        p2_last_character = p2_char
    end
end

function samsho.cycle_p1_variant()
    local p1_char, _ = get_current_characters()
    if p1_char then
        local base_char = p1_original_char or p1_char
        cycle_character_variant(1, base_char)
    end
end

function samsho.cycle_p2_variant()
    local _, p2_char = get_current_characters()
    if p2_char then
        local base_char = p2_original_char or p2_char
        cycle_character_variant(2, base_char)
    end
end

function samsho.cycle_both_variants()
    samsho.cycle_p1_variant()
    samsho.cycle_p2_variant()
end

function samsho.cleanup()
    print("SAMSHO module cleanup")
    p1_current_variant = {}
    p2_current_variant = {}
    p1_last_character = nil
    p2_last_character = nil
    p1_original_char = nil
    p2_original_char = nil
end

return samsho