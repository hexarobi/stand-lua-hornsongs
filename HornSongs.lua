-- HornSongs v1.1
-- by Hexarobi
-- Install in `Stand/Lua Scripts`

util.require_natives(1660775568)

local pause=0

local do1=16
local re=17
local mi=18
local fa=19
local sol=20
local la=21
local ti=22
local do2=23

local C1 = 16
local D1 = 17
local E1 = 18
local F1 = 19
local G1 = 20
local A1 = 21
local B1 = 22
local C2 = 23

local whole = 1
local half = 2
local quarter = 4
local eighth = 8
local sixteenth = 16

local MOD_HORN = 14

local horn_on = false

local songs = {
    {
        -- From https://www.easymusicnotes.com/pdf-piano-1/twinkle-twinkle-little-star-classical-mozart-piano-level-1.pdf
        name = "Twinkle Twinkle Little Star",
        bpm = 90,
        notes = {
            pause,
            do1, do1, sol, sol, la, la, { pitch = sol, length = half }, pause,
            fa, fa, mi, mi, re, re, { pitch = do1, length = half }, pause,
            sol, sol, fa, fa, mi, mi, { pitch = re, length = half }, pause,
            sol, sol, fa, fa, mi, mi, { pitch = re, length = half }, pause,
            do1, do1, sol, sol, la, la, { pitch = sol, length = half }, pause,
            fa, fa, mi, mi, re, re, { pitch = do1, length = half }, pause,
        },
    },
    {
        -- From https://www.easymusicnotes.com/pdf-piano-1/au-claire-de-la-lune-children-traditional-piano-level-1.pdf
        name = "Au Claire De La Lune",
        bpm = 60,
        notes = {
            fa, fa, fa, sol, { pitch = la, length = half }, { pitch = sol, length = half },
            fa, la, sol, sol, { pitch = fa, length = whole },
            fa, fa, fa, sol,  { pitch = la, length = half }, { pitch = sol, length = half },
            fa, la, sol, sol, { pitch = fa, length = whole },
        },
    },
    {
        -- From https://www.easymusicnotes.com/pdf-piano-1/hot-cross-buns-children-traditional-piano-level-1.pdf
        name = "Hot Cross Buns",
        bpm = 60,
        notes = {
            { pitch = mi, length = half }, { pitch = re, length = half },
            { pitch = do1, length = half }, { pitch = pause, length = half },
            { pitch = mi, length = half }, { pitch = re, length = half },
            { pitch = do1, length = half }, { pitch = pause, length = half },
            do1, do1, do1, do1, re, re, re, re,
            { pitch = mi, length = half }, { pitch = re, length = half },
            { pitch = do1, length = half }, { pitch = pause, length = half },
        },
    },
}

local function get_note(note)
    if type(note) ~= "table" then
        note = {pitch=note}
    end
    if note.length == nil then
        note.length = quarter
    end
    return note
end

local function play_note(vehicle, song, note, index)
    note = get_note(note)
    local note_playtime = math.floor(song.beat_length / note.length)
    if note.pitch ~= pause then
        horn_on = true
        --VEHICLE.START_VEHICLE_HORN(vehicle, note_delay, util.joaat("HELDDOWN"), false)
    end
    util.yield(note_playtime)
    horn_on = false
    -- Que up pitch for next note
    if song.notes[index+1] ~= nil then
        local next_note = get_note(song.notes[index+1])
        if next_note.pitch ~= pause then
            VEHICLE.SET_VEHICLE_MOD(vehicle, MOD_HORN, next_note.pitch)
        end
    end
    util.yield(song.beat_length - note_playtime)
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
        for index, note in pairs(song.notes) do
            play_note(vehicle, song, note, index)
        end
        VEHICLE.SET_VEHICLE_MOD(vehicle, MOD_HORN, original_horn)
    end
end

for _, song in pairs(songs) do
    menu.action(menu.my_root(), "Play "..song.name, {}, "Spawns a car and plays song on its horn.", function()
        play_song(song)
    end)
end

util.create_tick_handler(function()
    if horn_on then
        PAD._SET_CONTROL_NORMAL(0, 86, 1)
    end
    return true
end)
