-- SFEX2 Plus Game Module - Fixed Memory Address Strategy
local sfex2p = {}

-- Communication flags (must match layout script)
local cycle_flag_p1 = 0x2E0000
local cycle_flag_p2 = 0x2E0001
local cycle_flag_both = 0x2E0002
-- New reset flags
local reset_flag_p1 = 0x2E0003
local reset_flag_p2 = 0x2E0004
local reset_flag_both = 0x2E0005

-- Add these new functions to your module:

function sfex2p.reset_p1_portrait()
    local mem = get_memory()
    if not mem then return end
    
    print("SFEX2P Plugin: P1 portrait reset requested")
    send_cycle_request(reset_flag_p1, "P1 Reset")
end

function sfex2p.reset_p2_portrait()
    local mem = get_memory()
    if not mem then return end
    
    print("SFEX2P Plugin: P2 portrait reset requested")
    send_cycle_request(reset_flag_p2, "P2 Reset")
end

function sfex2p.reset_both_portraits()
    local mem = get_memory()
    if not mem then return end
    
    print("SFEX2P Plugin: Both portraits reset requested")
    send_cycle_request(reset_flag_both, "Both Reset")
end

-- Update the cleanup function to clear all flags:
function sfex2p.cleanup()
    print("SFEX2P module cleanup")
    
    local mem = get_memory()
    if mem then
        pcall(function()
            mem:write_u8(cycle_flag_p1, 0)
            mem:write_u8(cycle_flag_p2, 0)
            mem:write_u8(cycle_flag_both, 0)
            mem:write_u8(reset_flag_p1, 0)
            mem:write_u8(reset_flag_p2, 0)
            mem:write_u8(reset_flag_both, 0)
            print("SFEX2P: All communication flags cleared on cleanup")
        end)
    end
end

-- Memory addresses for SFEX2 Plus - Multiple options to try
local char_addresses = {
    -- Character select addresses (priority 1)
    {p1 = 0x1F010, p2 = 0x1F011, name = "char_select"},
    -- Static character storage (common in fighters - priority 2)
    {p1 = 0x2AE5C0, p2 = 0x2AE5C1, name = "static_chars_1"},
    {p1 = 0x2AE5C4, p2 = 0x2AE5C5, name = "static_chars_2"},
    {p1 = 0x2AE600, p2 = 0x2AE601, name = "static_chars_3"},
    -- Round/match character storage
    {p1 = 0x2B6820, p2 = 0x2B8020, name = "match_chars_1"},
    {p1 = 0x2B6824, p2 = 0x2B8024, name = "match_chars_2"},
    {p1 = 0x2B6828, p2 = 0x2B8028, name = "match_chars_3"},
    -- Fighter data structure offsets
    {p1 = 0x2B6880, p2 = 0x2B8080, name = "fighter_data_1"},
    {p1 = 0x2B6884, p2 = 0x2B8084, name = "fighter_data_2"},
}

-- Other addresses
local memory_addresses = {
    game_timer = 0x2AE5BC,      -- Timer from "Infinite Time" cheat
    p1_energy = 0x2B68A8,       -- P1 energy from "P1 Infinite Energy" cheat
    p2_energy = 0x2B80AC,       -- P2 energy from "P2 Infinite Energy" cheat
}

-- Get memory interface
local function get_memory()
    if not manager or not manager.machine then
        return nil
    end
    
    local machine = manager.machine
    local cpu = machine.devices[":maincpu"]
    if not cpu then return nil end
    
    return cpu.spaces["program"]
end

-- Find current character data using the discovered addresses
local function get_character_data(mem)
    -- FIX: Use correct P2 address (0x1F011, not 0x1F014)
    local p1_char = mem:read_u8(0x1F010)
    local p2_char = mem:read_u8(0x1F011)  -- FIXED: was 0x1F014
    
    -- Validate characters
    if p1_char < 0x01 or p1_char > 0x17 then
        p1_char = 0x0F  -- Default to Ryu
    end
    if p2_char < 0x01 or p2_char > 0x17 then
        p2_char = 0x0F  -- Default to Ryu
    end
    
    return p1_char, p2_char, "discovered_addresses"
end

-- Send cycle request
local function send_cycle_request(flag_address, player_name)
    local mem = get_memory()
    if not mem then 
        print("SFEX2P: No memory interface available")
        return false
    end
    
    local success, error_msg = pcall(function()
        mem:write_u8(flag_address, 1)
    end)
    
    if success then
        print(string.format("SFEX2P Plugin: %s cycle request sent", player_name))
        return true
    else
        print(string.format("SFEX2P Plugin: Failed to send %s cycle request: %s", player_name, tostring(error_msg)))
        return false
    end
end

-- Module API
function sfex2p.init()
    print("SFEX2P module initialized for SFEX2 Plus")
    
    -- Clear all flags on startup
    local mem = get_memory()
    if mem then
        pcall(function()
            mem:write_u8(cycle_flag_p1, 0)
            mem:write_u8(cycle_flag_p2, 0)
            mem:write_u8(cycle_flag_both, 0)
            print("SFEX2P: Communication flags cleared")
        end)
    end
    
    return true
end

function sfex2p.update()
    -- No active processing needed
end

function sfex2p.cycle_p1_variant()
    local mem = get_memory()
    if not mem then return end
    
    local p1_char, p2_char, source = get_character_data(mem)
    print(string.format("SFEX2P Plugin: P1 cycle requested (char 0x%02X from %s)", p1_char, source))
    
    send_cycle_request(cycle_flag_p1, "P1")
end

function sfex2p.cycle_p2_variant()
    local mem = get_memory()
    if not mem then return end
    
    local p1_char, p2_char, source = get_character_data(mem)
    print(string.format("SFEX2P Plugin: P2 cycle requested (char 0x%02X from %s)", p2_char, source))
    
    send_cycle_request(cycle_flag_p2, "P2")
end

function sfex2p.cycle_both_variants()
    local mem = get_memory()
    if not mem then return end
    
    local p1_char, p2_char, source = get_character_data(mem)
    print(string.format("SFEX2P Plugin: Both cycle requested (P1: 0x%02X, P2: 0x%02X from %s)", p1_char, p2_char, source))
    
    send_cycle_request(cycle_flag_both, "Both")
end

function sfex2p.cleanup()
    print("SFEX2P module cleanup")
    
    -- Clear flags on cleanup
    local mem = get_memory()
    if mem then
        pcall(function()
            mem:write_u8(cycle_flag_p1, 0)
            mem:write_u8(cycle_flag_p2, 0)
            mem:write_u8(cycle_flag_both, 0)
            print("SFEX2P: Communication flags cleared on cleanup")
        end)
    end
end

-- Debug function
function sfex2p.debug_state()
    local mem = get_memory()
    if not mem then
        print("SFEX2P: No memory interface")
        return
    end
    
    local timer = mem:read_u8(memory_addresses.game_timer)
    local p1_char, p2_char, source = get_character_data(mem)
    
    local p1_flag, p2_flag, both_flag = 0, 0, 0
    
    pcall(function()
        p1_flag = mem:read_u8(cycle_flag_p1)
        p2_flag = mem:read_u8(cycle_flag_p2)
        both_flag = mem:read_u8(cycle_flag_both)
    end)
    
    print(string.format("SFEX2P Debug:"))
    print(string.format("  Timer: %d", timer))
    print(string.format("  Characters: P1=0x%02X, P2=0x%02X (from %s)", p1_char, p2_char, source))
    print(string.format("  Cycle Flags: P1=%d, P2=%d, Both=%d", p1_flag, p2_flag, both_flag))
end

return sfex2p