-- MSHVSF Game Module for Character Variants Plugin
local mshvsf = {}

-- Character variant definitions with their state mappings
local character_variants = {
    -- Cyclops: 01, 02
    [0x02] = {
        name = "cyclops",
        states = {0x02, 0x34}  -- Default, variant 2
    },
    -- Captain America: 01, 02
    [0x04] = {
        name = "captain_america",
        states = {0x04, 0x38}  -- Default, variant 2
    },
    -- Wolverine: 01, 02
    [0x08] = {
        name = "wolverine",
        states = {0x08, 0x3C}  -- Default, variant 2
    },
    -- Blackheart: 01, 02
    [0x10] = {
        name = "blackheart",
        states = {0x10, 0x40}  -- Default, variant 2
    },
    -- Ryu: 01, 02
    [0x12] = {
        name = "ryu",
        states = {0x12, 0x44}  -- Default, variant 2
    },
    -- Ken: 01, 02
    [0x14] = {
        name = "ken",
        states = {0x14, 0x48}  -- Default, variant 2
    },
    -- Chun Li: 01, 02
    [0x16] = {
        name = "chun_li",
        states = {0x16, 0x4C}  -- Default, variant 2
    },
    -- Dhalsim: 01, 02
    [0x18] = {
        name = "dhalsim",
        states = {0x18, 0x50}  -- Default, variant 2
    },
    -- Zangief: 01, 02, 03
    [0x1A] = {
        name = "zangief",
        states = {0x1A, 0x54, 0x56}  -- Default, variant 2, variant 3
    },
    -- M Bison: 01, 02
    [0x1C] = {
        name = "m_bison",
        states = {0x1C, 0x5C}  -- Default, variant 2
    },
    -- Akuma: 01, 02
    [0x1E] = {
        name = "akuma",
        states = {0x1E, 0x60}  -- Default, variant 2
    },
    -- Norimaro: 01, 02
    [0x22] = {
        name = "norimaro",
        states = {0x22, 0x64}  -- Default, variant 2
    },
    -- Dan: 01, 02
    [0x24] = {
        name = "dan",
        states = {0x24, 0x68}  -- Default, variant 2
    },
    -- Cyber Akuma: 01, 02, 03
    [0x26] = {
        name = "cyber_akuma",
        states = {0x26, 0x6C, 0x6E}  -- Default, variant 2, variant 3
    },
    -- Mech Zangief: 01, 02, 03, 04
    [0x28] = {
        name = "mech_zangief",
        states = {0x28, 0x74, 0x76, 0x78}  -- Default, variant 2, variant 3, variant 4
    },
    -- Evil Sakura: 01, 02, 03
    [0x2A] = {
        name = "evil_sakura",
        states = {0x2A, 0x80, 0x82}  -- Default, variant 2, variant 3
    },
    -- Shadow: 01, 02, 03
    [0x2C] = {
        name = "shadow",
        states = {0x2C, 0x88, 0x8A}  -- Default, variant 2, variant 3
    },
    -- US Agent: 01, 02, 03
    [0x2E] = {
        name = "us_agent",
        states = {0x2E, 0x90, 0x92}  -- Default, variant 2, variant 3
    },
    -- Mephisto: 01, 02, 03
    [0x30] = {
        name = "mephisto",
        states = {0x30, 0x98, 0x9A}  -- Default, variant 2, variant 3
    },
    -- Armored Spider Man: 01, 02
    [0x32] = {
        name = "armored_spider_man",
        states = {0x32, 0xA0}  -- Default, variant 2
    },
}

-- Memory addresses for character detection
local memory_addresses = {
    game_state1 = 0xFF0080,
    game_active = 0xFF0000,
    state_flag = 0xFF81C3,
    p1_char_addr1 = 0xFF3853,
    p2_char_addr1 = 0xFF3C53,
    p1_char_addr2 = 0xFF4053,
    p2_char_addr2 = 0xFF4453,
    round_flag = 0xFF6f93,
    round_p1 = 0xFF3800,
    round_p2 = 0xFF3C00
}

-- Memory locations for variant override
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

