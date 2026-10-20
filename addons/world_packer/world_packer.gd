@tool
extends RefCounted
class_name WorldPacker
## Packs a world of the game's own format from its sources into the packs the game mounts, in a
## worlds directory given (the game's WORLDS_DIR): its files of no sector (WORLD_FILES) whole into
## <name>/WORLD_PACK, and what is drawn of its sectors into a pack a block (<name>/<block>.pck),
## sector by sector in the order of their
## ids, a sector's files one after another (SECTOR_FILES) - so a sector may be read out of the pack
## alone - but the sectors exported as far terrain only (WorldDescription.far_sectors), which no
## block's pack holds. The far terrain (FAR_TERRAIN_DIR, a mesh a block) goes whole into
## <name>/FAR_TERRAIN_PACK. Every file is under RESOURCES_DIR/<name>/ in the packs, at its place in the sources. Its
## description for the game, <name>.json, is made of its WorldDescription (WorldDescription.FILE
## beside its sources) as it is packed (pack()). Needs
## nothing of libmaszyna, so a world's packs build without it (a world's `make packs`, its CI); the
## names are libmaszyna's ReloadedProWorld's (WORLDS_DIR, RESOURCES_DIR, WORLD_PACK, BLOCKS_DIR,
## SECTORS_DIR, PACK_EXTENSION, SECTOR_FILE_SUFFIXES, SCENERY_FILE, SCENARIO_FILE, FAR_TERRAIN_DIR,
## FAR_TERRAIN_PACK).

## The game's directory of worlds (the packs go into one - its <name>.json describing a world, its
## packs in <name>/ - as a world's sources are kept in one, its <name>/)
const WORLDS_DIR: String = "worlds"
const RESOURCES_DIR: String = "res://worlds"
const WORLD_PACK: String = "world.pck"
const PACK_EXTENSION: String = "pck"
const DESCRIPTION_EXTENSION: String = "json"
const BLOCKS_DIR: String = "blocks"
const SECTORS_DIR: String = "sectors"
## The world's scene, scenery and scenario, beside each other
const WORLD_FILES: PackedStringArray = ["world.scn", "scenery.res", "scenario.res"]
## What is drawn of a sector, its terrain and its roads, the suffixes of its id
const SECTOR_FILES: PackedStringArray = [".drawn.scn", ".terrain.res", ".roads.res"]
## The world's low-poly preview (the scenery importer's SIWorldPreview) beside its scene, packed alone
## into worlds/<name>/PREVIEW_PACK: a screen choosing a world mounts only it
const PREVIEW_FILE: String = "preview.res"
const PREVIEW_PACK: String = "preview.pck"
## The world's far terrain beside its scene, a mesh a block (the scenery importer's SIFarTerrain),
## packed whole into worlds/<name>/FAR_TERRAIN_PACK: the game mounts it with the world
const FAR_TERRAIN_DIR: String = "far"
const FAR_TERRAIN_PACK: String = "far.pck"
## The world's description (a class_name is unknown to a headless run that scanned no project)
const Description: GDScript = preload("world_description.gd")


## Writes the pack [param pck_path] of [param files] (path in the pack -> source file); false on failure
static func write_pack(pck_path: String, files: Dictionary[String, String]) -> bool:
    DirAccess.make_dir_recursive_absolute(pck_path.get_base_dir())
    var packer: PCKPacker = PCKPacker.new()
    if not packer.pck_start(pck_path) == OK:
        push_error("World packer: cannot write %s" % pck_path)
        return false
    for file: String in files:
        packer.add_file(file, files[file])
    if not packer.flush() == OK:
        push_error("World packer: cannot write %s" % pck_path)
        return false
    return true


## The world [param world_name] whose sources are in [param dir] packed whole - WORLD_PACK, its far
## terrain and every block's pack but its sectors exported as far terrain only - into
## [param worlds_dir]/<name>/, with its description <name>.json beside them; false on failure
static func pack(dir: String, world_name: String, worlds_dir: String) -> bool:
    var world: Description = ResourceLoader.load(dir.path_join(Description.FILE), "",
            ResourceLoader.CACHE_MODE_IGNORE) as Description
    if not world:
        push_error("World packer: no %s in %s" % [Description.FILE, dir])
        return false
    if not pack_world(dir, world_name, worlds_dir):
        return false
    if FileAccess.file_exists(dir.path_join(PREVIEW_FILE)) and not pack_preview(dir, world_name, worlds_dir):
        return false
    if DirAccess.dir_exists_absolute(dir.path_join(FAR_TERRAIN_DIR)) and not pack_far_terrain(dir, world_name, worlds_dir):
        return false
    for block: String in blocks(dir):
        if not pack_block(dir, world_name, block, worlds_dir, world.far_sectors):
            return false
    return write_description(world, world_name, worlds_dir)


