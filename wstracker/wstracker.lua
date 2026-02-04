addon = {
    name    = 'WSTracker',
    author  = 'Xua',
    version = '1.2',
};

local SC_LEVELS = {
    [288]=1, [289]=1, [290]=1, [291]=1, [292]=1, [293]=1, [294]=1, [295]=1, -- Lv1 (Liquefaction, etc)
    [296]=2, [297]=2, [298]=2, [299]=2,                                    -- Lv2 (Fusion, etc)
    [300]=4, [301]=4                                                       -- Lv3 (Light/Dark)
};

require('common');
local chat = require('chat');
local settings = require('settings');
local imgui = require('imgui');
local io = require('io');
local json = require('json');

local default_settings = {
    points = 0,
    target = 300,
    drk_mode = false,
    display = { visible = true, x = 100, y = 100 }
};

local function ensure_presets_exist()
    local dir = string.format('%sconfig/addons/%s/', AshitaCore:GetInstallPath(), addon.name);
    local path = dir .. 'presets.json';
    if (not ashita.fs.exists(dir)) then ashita.fs.create_directory(dir); end
    if (not ashita.fs.exists(path)) then
        local default_presets = { trial = 300, ["break"] = 500, relic = 100, mythic = 250, empyrean = 1500, magian = 400 };
        local f = io.open(path, 'w');
        if (f) then f:write(json.encode(default_presets)); f:close(); end
    end
end

ensure_presets_exist();
local s = settings.load(default_settings) or default_settings;
local completed_alerted = false;

ashita.events.register('packet_in', 'wsptracker_packet_cb', function (e)
    if (e.id == 0x28) then
        local packet = e.data;
        if (packet:len() < 32) then return end

        local actor_id = struct.unpack('I', packet, 6);
        local my_id = AshitaCore:GetMemoryManager():GetParty():GetMemberServerId(0);

        if (actor_id == my_id) then
            local byte11 = struct.unpack('B', packet, 11);
            local category = bit.band(bit.rshift(byte11, 2), 0x0F);

            -- 1. Award base 1 point for the WS
            if (category == 3) then
                s.points = s.points + 1;
                settings.save();
                completed_alerted = false;
                print(chat.header(addon.name) .. chat.message(string.format("Weapon Skill! +1 (Total: %d)", s.points)));
            
            -- 2. Award BONUS points if an explicit SC message is found
            elseif (category == 3 or category == 4) then
                local message_id = bit.band(bit.rshift(struct.unpack('H', packet, 27), 2), 0x7FF);
                local bonus = SC_LEVELS[message_id];
                
                if (bonus) then
                    s.points = s.points + bonus;
                    settings.save();
                    print(chat.header(addon.name) .. chat.message(string.format("Skillchain Bonus! +%d (Total: %d)", bonus, s.points)));
                end

            -- 3. DRK Mode Kill tracking
            elseif (s.drk_mode and category == 1) then
                local byte27 = struct.unpack('B', packet, 27);
                local msg = bit.band(bit.rshift(byte27, 5), 0x07);
                if (msg == 6) then
                    s.points = s.points + 1;
                    settings.save();
                    completed_alerted = false;
                    print(chat.header(addon.name) .. chat.message("Kill tracked!"));
                end
            end

            -- Goal Alert
            if (s.points >= s.target and not completed_alerted) then
                AshitaCore:GetChatManager():QueueCommand(-1, '/ashita.play_sound 210');
                print(chat.header(addon.name) .. chat.success('GOAL REACHED!'));
                completed_alerted = true;
            end
        end
    end
end);

ashita.events.register('d3d_present', 'present_cb', function ()
    if not s.display.visible then return end
    imgui.SetNextWindowSize({ 180, 85 }, ImGuiCond_FirstUseEver);
    if (imgui.Begin('WSP Tracker', true, ImGuiWindowFlags_NoResize + ImGuiWindowFlags_AlwaysAutoResize)) then
        if (s.drk_mode) then imgui.TextColored({1, 0.2, 0.2, 1}, "MODE: DRK UNLOCK");
        else imgui.TextColored({0.4, 0.8, 1, 1}, "MODE: WS TRIALS"); end
        imgui.Text(string.format("Progress: %d / %d", s.points, s.target));
        imgui.ProgressBar(math.min(1.0, s.points / s.target), { -1, 0 });
        imgui.End();
    end
end);

ashita.events.register('command', 'command_cb', function (e)
    local args = e.command:args();
    if (#args > 0 and args[1]:lower() == '/wspt') then
        local cmd = args[2] and args[2]:lower();
        if (cmd == 'reset') then s.points = 0; completed_alerted = false;
        elseif (cmd == 'drk') then s.drk_mode = true; s.target = 100; s.points = 0;
        elseif (cmd == 'trial') then s.drk_mode = false; s.target = 300; s.points = 0;
        end
        settings.save();
        e.blocked = true;
    end
end);