-- Function to get current character IDs based on game state
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
    
    -- Use the same logic as the layout file
    if mem:read_u8(memory_addresses.game_state1) == 1 or
       (mem:read_u8(memory_addresses.game_active) ~= 0 and mem:read_u8(memory_addresses.state_flag) == 255) then
        p1_char = mem:read_u8(memory_addresses.p1_char_addr1)
        p2_char = mem:read_u8(memory_addresses.p2_char_addr1)
    elseif (mem:read_u8(memory_addresses.game_active) ~= 0 and mem:read_u8(memory_addresses.round_flag) == 255 and
            mem:read_u8(memory_addresses.round_p1) == 0 and mem:read_u8(memory_addresses.round_p2) == 0) then
        p1_char = mem:read_u8(memory_addresses.p1_char_addr2)
        p2_char = mem:read_u8(memory_addresses.p2_char_addr2)
    elseif (mem:read_u8(memory_addresses.game_active) ~= 0 and mem:read_u8(memory_addresses.round_flag) == 255 and
            mem:read_u8(memory_addresses.round_p1) == 1 and mem:read_u8(memory_addresses.round_p2) == 1) then
        p1_char = mem:read_u8(memory_addresses.p1_char_addr1)
        p2_char = mem:read_u8(memory_addresses.p2_char_addr1)
    elseif (mem:read_u8(memory_addresses.game_active) ~= 0 and mem:read_u8(memory_addresses.round_flag) == 255 and
            mem:read_u8(memory_addresses.round_p1) == 0 and mem:read_u8(memory_addresses.round_p2) == 1) then
        p1_char = mem:read_u8(memory_addresses.p1_char_addr2)
        p2_char = mem:read_u8(memory_addresses.p2_char_addr1)
    elseif (mem:read_u8(memory_addresses.game_active) ~= 0 and mem:read_u8(memory_addresses.round_flag) == 255 and
            mem:read_u8(memory_addresses.round_p1) == 1 and mem:read_u8(memory_addresses.round_p2) == 0) then
        p1_char = mem:read_u8(memory_addresses.p1_char_addr1)
        p2_char = mem:read_u8(memory_addresses.p2_char_addr2)
    end
    
    -- Add debug logging
    if p1_char ~= 0x00 or p2_char ~= 0x00 then
        -- print(string.format("MSHVSF DEBUG: P1=0x%02X, P2=0x%02X", p1_char, p2_char))
    end
    
    return p1_char, p2_char
end

-- Function to clear variant override
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
    
    print(string.format("MSHVSF: Cleared P%d variant override", player))
end

-- Function to trigger variant display
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
    
    print(string.format("MSHVSF: P%d variant set to 0x%02X", player, variant_state))
end

-- Function to cycle character variant
local function cycle_character_variant(player, character_id)
    if not character_variants[character_id] then
        print(string.format("MSHVSF: P%d character 0x%02X has no variants", player, character_id))
        return
    end
    
    local states = character_variants[character_id].states
    
    if #states <= 1 then
        print(string.format("MSHVSF: P%d %s has only one variant", 
              player, character_variants[character_id].name))
        return
    end
    
    local variant_table = (player == 1) and p1_current_variant or p2_current_variant
    
    if not variant_table[character_id] then
        variant_table[character_id] = 1
    end
    
    variant_table[character_id] = (variant_table[character_id] % #states) + 1
    
    local variant_state = states[variant_table[character_id]]
    print(string.format("MSHVSF: P%d %s variant %d/%d (state 0x%02X)", 
          player, character_variants[character_id].name, 
          variant_table[character_id], #states, variant_state))
    
    trigger_variant_display(player, variant_state)
end

-- Module API functions
function mshvsf.init()
    print("MSHVSF module initialized")
    p1_current_variant = {}
    p2_current_variant = {}
    p1_last_character = nil
    p2_last_character = nil
    return true
end

function mshvsf.update()
    local p1_char, p2_char = get_current_characters()
    
    if not p1_char or not p2_char then
        return
    end
    
    -- Only clear overrides when switching to a DIFFERENT character (not just any change)
    if p1_char ~= p1_last_character then
        -- Only clear if we're switching from one real character to a different real character
        if p1_last_character and p1_last_character ~= 0x00 and
           p1_char ~= 0x00 and
           p1_char ~= p1_last_character then
            print(string.format("MSHVSF: P1 switched from 0x%02X to 0x%02X - clearing override", p1_last_character, p1_char))
            clear_variant_override(1)
        end
        p1_last_character = p1_char
    end
    
    if p2_char ~= p2_last_character then
        -- Only clear if we're switching from one real character to a different real character
        if p2_last_character and p2_last_character ~= 0x00 and
           p2_char ~= 0x00 and
           p2_char ~= p2_last_character then
            print(string.format("MSHVSF: P2 switched from 0x%02X to 0x%02X - clearing override", p2_last_character, p2_char))
            clear_variant_override(2)
        end
        p2_last_character = p2_char
    end
end

function mshvsf.cycle_p1_variant()
    local p1_char, _ = get_current_characters()
    if p1_char and p1_char ~= 0x00 then
        cycle_character_variant(1, p1_char)
    else
        print("MSHVSF: No P1 character detected")
    end
end

function mshvsf.cycle_p2_variant()
    local _, p2_char = get_current_characters()
    if p2_char and p2_char ~= 0x00 then
        cycle_character_variant(2, p2_char)
    else
        print("MSHVSF: No P2 character detected")
    end
end

function mshvsf.cycle_both_variants()
    mshvsf.cycle_p1_variant()
    mshvsf.cycle_p2_variant()
end

function mshvsf.cleanup()
    print("MSHVSF module cleanup")
    p1_current_variant = {}
    p2_current_variant = {}
    p1_last_character = nil
    p2_last_character = nil
end

return mshvsf