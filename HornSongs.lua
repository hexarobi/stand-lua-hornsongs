-- HornSongs v1.0
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

local whole = 1
local half = 2
local quarter = 4
local eighth = 8
local sixteenth = 16

local songs = {
    {
        name = "Twinkle Twinkle Little Star",
        bpm = 120,
        notes = {
            do1, do1, sol, sol, la, la, { pitch = sol, length = half }, pause,
            fa, fa, mi, mi, re, re, { pitch = do1, length = half }, pause,
            sol, sol, fa, fa, mi, mi, { pitch = re, length = half }, pause,
            sol, sol, fa, fa, mi, mi, { pitch = re, length = half }, pause,
            do1, do1, sol, sol, la, la, { pitch = sol, length = half }, pause,
            fa, fa, mi, mi, re, re, { pitch = do1, length = half }, pause,
        },
    }
}

local function load_hash(hash)
    STREAMING.REQUEST_MODEL(hash)
    while not STREAMING.HAS_MODEL_LOADED(hash) do
        util.yield()
    end
end

local function spawn_vehicle_for_player(pid, model_name)
    local model = util.joaat(model_name)
    if STREAMING.IS_MODEL_VALID(model) and STREAMING.IS_MODEL_A_VEHICLE(model) then
        load_hash(model)
        local target_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(target_ped, 0.0, 4.0, 0.5)
        local heading = ENTITY.GET_ENTITY_HEADING(target_ped)
        local vehicle = entities.create_vehicle(model, pos, heading)
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(model)
        return vehicle
    end
end

for _, song in pairs(songs) do
    menu.action(menu.my_root(), "Play "..song.name, {}, "Spawns a car and plays song on its horn.", function()
        local vehicle
        local spawned_vehicle = false
        --vehicle = entities.get_user_vehicle_as_handle()
        if not vehicle then
            vehicle = spawn_vehicle_for_player(players.user(), "kuruma2")
            spawned_vehicle = true
        end

        local ped_hash = util.joaat("s_m_m_pilot_01")
        load_hash(ped_hash)
        local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, 0, 0, 0)
        local ped = entities.create_ped(1, ped_hash, pos, 0.0)
        PED.SET_PED_INTO_VEHICLE(ped, vehicle, -1)

        ENTITY.FREEZE_ENTITY_POSITION(vehicle, true)

        local song_beat_length = math.floor((60 / song.bpm) * 1000)
        if vehicle then
            for _, note in pairs(song.notes) do
                if type(note) ~= "table" then
                    note = {pitch=note}
                end
                if note.length == nil then
                    note.length = quarter
                end
                local note_delay = math.floor(song_beat_length / note.length)
                if note.pitch ~= pause then
                    VEHICLE.SET_VEHICLE_MOD(vehicle, 14, note.pitch)
                    --AUDIO.SET_HORN_PERMANENTLY_ON_TIME(vehicle, note_delay)
                    VEHICLE.START_VEHICLE_HORN(vehicle, note_delay, util.joaat("HELDDOWN"), false)
                end
                util.yield(note_delay)
            end

            if spawned_vehicle then
                entities.delete_by_handle(ped)
                entities.delete_by_handle(vehicle)
            end
        end
    end)
end

util.create_tick_handler(function()
    return true
end)
