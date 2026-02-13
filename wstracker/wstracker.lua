addon = {
    name    = 'WSTracker',
    author  = 'Xua',
    version = '1.3',
};

require('common');
local chat = require('chat');
local settings = require('settings');
local imgui = require('imgui');

-- Configuration
local default_settings = {
    points = 0,
    target = 300,
    drk_mode = false,
    display = { visible = true, x = 100, y = 100 }
};

local s = settings.load(default_settings) or default_settings;
local last_ws_time = 0;
local last_equipped_id = 0; -- To prevent chat spam

-- SKILLCHAIN BONUS MAP
local sc_bonus_map = {
    [290] = 2, [291] = 2, [292] = 2, [293] = 2, -- Lv2
    [288] = 1, [289] = 1, [290] = 1, [291] = 1, [292] = 1, [293] = 1, [294] = 1, [295] = 1, -- Lv1
    [296] = 2, [297] = 2, [298] = 2, [299] = 2, -- Lv2
    [300] = 4, [301] = 4  -- Lv3
};

-- WEAPON DATABASE (Derived from trials.lua)
local weapon_db = {
    -- DRK Unlock
    [16607] = { target = 100, mode = 'drk', name = "Chaosbringer" },

    -- 300 Point Trials (Latent Weapons)
    [16735] = { target = 300, mode = 'normal', name = "Axe of Trials" },
    [16793] = { target = 300, mode = 'normal', name = "Scythe of Trials" },
    [16892] = { target = 300, mode = 'normal', name = "Spear of Trials" },
    [16952] = { target = 300, mode = 'normal', name = "Sword of Trials" },
    [17456] = { target = 300, mode = 'normal', name = "Club of Trials" },
    [17507] = { target = 300, mode = 'normal', name = "Knuckles of Trials" },
    [17527] = { target = 300, mode = 'normal', name = "Pole of Trials" },
    [17616] = { target = 300, mode = 'normal', name = "Dagger of Trials" },
    [17654] = { target = 300, mode = 'normal', name = "Sapara of Trials" },
    [17773] = { target = 300, mode = 'normal', name = "Kodachi of Trials" },
    [17815] = { target = 300, mode = 'normal', name = "Tachi of Trials" },
    [17933] = { target = 300, mode = 'normal', name = "Pick of Trials" },
    [18144] = { target = 300, mode = 'normal', name = "Bow of Trials" },
    [18146] = { target = 300, mode = 'normal', name = "Gun of Trials" },

    -- 500 Point Trials (Broken Weapons / KSNM)
    [17451] = { target = 500, mode = 'normal', name = "Morgenstern" },
    [17509] = { target = 500, mode = 'normal', name = "Destroyers" },
    [17589] = { target = 500, mode = 'normal', name = "Thyrsusstab" },
    [17699] = { target = 500, mode = 'normal', name = "Dissector" },
    [17793] = { target = 500, mode = 'normal', name = "Senjuinrikio" },
    [17827] = { target = 500, mode = 'normal', name = "Michishiba" },
    [17944] = { target = 500, mode = 'normal', name = "Retributor" },
    [18005] = { target = 500, mode = 'normal', name = "Heart Snatcher" },
    [18053] = { target = 500, mode = 'normal', name = "Gravedigger" },
    [18097] = { target = 500, mode = 'normal', name = "Gondo-Shizunori" },
    [18217] = { target = 500, mode = 'normal', name = "Rampager" },
    [18378] = { target = 500, mode = 'normal', name = "Subduer" },
    [17207] = { target = 500, mode = 'normal', name = "Expunger" },
    [17275] = { target = 500, mode = 'normal', name = "Coffinmaker" },
};

-- RECURSIVE PACKET PARSER
local function ParseActionPacket(e)
local bitData = e.data_raw;
local bitOffset = 40;
local maxLength = e.size * 8;

local function UnpackBits(length)
if ((bitOffset + length) > maxLength) then return 0; end
    local value = ashita.bits.unpack_be(bitData, 0, bitOffset, length);
bitOffset = bitOffset + length;
return value;
end

local packet = T{};
packet.UserId = UnpackBits(32);
local targetCount = UnpackBits(6);
bitOffset = bitOffset + 4;
packet.Type = UnpackBits(4);
packet.Id = UnpackBits(32);
bitOffset = bitOffset + 32;

packet.Targets = T{};
for i = 1, targetCount do
    local target = T{ Actions = T{} };
target.Id = UnpackBits(32);
local actionCount = UnpackBits(4);
for j = 1, actionCount do
    local action = {};
action.Reaction = UnpackBits(5);
action.Animation = UnpackBits(12);
action.SpecialEffect = UnpackBits(7);
action.Knockback = UnpackBits(3);
action.Param = UnpackBits(17);
action.Message = UnpackBits(10);
action.Flags = UnpackBits(31);

