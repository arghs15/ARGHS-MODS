-- SF (Street Fighter) Game Module for Character Variants Plugin
local sf = {}

-- Character variants for SF (based on cheat file states + available images from names.txt)
-- Original Street Fighter only has Ken and Ryu
local character_variants = {
    -- Ken: 1 variant
    [0x00] = {
        name = "ken",
        states = {0x00}  -- Ken 01
    },
    -- Ryu: 1 variant  
    [0x01] = {
        name = "ryu",
        states = {0x01}  -- Ryu 01
    }
}

-- Memory addresses for SF (based on cheat file analysis)
local memory_addresses = {
    game_timer = 0xFF8E18,    -- Timer from "Infinite Time" cheat (32-bit)
    bonus_timer = 0xFF8E30,   -- Bonus stage timer
    p1_energy = 0xFF86B6,     -- P1 energy (16-bit)
    p2_energy = 0xFF86E0,     -- P2 energy (16-bit)
    p1_wins = 0xFF86B8,       -- P1 wins
    p2_wins = 0xFF86E2,       -- P2 wins
    cpu_wins = 0xFFC66C,      -- CPU wins
    p1_invincible = 0xFF96B0, -- P1 invincibility flag
    p2_invincible = 0xFF96DA, -- P2 invincibility flag
    cpu_invincible = 0xFFD664, -- CPU invincibility flag
    cpu_energy = 0xFFC66A     -- CPU energy
}

-- Character detection - SF doesn't seem to have explicit character selection addresses
-- We'll need to detect based on game state or use a simpler approach
local function detect_characters()
    -- For original SF, we'll assume:
    -- P1 is always player controlled (Ken or Ryu depending on cabinet/settings)
    -- P2/CPU cycles through opponents
    -- Since we don't have clear character selection addresses, we'll default to Ken vs Ryu
    return 0x00, 0x01  -- Default: Ken vs Ryu
end

-- Variant override memory - using different range for SF
local variant_memory = {
    p1_override_active = 0xFFFF90,
    p1_override_state = 0xFFFF91,
    p2_override_active = 0xFFFF92,
    p2_override_state = 0xFFFF93,
}

-- State tracking
local p1_current_variant = {}
local p2_current_variant = {}
local p1_last_character = nil
local p2_last_character = nil

-- Get current characters (simplified for SF)
local function get_current_characters()
    if not manager or not manager.machine then
        return nil, nil
    end
    
    local machine = manager.machine
    local cpu = machine.devices[":maincpu"]
    if not cpu then return nil, nil end
    
    local mem = cpu.spaces["program"]
    if not mem then return nil, nil end
    
    -- For SF, we'll use a simple detection method
    -- Check if we're in game (energy values exist)
    local p1_energy = mem:read_u16(memory_addresses.p1_energy)
    local p2_energy = mem:read_u16(memory_addresses.p2_energy)
    
    if p1_energy > 0 or p2_energy > 0 then
        -- Game is active, return default characters
        return 0x00, 0x01  -- Ken vs Ryu
    else
        -- No game active
        return 0x20, 0x20  -- Blank
    end
end

-- Clear variant override
local function clear_variant_override(player)
    if not manager or not manager.machine then return end
    
    local machine = manager.machine
    local cpu = machine.devices[":maincpu"]
    if not cpu then return end
    
    local mem = cpu.spaces["program"]
    if not mem then return end
    
    local override_addr = (player == 1) and variant_memory.p1_override_active or variant_memory.p2_override_active
    
    if pcall(function() 
        mem:write_u8(override_addr, 0)
    end) then
        print(string.format("SF: Cleared P%d variant override", player))
    else
        print(string.format("SF: Failed to clear P%d variant override", player))
    end
end

-- Trigger variant display
local function trigger_variant_display(player, variant_state)
    if not manager or not manager.machine then 
        print("SF: No manager or machine")
        return false
    end
    
    local machine = manager.machine
    local cpu = machine.devices[":maincpu"]
    if not cpu then 
        print("SF: No CPU device")
        return false
    end
    
    local mem = cpu.spaces["program"]
    if not mem then 
        print("SF: No memory space")
        return false
    end
    
    local override_addr, state_addr
    
    if player == 1 then
        override_addr = variant_memory.p1_override_active
        state_addr = variant_memory.p1_override_state
    else
        override_addr = variant_memory.p2_override_active
        state_addr = variant_memory.p2_override_state
    end
    
    -- Try to write with better error handling
    local write_success = false
    local error_msg = ""
    
    write_success, error_msg = pcall(function() 
        mem:write_u8(override_addr, 1)
        mem:write_u8(state_addr, variant_state)
        return true
    end)
    
    if write_success then
        -- Verify the write worked
        local verify_success, verify_msg = pcall(function()
            local check_override = mem:read_u8(override_addr)
            local check_state = mem:read_u8(state_addr)
            return check_override == 1 and check_state == variant_state
        end)
        
        if verify_success and verify_msg then
            print(string.format("SF: P%d variant set to 0x%02X - SUCCESS", player, variant_state))
            return true
        else
            print(string.format("SF: P%d variant write failed verification", player))
            return false
        end
    else
        print(string.format("SF: Memory write failed - %s", tostring(error_msg)))
        return false
    end
