-- HornSongs
-- by Hexarobi
-- https://github.com/hexarobi/stand-lua-hornsongs

local SCRIPT_VERSION = "1.6"

-- Auto Updater from https://github.com/hexarobi/stand-lua-auto-updater
local status, auto_updater = pcall(require, "auto-updater")
if not status then
    local auto_update_complete = nil util.toast("Installing auto-updater...", TOAST_ALL)
    async_http.init("raw.githubusercontent.com", "/hexarobi/stand-lua-auto-updater/main/auto-updater.lua",
            function(result, headers, status_code)
                local function parse_auto_update_result(result, headers, status_code)
                    local error_prefix = "Error downloading auto-updater: "
                    if status_code ~= 200 then util.toast(error_prefix..status_code, TOAST_ALL) return false end
                    if not result or result == "" then util.toast(error_prefix.."Found empty file.", TOAST_ALL) return false end
                    filesystem.mkdir(filesystem.scripts_dir() .. "lib")
                    local file = io.open(filesystem.scripts_dir() .. "lib\\auto-updater.lua", "wb")
                    if file == nil then util.toast(error_prefix.."Could not open file for writing.", TOAST_ALL) return false end
                    file:write(result) file:close() util.toast("Successfully installed auto-updater lib", TOAST_ALL) return true
                end
                auto_update_complete = parse_auto_update_result(result, headers, status_code)
            end, function() util.toast("Error downloading auto-updater lib. Update failed to download.", TOAST_ALL) end)
    async_http.dispatch() local i = 1 while (auto_update_complete == nil and i < 40) do util.yield(250) i = i + 1 end
    if auto_update_complete == nil then error("Error downloading auto-updater lib. HTTP Request timeout") end
    auto_updater = require("auto-updater")
end
if auto_updater == true then error("Invalid auto-updater lib. Please delete your Stand/Lua Scripts/lib/auto-updater.lua and try again") end

local auto_update_config = {
    source_url="https://raw.githubusercontent.com/hexarobi/stand-lua-hornsongs/main/HornSongs.lua",
    script_relpath=SCRIPT_RELPATH,
}
auto_updater.run_auto_update(auto_update_config)

util.require_natives(1660775568)

local pitch_map = {
    rest = 0,
    C = 16,
    D = 17,
    E = 18,
    F = 19,
    G = 20,
    A = 21,
    B = 22,
    C2 = 23,
}

local rest = 0

local double = 2
local whole = 1
local half = 0.5
local quarter = 0.25
local eighth = 0.125
local sixteenth = 0.0625

local MOD_HORN = 14

local horn_on = false

local script_store_dir = filesystem.store_dir() .. SCRIPT_NAME .. '\\'
if not filesystem.is_dir(script_store_dir) then
    filesystem.mkdirs(script_store_dir)
end

local function join_path(parent, child)
    local sub = parent:sub(-1)
    if sub == "/" or sub == "\\" then
        return parent .. child
    else
        return parent .. "/" .. child
    end
end

---
--- Play Music
---

local function get_note(note)
    if type(note) ~= "table" then
        note = {pitch=note}
    end
    if type(note.pitch) ~= "number" then
        note.pitch = pitch_map[note.pitch]
    end
    if note.length == nil then
        note.length = quarter
    end
    return note
end

local function play_note(vehicle, song, note, index)
    note = get_note(note)
    local note_playtime = math.floor(song.beat_length * note.length)
    if note.pitch ~= rest then
        horn_on = true
        --VEHICLE.START_VEHICLE_HORN(vehicle, note_delay, util.joaat("HELDDOWN"), false)
    end
    util.yield(note_playtime)
    horn_on = false
    -- Que up pitch for next note
    if song.notes[index+1] ~= nil then
        local next_note = get_note(song.notes[index+1])
        if next_note.pitch ~= rest then
            VEHICLE.SET_VEHICLE_MOD(vehicle, MOD_HORN, next_note.pitch)
        end
    end
    local beat_length = song.beat_length
    if note.beat_length ~= nil then
        beat_length = beat_length * note.beat_length
    end
    util.yield(beat_length - note_playtime)
    end

local function play_song(song)
    song.beat_length = math.floor(60000 / song.bpm)
    if not PED.IS_PED_IN_ANY_VEHICLE(PLAYER.PLAYER_PED_ID(), true) then
        util.toast("Cannot play horn unless within a vehicle")
        return
    end
    local vehicle = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false)
    if vehicle then
        local original_horn = VEHICLE.GET_VEHICLE_MOD(vehicle, MOD_HORN)
        play_note(vehicle, song, rest, 0)
        for index, note in pairs(song.notes) do
            play_note(vehicle, song, note, index)
        end
        VEHICLE.SET_VEHICLE_MOD(vehicle, MOD_HORN, original_horn)
    end
end

---
--- Songs Menu
---

local songs_menu = menu.list(menu.my_root(), "Play Song")

local _, json = pcall(require, "json")
local function load_song_from_file(filepath)
    local file = io.open(filepath, "r")
    if file then
        local data = json.decode(file:read("*a"))
        if not data.target_version then
            util.toast("Invalid horn file format. Missing target_version.")
            return nil
        end
        file:close()
        return data
    else
        error("Could not read file '" .. filepath .. "'")
    end
end

local function load_songs(directory)
    local loaded_songs = {}
    for _, filepath in ipairs(filesystem.list_files(directory)) do
        local _, filename, ext = string.match(filepath, "(.-)([^\\/]-%.?([^%.\\/]*))$")
        if not filesystem.is_dir(filepath) and ext == "horn" then
            table.insert(loaded_songs, load_song_from_file(filepath))
        end
    end
    return loaded_songs
end

local songs_dir = join_path(script_store_dir, "songs")
local songs = load_songs(songs_dir)
for _, song in pairs(songs) do
    menu.action(songs_menu, "Play "..song.name, {}, song.description .. "\nBPM: " .. song.bpm, function()
        play_song(song)
    end)
end

---
--- Script Meta
---

local script_meta_menu = menu.list(menu.my_root(), "About HornSongs")

menu.divider(script_meta_menu, "HornSongs")
menu.readonly(script_meta_menu, "Version", SCRIPT_VERSION)
if auto_update_config ~= nil then
    menu.action(script_meta_menu, "Check for Update", {}, "The script will automatically check for updates at most daily, but you can manually check using this option anytime.", function()
        auto_update_config.check_interval = 0
        if auto_updater.run_auto_update(auto_update_config) then
            util.toast(t("No updates found"))
        end
    end)
    menu.action(script_meta_menu, "Clean Reinstall", {}, "Force an update to the latest version, regardless of current version.", function()
        auto_update_config.clean_reinstall = true
        auto_updater.run_auto_update(auto_update_config)
    end)
end
menu.hyperlink(script_meta_menu, "GitHub Source", "https://github.com/hexarobi/stand-lua-hornsongs", "View source files on Github")
menu.hyperlink(script_meta_menu, "Discord", "https://discord.gg/2u5HbHPB9y", "Open Discord Server")

util.create_tick_handler(function()
    if horn_on then
        PAD._SET_CONTROL_NORMAL(0, 86, 1)
    end
    return true
end)
