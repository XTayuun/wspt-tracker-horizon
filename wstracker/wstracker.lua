addon = {
    name    = 'WSTracker',
    author  = 'Xua',
    version = '1.1',
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
            local byte10 = struct.unpack('B', packet, 11);
            local category = bit.band(bit.rshift(byte10, 2), 0x0f);

            if (category == 3) then
                local total_gained = 1;

                local byte26 = struct.unpack('B', packet, 27);
                local sc_level = bit.band(bit.rshift(byte26, 5), 0x07);

                if (sc_level == 1) then
                    total_gained = 2;
                elseif (sc_level == 2) then
                    total_gained = 3;
                elseif (sc_level == 3) then
                    total_gained = 5;
                end
                
                s.points = s.points + total_gained;
                settings.save();
                completed_alerted = false;
                print(chat.header(addon.name) .. chat.message(string.format("Weapon Skill! +%d (Total: %d)", total_gained, s.points)));
            
            elseif (s.drk_mode and category == 1) then
                local byte26 = struct.unpack('B', packet, 27);
                local msg = bit.band(bit.rshift(byte26, 5), 0x07);
                if (msg == 6) then
                    s.points = s.points + 1;
                    settings.save();
                    completed_alerted = false;
                    print(chat.header(addon.name) .. chat.message("Kill tracked!"));
                end
            end

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