# Slab

![Slab v2 in brackenhide hollow](readme/brackenhide_casts.png)

Slab is a slim and colorful nameplate addon for Retail World of Warcraft with a focus on being clear, simple & efficient. It uses color to distinguish different classes of enemies, with high-visibility colors for dangerous threat states.

**Status:** Actively tweaking. Main functionality is set.

### Features

- Built-in support for threat and tank pets.
- Built-in cast bars with support for cast targets.
- Compatible with (most) existing nameplate WAs.
- Option-free. Install & go, no fiddling allowed.


### Enemy Classes

<p align="center">
<img alt="Slab v2 Colors" src="readme/v2_color_grid.png" />
</p>

- Boss: A Dungeon or Raid boss (or world boss, in open world content)
- Lieutenant: Traditionally a level 71 enemy in a dungeon or 72 in raid. These are usually immune to CCs and have important mechanics.
- Normal: Most enemies you encounter fall into the "normal" category.
- Trivial: "Spam" enemies like lashers on Gnarlroot and low-level enemies in Dungeons.
- Special: Noteworthy units like Explosive Orbs that require special attention.

### A Note on CVars and Plater

Many aspects of nameplates in WoW are controlled by CVars, which are stored as part of your game configuration independently of any addon. If you've used Plater, you likely have a large number of CVars set from adjusting nameplate settings through the Plater options.

Slab resets the following CVars to their default values:

- `NamePlateMinAlpha`
- `NamePlateMinAlphaDistance`
- `NamePlateMinScale`
- `NamePlateMinScaleDistance`
- `NamePlateMaxScale`
- `NamePlateMaxScaleDistance`

## Efficient

Slab was written with efficiency in mind. Any frame drops in-game are dealt with ruthlessly---I will cut features if it means maintaining a seemless high framerate in-game.

# License

Copyright 2022 emallson. Published under the BSD 3-Clause.

There are small snippets of code cribbed in whole or part from Plater and KuiNameplates, which do not have a license listed. These bits are commented as such in the code.