## The world's description for the game, [param worlds_dir]/<name>.json, made of its
## WorldDescription [param world] (its FILE beside its sources); false on failure
static func write_description(world: Description, world_name: String, worlds_dir: String) -> bool:
    var path: String = worlds_dir.path_join(world_name + "." + DESCRIPTION_EXTENSION)
    DirAccess.make_dir_recursive_absolute(path.get_base_dir())
    var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
    if not file:
        push_error("World packer: cannot write %s" % path)
        return false
    file.store_string(JSON.stringify(world.game_description(world_name, world_name.path_join(WORLD_PACK),
            RESOURCES_DIR.path_join(world_name).path_join(WORLD_FILES[0])), "\t"))
    return true


## The world's files of no sector (WORLD_FILES) packed into [param worlds_dir]/<name>/WORLD_PACK;
## returns the pack's path, "" on failure
static func pack_world(dir: String, world_name: String, worlds_dir: String) -> String:
    var files: Dictionary[String, String] = {}
    for file: String in WORLD_FILES:
        if FileAccess.file_exists(dir.path_join(file)):
            files[RESOURCES_DIR.path_join(world_name).path_join(file)] = dir.path_join(file)
    var pck_path: String = worlds_dir.path_join(world_name).path_join(WORLD_PACK)
    return pck_path if write_pack(pck_path, files) else ""


## The world's preview (PREVIEW_FILE in [param dir]) packed into [param worlds_dir]/<name>/
## PREVIEW_PACK; returns the pack's path, "" on failure or with no preview
static func pack_preview(dir: String, world_name: String, worlds_dir: String) -> String:
    var source: String = dir.path_join(PREVIEW_FILE)
    if not FileAccess.file_exists(source):
        return ""
    var files: Dictionary[String, String] = {RESOURCES_DIR.path_join(world_name).path_join(PREVIEW_FILE): source}
    var pck_path: String = worlds_dir.path_join(world_name).path_join(PREVIEW_PACK)
    return pck_path if write_pack(pck_path, files) else ""


## The world's far terrain (FAR_TERRAIN_DIR in [param dir]) packed into [param worlds_dir]/<name>/
## FAR_TERRAIN_PACK; returns the pack's path, "" on failure
static func pack_far_terrain(dir: String, world_name: String, worlds_dir: String) -> String:
    var files: Dictionary[String, String] = {}
    for file: String in DirAccess.get_files_at(dir.path_join(FAR_TERRAIN_DIR)):
        files[RESOURCES_DIR.path_join(world_name).path_join(FAR_TERRAIN_DIR).path_join(file)] = \
                dir.path_join(FAR_TERRAIN_DIR).path_join(file)
    var pck_path: String = worlds_dir.path_join(world_name).path_join(FAR_TERRAIN_PACK)
    return pck_path if write_pack(pck_path, files) else ""


## What is drawn of the sectors of the block [param block] packed into
## [param worlds_dir]/<name>/<block>.pck, but [param far_sectors] (exported as far terrain only); a
## block of them alone has no pack, an earlier one removed; false on failure
static func pack_block(dir: String, world_name: String, block: String, worlds_dir: String,
        far_sectors: PackedStringArray) -> bool:
    var sectors: String = BLOCKS_DIR.path_join(block).path_join(SECTORS_DIR)
    var ids: PackedStringArray = []
    for file: String in DirAccess.get_files_at(dir.path_join(sectors)):
        if file.ends_with(SECTOR_FILES[0]) and not file.trim_suffix(SECTOR_FILES[0]) in far_sectors:
            ids.append(file.trim_suffix(SECTOR_FILES[0]))
    ids.sort()
    var pck_path: String = worlds_dir.path_join(world_name).path_join(block + "." + PACK_EXTENSION)
    if not ids:
        DirAccess.remove_absolute(pck_path)
        return true
    var files: Dictionary[String, String] = {}
    for id: String in ids:
        for suffix: String in SECTOR_FILES:
            var file: String = sectors.path_join(id + suffix)
            if FileAccess.file_exists(dir.path_join(file)):
                files[RESOURCES_DIR.path_join(world_name).path_join(file)] = dir.path_join(file)
    return write_pack(pck_path, files)


## The blocks of the world whose sources are in [param dir]
static func blocks(dir: String) -> PackedStringArray:
    var blocks_dir: String = dir.path_join(BLOCKS_DIR)
    return DirAccess.get_directories_at(blocks_dir) if DirAccess.dir_exists_absolute(blocks_dir) else PackedStringArray()
