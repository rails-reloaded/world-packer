@tool
extends RefCounted
class_name WorldAssetsPacker
## Packs what the worlds share - every directory of RESOURCES_DIR, a pack each (common_terrain,
## common_facades, common_biomes) - into ASSETS_DIR/<pack>.pck of a directory: the game's, which
## mounts them with a world (libmaszyna's ReloadedProWorld.mount()) and whose packs the scenery importer
## reads in the editor, or a release's (the world assets' `make packs` and CI). It needs nothing of
## libmaszyna, so the packs build without it; its paths are ReloadedProWorld's (ASSETS_DIR,
## ASSETS_RESOURCES_DIR, PACK_EXTENSION). A pack holds a directory's files under their
## own paths, an imported one (.import beside it) as Godot's export does: its .import and what the
## import made (.godot/imported/), not its source; a shader with its UID beside it (UID_EXTENSION);
## what is no resource (a licence, a glTF's buffer) is left out. A scene's nodes of PREVIEW_GROUP are
## this project's - what a pack's content is tuned on here (common_biomes/biomes.tscn's piece of
## terrain) - and are left out of the pack's copy of it, with what referred to them.

## Under the directory the packs go into, and where their files are in them
const ASSETS_DIR: String = "world_assets"
const RESOURCES_DIR: String = "res://world_assets"
## Its pack writing (a class_name is unknown to a headless run that scanned no project)
const Packer: GDScript = preload("world_packer.gd")
const IMPORT_EXTENSION: String = "import"
const UID_EXTENSION: String = "uid"
const PREVIEW_GROUP: StringName = &"world_assets_preview"
## Where a scene is written without its preview nodes, to be packed
const EXPORT_DIR: String = "user://cache/world_packer"


## Every pack exported into [param dir]/ASSETS_DIR; false when one failed
static func export_all(dir: String) -> bool:
    var exported: bool = true
    for pack: String in DirAccess.get_directories_at(RESOURCES_DIR):
        exported = export_pack(pack, dir) and exported
    return exported


## The pack [param pack] exported into [param dir]/ASSETS_DIR; false on failure
static func export_pack(pack: String, dir: String) -> bool:
    var files: PackedStringArray = []
    _collect(RESOURCES_DIR.path_join(pack), files)
    var path: String = dir.path_join(ASSETS_DIR).path_join(pack + "." + Packer.PACK_EXTENSION)
    var sources: Dictionary[String, String] = {}
    for file: String in files:
        sources[file] = _without_preview(file)
    if not Packer.write_pack(path, sources):
        return false
    print("World assets: %s, %d files" % [path, files.size()])
    return true


## The file to pack as [param path]: a scene with nodes of PREVIEW_GROUP written without them (and
## with what referred to them null), else the file itself
static func _without_preview(path: String) -> String:
    if not path.get_extension() == "tscn":
        return ProjectSettings.globalize_path(path)
    var root: Node = (load(path) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
    var previews: Array[Node] = []
    for node: Node in root.find_children("*", "", true, false):
        if node.is_in_group(PREVIEW_GROUP):
            previews.append(node)
    if not previews:
        root.free()
        return ProjectSettings.globalize_path(path)
    for node: Node in [root] + root.find_children("*", "", true, false):
        for property: Dictionary in node.get_property_list():
            var value: Variant = node.get(property["name"]) if property["type"] == TYPE_OBJECT else null
            if value is Node and value in previews:
                node.set(property["name"], null)
    for node: Node in previews:
        node.get_parent().remove_child(node)
        node.free()
    var scene: PackedScene = PackedScene.new()
    scene.pack(root)
    root.free()
    var target: String = ProjectSettings.globalize_path(EXPORT_DIR.path_join(path.trim_prefix("res://")))
    DirAccess.make_dir_recursive_absolute(target.get_base_dir())
    ResourceSaver.save(scene, target)
    return target


## The files of the directory [param dir] that go into its pack, into [param files]
static func _collect(dir: String, files: PackedStringArray) -> void:
    for sub: String in DirAccess.get_directories_at(dir):
        _collect(dir.path_join(sub), files)
    for file: String in DirAccess.get_files_at(dir):
        var path: String = dir.path_join(file)
        if not file.get_extension() == IMPORT_EXTENSION:
            if ResourceLoader.exists(path) and not FileAccess.file_exists(path + "." + IMPORT_EXTENSION):
                files.append(path)
                if FileAccess.file_exists(path + "." + UID_EXTENSION):
                    files.append(path + "." + UID_EXTENSION)
            continue
        files.append(path)
        var import_file: ConfigFile = ConfigFile.new()
        import_file.load(path)
        for key: String in import_file.get_section_keys("remap") if import_file.has_section("remap") else PackedStringArray():
            if key.begins_with("path"):
                files.append(import_file.get_value("remap", key))
