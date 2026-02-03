addon = {
    name    = 'WSTracker',
    author  = 'Xua',
    version = '0.7',
};

require('common');
local chat = require('chat');
local settings = require('settings');
local imgui = require('imgui');
local io = require('io');
local json = require('json');

-- Default Settings
local default_settings = {
    points = 0,
    target = 300,
    drk_mode = false,
    display = { visible = true, x = 100, y = 100 }
};

local function ensure_presets_exist()
    local dir = string.format('%sconfig/addons/%s/', AshitaCore:GetInstallPath(), addon.name);
    local path = dir .. 'presets.json';
    
    if (not ashita.fs.exists(dir)) then
        ashita.fs.create_directory(dir);
    end

    if (not ashita.fs.exists(path)) then
        local default_presets = {
            trial = 300,
            ["break"] = 500,
            relic = 100,
            mythic = 250,
            empyrean = 1500,
            magian = 400
        };
        local f = io.open(path, 'w');
        if (f) then
            f:write(json.encode(default_presets));
            f:close();
            print(chat.header(addon.name) .. chat.message('Created default presets.json in config folder.'));
        end
    end
end

ensure_presets_exist();
local s = settings.load(default_settings) or default_settings;
local completed_alerted = false;

local function load_preset(name)
    local path = string.format('%sconfig/addons/%s/presets.json', AshitaCore:GetInstallPath(), addon.name);
    if (not ashita.fs.exists(path)) then return nil end
    
    local f = io.open(path, 'r');
    if (not f) then return nil end
    local content = f:read('*all');
    f:close();
    
    if (content == nil or content == '') then return nil end
    
    local presets = json.decode(content);
    return presets[name:lower()] or nil;
end

ashita.events.register('packet_in', 'packet_in_cb', function (e)
    if (e.id == 0x28) then
        local packet = e.data;
        local actor_id = ashita.bits.unpack_be(packet, 40, 32);
        
        if (actor_id == GetPlayerEntity().ServerId) then
            local category = ashita.bits.unpack_be(packet, 82, 4);
            local is_dead = (ashita.bits.unpack_be(packet, 213, 4) == 6);

            if (s.drk_mode) then
                if ((category == 1 or category == 11) and is_dead) then
                    s.points = s.points + 1;
                    settings.save();
                end
            elseif (category == 3) then
                local sc_level = ashita.bits.unpack_be(packet, 213, 4);
                local gained = ({ [1]=2, [2]=3, [3]=5 })[sc_level] or 1;
                s.points = s.points + gained;
                settings.save();
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
        if (s.drk_mode) then 
            imgui.TextColored({1, 0.2, 0.2, 1}, "MODE: DRK UNLOCK");
        else
            imgui.TextColored({0.4, 0.8, 1, 1}, "MODE: WS TRIALS");
        end
        
        if (s.points >= s.target) then
            local color = (math.floor(os.clock() * 2) % 2 == 0) and {0, 1, 0, 1} or {1, 1, 1, 1};
            imgui.TextColored(color, "!!! GOAL REACHED !!!");
        else
            imgui.Text(string.format("Progress: %d / %d", s.points, s.target));
        end
        imgui.ProgressBar(math.min(1.0, s.points / s.target), { -1, 0 });
        imgui.End();
    end
end);

ashita.events.register('command', 'command_cb', function (e)
    local args = e.command:args();
    if (#args > 0 and args[1]:lower() == '/wspt') then
        local cmd = args[2] and args[2]:lower();
        local val = tonumber(args[3]);

        if (cmd == 'drk') then
            s.drk_mode = true; s.target = 100; s.points = 0; completed_alerted = false;
            print(chat.header(addon.name) .. 'Switched to DRK Unlock Mode (100 Melee Kills).');
        elseif (cmd == 'trial') then
            s.drk_mode = false; s.target = 300; s.points = 0; completed_alerted = false;
            print(chat.header(addon.name) .. 'Switched to Trial Mode (300 WS Points).');
        elseif (cmd == 'reset') then
            s.points = 0; completed_alerted = false;
        elseif (cmd == 'set' and val) then
            s.points = val;
        elseif (cmd == 'target' and val) then
            s.target = val;
        elseif (cmd ~= nil) then
            local p = load_preset(cmd);
            if (p) then 
                s.target = p; s.points = 0; s.drk_mode = false; completed_alerted = false; 
                print(chat.header(addon.name) .. 'Loaded preset: ' .. cmd .. ' (Target: ' .. p .. ')');
            else
                print(chat.header(addon.name) .. 'Commands: /wspt [drk | trial | reset | set # | target # | <preset>]');
            end
        end
        settings.save();
        e.blocked = true;
    end
end);