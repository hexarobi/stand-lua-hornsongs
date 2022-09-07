# stand-lua-hornsongs

A Lua Script for the Stand mod menu for GTA5.

Plays songs on your vehicles horn.

# Installation

Download [the project zip file](https://github.com/hexarobi/stand-lua-hornsongs/archive/refs/heads/main.zip) and extract into your `Stand/Lua Scripts` folder

# Add Horn Files

Add new `*.horn` files to `Stand/Lua Scripts/store/HornSongs/songs/`

# Create your own horn song files

Horn files are JSON format and contain meta data about the song, as well as `notes` list.

```
{
  "name": "Scales",
  "description": "Basic Music Theory\nEncoded by Hexarobi",
  "target_version": 1.2,
  "bpm": 100,
  "notes": [
    "C", "D", "E", "F", "G", "A", "B", "C2", "rest",
    "C2", "B", "A", "G", "F", "E", "D", "C", "rest"
  ]
}
```

#### Name

Song name

#### Description

Song description. Will be shown as help text. Use "\n" for line breaks.

#### Target Version

The version of HornSongs this file was created for.

### Beats Per Minute (BPM)

The tempo or speed of the song. Horns take time to change between notes, so you need a slow tempo to play properly to others.

### Notes

A list of notes to be played. Each will take up one beat, and be played for a quarter note (0.25), unless otherwise indicated with the `length` parameter.
Valid notes are `C`, `D`, `E`, `F`, `G`, `A`, `B`, `C2` and `rest` (no sound). No sharps/flats are supported, and only one horn is networked, so the musical range is very limited.