if (UnpackBits(1) == 1) then
    action.AdditionalEffect = {
        Damage = UnpackBits(10),
        Param = UnpackBits(17),
        Message = UnpackBits(10),
    };
end
if (UnpackBits(1) == 1) then
    action.SpikesEffect = {
        Damage = UnpackBits(10),
        Param = UnpackBits(14),
        Message = UnpackBits(10)
    };
end
target.Actions:append(action);
end
packet.Targets:append(target);
end
return packet;
end

-- SMART WEAPON CHECK
local function CheckWeaponMode()
local inventory = AshitaCore:GetMemoryManager():GetInventory();
local equipment = inventory:GetEquippedItem(0); -- Main Hand

if (equipment and equipment.Index ~= 0) then
    local item_id = inventory:GetContainerItem(bit.rshift(equipment.Index, 8), bit.band(equipment.Index, 0xFF)).Id;

-- Only update if weapon changed
if (item_id ~= last_equipped_id) then
    last_equipped_id = item_id;

local w_info = weapon_db[item_id];
if (w_info) then
    s.target = w_info.target;
s.drk_mode = (w_info.mode == 'drk');

print(chat.header(addon.name) .. chat.success(string.format("Equipped: %s", w_info.name)));
print(chat.header(addon.name) .. chat.message(string.format("Target auto-set to: %d pts (%s Mode)", s.target, s.drk_mode and "DRK" or "Normal")));
else
    -- If switching to an unknown weapon, default to 300/Normal (Safe fallback)
    if (s.drk_mode or s.target ~= 300) then
        s.target = 300;
    s.drk_mode = false;
print(chat.header(addon.name) .. chat.message("Unknown weapon. Reverting to Standard Trial Mode (300 pts)."));
end
end
end
end
end

-- PACKET HANDLER
ashita.events.register('packet_in', 'wsptracker_packet_cb', function (e)
if (e.id == 0x28) then
    local my_id = AshitaCore:GetMemoryManager():GetParty():GetMemberServerId(0);
local action = ParseActionPacket(e);

if (action.UserId == my_id and action.Type == 3) then
    CheckWeaponMode();

local now = os.clock();
if (now - last_ws_time < 0.2) then return end
    last_ws_time = now;

local bonus = 0;
local first_target = action.Targets[1];

if first_target and first_target.Actions[1] then
    local act = first_target.Actions[1];
if (act.Reaction == 0x01 or act.Reaction == 0x09) then return end -- Miss

    if act.AdditionalEffect then
        bonus = sc_bonus_map[act.AdditionalEffect.Message] or 0;
    end
    end

    local earned = 1;
if (not s.drk_mode) then earned = earned + bonus; end

    s.points = s.points + earned;

if (bonus > 0 and not s.drk_mode) then
    print(chat.header(addon.name) .. chat.success(string.format("Skillchain! +%d Bonus (Total Gained: %d)", bonus, earned)));
else
    print(chat.header(addon.name) .. chat.message(string.format("WS Hit! +1 (Total: %d)", s.points)));
end

if (s.points >= s.target) then
    print(chat.header(addon.name) .. chat.success("TRIAL COMPLETE!"));
end

settings.save();
end
end
end);

-- UI RENDERING
ashita.events.register('d3d_present', 'present_cb', function ()
if not s.display.visible then return end
    imgui.SetNextWindowSize({ 220, 90 }, ImGuiCond_AlwaysAutoResize);
if (imgui.Begin('WSP Tracker', true, ImGuiWindowFlags_NoResize)) then
    if (s.drk_mode) then
        imgui.TextColored({1.0, 0.2, 0.2, 1.0}, "MODE: CHAOSBRINGER");
    elseif (s.target == 500) then
        imgui.TextColored({0.5, 0.8, 1.0, 1.0}, "MODE: BROKEN WEAPON (500)");
    else
        imgui.TextColored({0.5, 1.0, 0.5, 1.0}, "MODE: LATENT WEAPON (300)");
    end

    imgui.Separator();
imgui.Text(string.format("Progress: %d / %d", s.points, s.target));
imgui.ProgressBar(math.min(1.0, s.points / s.target), { -1, 15 });
imgui.End();
end
end);

-- COMMANDS
ashita.events.register('command', 'command_cb', function (e)
local args = e.command:args();
if (#args > 0 and args[1]:lower() == '/wspt') then
    local cmd = args[2] and args[2]:lower();
if (cmd == 'reset') then s.points = 0; print(chat.header(addon.name).."Reset.");
elseif (cmd == 'set' and args[3]) then s.points = tonumber(args[3]) or s.points;
elseif (cmd == 'target' and args[3]) then s.target = tonumber(args[3]) or s.target;
elseif (cmd == 'drk') then s.drk_mode = not s.drk_mode;
end
settings.save();
return true;
end
end);
