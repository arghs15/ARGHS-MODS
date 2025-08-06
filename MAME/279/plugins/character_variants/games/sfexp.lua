-- SFEX Plus Game Module - Based on sfexp.xml cheat file
local sfexp = {}

-- Communication flags (must match layout script)
local cycle_flag_p1 = 0x2E0000
local cycle_flag_p2 = 0x2E0001
local cycle_flag_both = 0x2E0002

-- Memory addresses for SFEX Plus (from sfexp.xml)
local memory_addresses = {
    game_timer = 0x31D5CC,      -- Timer from "Infinite Time" cheat
    p1_char = 0x32358A,         -- P1 character from "P1 Select Character" cheat
    p2_char = 0x3249FE,         -- P2 character from "P2 Select Character" cheat
    p1_energy = 0x3249E4,       -- P1 energy from "P1 Infinite Energy" cheat
    p2_energy = 0x325E58        -- P2 energy from "P2 Infinite Energy" cheat
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

-- Send cycle request
local function send_cycle_request(flag_address, player_name)
    local mem = get_memory()
    if not mem then 
        print("SFEXP: No memory interface available")
        return false
    end
    
    local success, error_msg = pcall(function()
        mem:write_u8(flag_address, 1)
    end)
    
    if success then
        print(string.format("SFEXP Plugin: %s cycle request sent", player_name))
        return true
    else
        print(string.format("SFEXP Plugin: Failed to send %s cycle request: %s", player_name, tostring(error_msg)))
        return false
    end
end

-- Module API
function sfexp.init()
    print("SFEXP module initialized for SFEX Plus")
    
    -- Clear all flags on startup
    local mem = get_memory()
    if mem then
        pcall(function()
            mem:write_u8(cycle_flag_p1, 0)
            mem:write_u8(cycle_flag_p2, 0)
            mem:write_u8(cycle_flag_both, 0)
            print("SFEXP: Communication flags cleared")
        end)
    end
    
    return true
end

function sfexp.update()
    -- No active processing needed
end

function sfexp.cycle_p1_variant()
    local mem = get_memory()
    if not mem then return end
    
    local p1_char = mem:read_u8(memory_addresses.p1_char)
    print(string.format("SFEXP Plugin: P1 cycle requested (char 0x%02X)", p1_char))
    
    send_cycle_request(cycle_flag_p1, "P1")
end

function sfexp.cycle_p2_variant()
    local mem = get_memory()
    if not mem then return end
    
    local p2_char = mem:read_u8(memory_addresses.p2_char)
    print(string.format("SFEXP Plugin: P2 cycle requested (char 0x%02X)", p2_char))
    
    send_cycle_request(cycle_flag_p2, "P2")
end

function sfexp.cycle_both_variants()
    local mem = get_memory()
    if not mem then return end
    
    local p1_char = mem:read_u8(memory_addresses.p1_char)
    local p2_char = mem:read_u8(memory_addresses.p2_char)
    print(string.format("SFEXP Plugin: Both cycle requested (P1: 0x%02X, P2: 0x%02X)", p1_char, p2_char))
    
    send_cycle_request(cycle_flag_both, "Both")
end

function sfexp.cleanup()
    print("SFEXP module cleanup")
    
    -- Clear flags on cleanup
    local mem = get_memory()
    if mem then
        pcall(function()
            mem:write_u8(cycle_flag_p1, 0)
            mem:write_u8(cycle_flag_p2, 0)
            mem:write_u8(cycle_flag_both, 0)
            print("SFEXP: Communication flags cleared on cleanup")
        end)
    end
end

-- Debug function
function sfexp.debug_state()
    local mem = get_memory()
    if not mem then
        print("SFEXP: No memory interface")
        return
    end
    
    local timer = mem:read_u8(memory_addresses.game_timer)
    local p1_char = mem:read_u8(memory_addresses.p1_char)
    local p2_char = mem:read_u8(memory_addresses.p2_char)
    
    local p1_flag, p2_flag, both_flag = 0, 0, 0
    
    pcall(function()
        p1_flag = mem:read_u8(cycle_flag_p1)
        p2_flag = mem:read_u8(cycle_flag_p2)
        both_flag = mem:read_u8(cycle_flag_both)
    end)
    
    print(string.format("SFEXP Debug:"))
    print(string.format("  Timer: %d", timer))
    print(string.format("  Characters: P1=0x%02X, P2=0x%02X", p1_char, p2_char))
    print(string.format("  Cycle Flags: P1=%d, P2=%d, Both=%d", p1_flag, p2_flag, both_flag))
end

return sfexp