@tool
extends Resource
class_name WorldDescription
## What a world of the game's own format is, apart from its files: its title and description (the
## scenario selector's), its frame (the projection its coordinates are in and their origin), its
## middle, where a player starts, and what it is drawn with - the world assets' packs it mounts, its
## biomes, its terrain's atlas. Kept beside the world's sources (FILE in worlds/<name>/), edited in
## the inspector; the game's description of the world (worlds/<name>.json, libmaszyna's
## ReloadedProWorld.read_description()) is made of it when the world is packed (WorldPacker.pack()). Its
## era (era_preset, era_year) is the scenery importer's alone: the game gets the world built of it.

## Beside the world's sources
const FILE: String = "description.tres"
## The .json's format the game reads (libmaszyna's ReloadedProWorld.FORMAT)
const FORMAT: int = 5

@export var title: String = ""
@export_multiline var description: String = ""
@export_group("Frame")
## The projection the world's coordinates are in: its name and EPSG code
@export var projection: String = ""
@export var epsg: int = 0
## The projected metres (east, north) of the world's origin
@export var origin: Vector2 = Vector2.ZERO
@export_group("")
## The world's middle: latitude, longitude
@export var center: Vector2 = Vector2.ZERO
## Where a player starts, in the world's coordinates
@export var player_start: Vector3 = Vector3.ZERO
@export_group("Drawn with")
## The world assets' packs it mounts, in the order they are mounted
@export var assets: PackedStringArray = ["common_terrain", "common_facades", "common_biomes"]
## The scene of the biomes it grows (its node Vegetation)
@export var biomes: String = "res://world_assets/common_biomes/biomes.tscn"
## The terrain's atlas (Terrain3DAssets)
@export var terrain_assets: String = "res://world_assets/common_terrain/assets.res"
## Side of a Terrain3D region: a sector's [m]
@export var region_size: int = 1024
@export_group("Era")
## What the world is built with, the era's (the scenery importer's EraPreset, builder-presets): a preset
## of the world assets' common_eras (res://world_assets/common_eras/<era>.tres); "" the contemporary one
@export var era_preset: String = ""
## The year the world stands in: what was not built by then, or was taken down, is left out of it (the
## description's start and end years, OSM's start_date and end_date); 0: today, nothing left out
@export var era_year: int = 0
@export_group("Export")
## The sectors exported as far terrain only (WorldPacker): no block's pack holds them, the world's far
## terrain stands for them - a range of mountains seen, not walked (the scenery importer's Project >
## Tools > "Scenery sectors LOD...")
@export var far_sectors: PackedStringArray = []


## The game's description of the world [param world_name] (ReloadedProWorld.read_description()): this
## one's fields with where its pack [param pck] and its scene [param scene] are (WorldPacker's)
func game_description(world_name: String, pck: String, scene: String) -> Dictionary:
    return {
        "format": FORMAT,
        "name": world_name,
        "title": title,
        "description": description,
        "frame": {"projection": projection, "epsg": epsg, "origin": [origin.x, origin.y]},
        "center": [center.x, center.y],
        "player_start": [player_start.x, player_start.y, player_start.z],
        "pck": pck,
        "scene": scene,
        "assets": assets,
        "biomes": biomes,
        "terrain": {"assets": terrain_assets, "region_size": region_size},
    }
