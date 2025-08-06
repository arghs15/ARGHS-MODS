-- SFEX Game Module - SIMPLE FLAG COMMUNICATION
local sfex = {}

-- Communication flags (must match layout script)
local cycle_flag_p1 = 0x2E0000
local cycle_flag_p2 = 0x2E0001
local cycle_flag_both = 0x2E0002

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
        print("SFEX: No memory interface available")
        return false
    end
    
    local success, error_msg = pcall(function()
        mem:write_u8(flag_address, 1)
    end)
    
    if success then
        print(string.format("SFEX Plugin: %s cycle request sent", player_name))
        return true
    else
        print(string.format("SFEX Plugin: Failed to send %s cycle request: %s", player_name, tostring(error_msg)))
        return false
    end
end

-- Module API
function sfex.init()
    print("SFEX module initialized (simple flag communication)")
    
    -- Clear all flags on startup
    local mem = get_memory()
    if mem then
        pcall(function()
            mem:write_u8(cycle_flag_p1, 0)
            mem:write_u8(cycle_flag_p2, 0)
            mem:write_u8(cycle_flag_both, 0)
            print("SFEX: Communication flags cleared")
        end)
    end
    
    return true
end

function sfex.update()
    -- No active processing needed
end

function sfex.cycle_p1_variant()
    send_cycle_request(cycle_flag_p1, "P1")
end

function sfex.cycle_p2_variant()
    send_cycle_request(cycle_flag_p2, "P2")
end

function sfex.cycle_both_variants()
    send_cycle_request(cycle_flag_both, "Both")
end

function sfex.cleanup()
    print("SFEX module cleanup")
    
    -- Clear flags on cleanup
    local mem = get_memory()
    if mem then
        pcall(function()
            mem:write_u8(cycle_flag_p1, 0)
            mem:write_u8(cycle_flag_p2, 0)
            mem:write_u8(cycle_flag_both, 0)
            print("SFEX: Communication flags cleared on cleanup")
        end)
    end
end

-- Debug function
function sfex.debug_state()
    local mem = get_memory()
    if not mem then
        print("SFEX: No memory interface")
        return
    end
    
    local p1_flag, p2_flag, both_flag = 0, 0, 0
    
    pcall(function()
        p1_flag = mem:read_u8(cycle_flag_p1)
        p2_flag = mem:read_u8(cycle_flag_p2)
        both_flag = mem:read_u8(cycle_flag_both)
    end)
    
    print(string.format("SFEX Debug: Flags P1=%d, P2=%d, Both=%d", p1_flag, p2_flag, both_flag))
end

return sfex