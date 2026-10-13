extends SceneTree
## Überträgt die KayKit-Animationen (assets/source/kaykit/Knight.glb, CC0) auf alle Figurenmodelle,
## deren CharacterVisual "bake_from_kaykit" gesetzt hat, und speichert sie unter assets/characters/anims.
## Aufruf: godot --headless --path godot --script res://tools/bake_animations.gd

const SOURCE := "res://assets/source/kaykit/Knight.glb"
const VISUAL_DIR := "res://data/visuals/characters"
const OUT_DIR := "res://assets/characters/anims"
## Spielzustand -> [KayKit-Animation, Schleife]
const ANIMS := {
	"idle": ["Idle", true], "aim2": ["2H_Ranged_Aiming", true], "aim1": ["1H_Ranged_Aiming", true],
	"walk": ["Walking_A", true], "run": ["Running_A", true],
	"shoot2": ["2H_Ranged_Shoot", false], "shoot1": ["1H_Ranged_Shoot", false],
	"melee": ["1H_Melee_Attack_Slice_Diagonal", false], "punch": ["Unarmed_Melee_Attack_Punch_A", false],
	"spell": ["Spellcast_Shoot", false], "hit": ["Hit_A", false], "death": ["Death_A", false],
	"ko": ["Death_B", false], "standup": ["Lie_StandUp", false], "aid": ["Use_Item", false],
	"reload": ["2H_Ranged_Reload", false], "cheer": ["Cheer", false],
}


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var src: Node3D = (load(SOURCE) as PackedScene).instantiate()
	root.add_child(src)
	var sp: AnimationPlayer = src.find_children("*", "AnimationPlayer", true, false)[0]
	var ss: Skeleton3D = src.find_children("*", "Skeleton3D", true, false)[0]
	var crouch_t := Retarget.lowest_hips_time(sp, ss, "PickUp")
	for f in DirAccess.get_files_at(VISUAL_DIR):
		if not f.ends_with(".tres"):
			continue
		var path := VISUAL_DIR.path_join(f)
		var vis: CharacterVisual = load(path)
		if not vis.bake_from_kaykit or vis.model == null:
			continue
		var dst: Node3D = vis.model.instantiate()
		root.add_child(dst)
		var ds: Skeleton3D = dst.find_children("*", "Skeleton3D", true, false)[0]
		var skel_path := String(dst.get_path_to(ds))
		var lib := AnimationLibrary.new()
		for state in ANIMS:
			lib.add_animation(state, Retarget.bake(sp, ss, ANIMS[state][0], ds, skel_path, ANIMS[state][1]))
		# Hocke (hinter Deckung): tiefste Haltung aus "PickUp"
		lib.add_animation("crouch", Retarget.bake(sp, ss, "PickUp", ds, skel_path, true, crouch_t))
		var out := OUT_DIR.path_join(f.get_basename() + ".res")
		ResourceSaver.save(lib, out)
		vis.animations = load(out)
		ResourceSaver.save(vis, path)
		print("gebacken: ", f, " (", lib.get_animation_list().size(), " Animationen)")
		dst.free()
	quit()
