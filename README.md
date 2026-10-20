# world-packer

Packs the game's worlds and what they share into the packs the game mounts - Godot addon
`addons/world_packer`, plain GDScript with nothing of the game's libraries, so the packs build in CI
without them:

- `WorldPacker` (`world_packer.gd`): a world's sources (`world.res`, `scenery.res`, `scenario.res`,
  `sections/`, a big world's `blocks/<block>/sectors/<id>.drawn.res|.terrain.res|.roads.res`) into a
  worlds directory given (the game's `worlds/`): `<name>/world.pck`, a pack a block and
  `<name>.json` (`"world"`, and `"sectors"` for a world of them), every file under
  `res://worlds/<name>/`; `far/<block>.res` (the far terrain) into `<name>/far.pck`, and the
  sectors of the description's `far_sectors` left out of the blocks' packs (exported as far terrain
  only). Used by the scenery importer and by a world's repository (`export_world.gd`).
- `WorldAssetsPacker` (`world_assets_packer.gd`): every `res://world_assets/<pack>/` of a project into
  `world_assets/<pack>.pck`, imported files as Godot's export takes them, nodes of the group
  `world_assets_preview` left out. Used by the world assets' repository (`export_assets.gd`).

A repository using it has it as a submodule (`vendor/world-packer`) with `addons/world_packer`
linked to `vendor/world-packer/addons/world_packer`.