end

-- Cycle character variant
local function cycle_character_variant(player, character_id)
    if not character_variants[character_id] then
        print(string.format("SF: P%d character 0x%02X has no variants", player, character_id))
        return
    end
    
    local states = character_variants[character_id].states
    
    if #states <= 1 then
        if #states == 0 then
            print(string.format("SF: P%d %s has no image files available", 
                  player, character_variants[character_id].name))
        else
            print(string.format("SF: P%d %s has only one variant", 
                  player, character_variants[character_id].name))
        end
        return
    end
    
    local variant_table = (player == 1) and p1_current_variant or p2_current_variant
    
    if not variant_table[character_id] then
        variant_table[character_id] = 1
    end
    
    variant_table[character_id] = (variant_table[character_id] % #states) + 1
    
    local variant_state = states[variant_table[character_id]]
    print(string.format("SF: P%d %s variant %d/%d (state 0x%02X)", 
          player, character_variants[character_id].name, 
          variant_table[character_id], #states, variant_state))
    
    trigger_variant_display(player, variant_state)
end

-- Module API
function sf.init()
    print("SF module initialized")
    p1_current_variant = {}
    p2_current_variant = {}
    p1_last_character = nil
    p2_last_character = nil
    
    -- Clear memory on startup
    if manager and manager.machine then
        local machine = manager.machine
        local cpu = machine.devices[":maincpu"]
        if cpu then
            local mem = cpu.spaces["program"]
            if mem then
                pcall(function()
                    for i = 0, 15 do
                        mem:write_u8(0xFFFF90 + i, 0)
                    end
                    print("SF: Cleared variant override memory")
                end)
            end
        end
    end
    
    return true
end

function sf.update()
    local p1_char, p2_char = get_current_characters()
    
    if not p1_char or not p2_char then
        return
    end
    
    -- Handle P1 character changes
    if p1_char ~= p1_last_character then
        if p1_last_character and p1_last_character ~= 0x20 and
           p1_char ~= 0x20 and
           p1_char ~= p1_last_character then
            print(string.format("SF: P1 switched from 0x%02X to 0x%02X - clearing override", p1_last_character, p1_char))
            clear_variant_override(1)
        end
        p1_last_character = p1_char
    end
    
    -- Handle P2 character changes
    if p2_char ~= p2_last_character then
        if p2_last_character and p2_last_character ~= 0x20 and
           p2_char ~= 0x20 and
           p2_char ~= p2_last_character then
            print(string.format("SF: P2 switched from 0x%02X to 0x%02X - clearing override", p2_last_character, p2_char))
            clear_variant_override(2)
        end
        p2_last_character = p2_char
    end
end

function sf.cycle_p1_variant()
    local p1_char, _ = get_current_characters()
    
    print(string.format("SF: P1 character detected as 0x%02X", p1_char or 0))
    if p1_char and p1_char ~= 0x20 and (p1_char <= 0x01) then
        cycle_character_variant(1, p1_char)
    else
        print("SF: P1 character is invalid or not detected")
    end
end

function sf.cycle_p2_variant()
    local _, p2_char = get_current_characters()
    
    print(string.format("SF: P2 character detected as 0x%02X", p2_char or 0))
    if p2_char and p2_char ~= 0x20 and (p2_char <= 0x01) then
        cycle_character_variant(2, p2_char)
    else
        print("SF: P2 character is invalid or not detected")
    end
end

function sf.cycle_both_variants()
    sf.cycle_p1_variant()
    sf.cycle_p2_variant()
end

function sf.cleanup()
    print("SF module cleanup")
    p1_current_variant = {}
    p2_current_variant = {}
    p1_last_character = nil
    p2_last_character = nil
end

-- Debug function to show current game state
function sf.debug_state()
    if not manager or not manager.machine then
        print("SF: No manager or machine available")
        return
    end
    
    local machine = manager.machine
    local cpu = machine.devices[":maincpu"]
    if not cpu then
        print("SF: No CPU device")
        return
    end
    
    local mem = cpu.spaces["program"]
    if not mem then
        print("SF: No memory space")
        return
    end
    
    local timer = mem:read_u32(memory_addresses.game_timer)
    local p1_energy = mem:read_u16(memory_addresses.p1_energy)
    local p2_energy = mem:read_u16(memory_addresses.p2_energy)
    local p1_wins = mem:read_u8(memory_addresses.p1_wins)
    local p2_wins = mem:read_u8(memory_addresses.p2_wins)
    
    print(string.format("SF Debug - Timer: %d, P1 Energy: %d, P2 Energy: %d, P1 Wins: %d, P2 Wins: %d", 
          timer, p1_energy, p2_energy, p1_wins, p2_wins))
end

return sf