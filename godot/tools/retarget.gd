class_name Retarget
extends RefCounted
## Überträgt Animationen von einem Skelett auf ein anderes (beide menschenähnlich), indem für jeden Zeitpunkt
## die Drehung jedes Knochens gegenüber seiner Ruhelage im Modellraum übernommen wird.
## Wird von tools/bake_animations.gd benutzt; im Spiel werden nur die fertigen Animationen geladen.

## Quell-Knochen (KayKit) -> Ziel-Knochen (Quaternius)
const BONE_MAP := {
	"hips": "Hips", "spine": "Abdomen", "chest": "Chest", "head": "Head",
	"upperarm.l": "UpperArm.L", "lowerarm.l": "LowerArm.L", "hand.l": "Hand.L",
	"upperarm.r": "UpperArm.R", "lowerarm.r": "LowerArm.R", "hand.r": "Hand.R",
	"upperleg.l": "UpperLeg.L", "lowerleg.l": "LowerLeg.L", "foot.l": "Foot.L",
	"upperleg.r": "UpperLeg.R", "lowerleg.r": "LowerLeg.R", "foot.r": "Foot.R",
}
const FPS := 24.0


## src_root: Szene mit Skeleton3D und AnimationPlayer (im Baum), dst_skel: Zielskelett,
## dst_path: Pfad zum Zielskelett relativ zum späteren AnimationPlayer-Wurzelknoten
## pose_at >= 0: nur eine Haltung zu diesem Zeitpunkt (Animation mit einem Bild)
static func bake(src_player: AnimationPlayer, src_skel: Skeleton3D, anim_name: String, dst_skel: Skeleton3D, dst_path: String, loop: bool, pose_at := -1.0) -> Animation:
	var src_anim := src_player.get_animation(anim_name)
	var out := Animation.new()
	out.length = src_anim.length if pose_at < 0 else 0.1
	out.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	var n := dst_skel.get_bone_count()
	# Zuordnung Ziel -> Quelle
	var src_of := {}
	for s in BONE_MAP:
		var si := src_skel.find_bone(s)
		var ti := dst_skel.find_bone(BONE_MAP[s])
		if si >= 0 and ti >= 0:
			src_of[ti] = si
	var tracks := {}
	for ti in src_of:
		var tr := out.add_track(Animation.TYPE_ROTATION_3D)
		out.track_set_path(tr, "%s:%s" % [dst_path, dst_skel.get_bone_name(ti)])
		tracks[ti] = tr
	var hips := dst_skel.find_bone("Hips")
	var pos_track := out.add_track(Animation.TYPE_POSITION_3D)
	out.track_set_path(pos_track, "%s:Hips" % dst_path)
	var src_hips := src_skel.find_bone("hips")
	var sx := src_skel.global_transform
	var dx := dst_skel.global_transform
	var scale := (dx * dst_skel.get_bone_global_rest(hips)).origin.y / maxf((sx * src_skel.get_bone_global_rest(src_hips)).origin.y, 0.001)
	var hips_parent := dst_skel.get_bone_parent(hips)
	var hips_parent_rest: Basis = dst_skel.get_bone_global_rest(hips_parent).basis if hips_parent >= 0 else Basis()
	# Skelette können in ihren Szenen unterschiedlich gedreht sein: alles im Weltraum vergleichen
	var sb := src_skel.global_transform.basis.orthonormalized()
	var db := dst_skel.global_transform.basis.orthonormalized()
	var frames := maxi(1, int(ceil(src_anim.length * FPS))) if pose_at < 0 else 0
	for f in frames + 1:
		var t := minf(f / FPS, src_anim.length) if pose_at < 0 else pose_at
		var key_t := t if pose_at < 0 else 0.0
		src_player.play(anim_name)
		src_player.seek(t, true)
		src_player.pause()
		var glob := {}  # Ziel-Knochen -> globale Basis
		for ti in n:
			var parent := dst_skel.get_bone_parent(ti)
			var parent_g: Basis = glob[parent] if parent >= 0 else Basis()
			var g: Basis
			if src_of.has(ti):
				var si: int = src_of[ti]
				var delta := src_skel.get_bone_global_pose(si).basis.orthonormalized() * src_skel.get_bone_global_rest(si).basis.orthonormalized().inverse()
				var delta_w := sb * delta * sb.inverse()
				var delta_d := db.inverse() * delta_w * db
				g = delta_d * dst_skel.get_bone_global_rest(ti).basis.orthonormalized()
				var local := (parent_g.inverse() * g).get_rotation_quaternion()
				out.rotation_track_insert_key(tracks[ti], key_t, local)
			else:
				g = parent_g * dst_skel.get_bone_rest(ti).basis.orthonormalized()
			glob[ti] = g
		# Hüfte: Verschiebung gegenüber der Ruhelage, auf die Größe des Ziels skaliert
		var d := src_skel.get_bone_global_pose(src_hips).origin - src_skel.get_bone_global_rest(src_hips).origin
		var d_dst := dx.basis.inverse() * (sx.basis * d * scale)
		var hp := dst_skel.get_bone_rest(hips).origin + hips_parent_rest.inverse() * d_dst
		out.position_track_insert_key(pos_track, key_t, hp)
	return out


## Zeitpunkt, an dem die Hüfte am tiefsten ist (z. B. Hocke beim Aufheben)
static func lowest_hips_time(src_player: AnimationPlayer, src_skel: Skeleton3D, anim_name: String) -> float:
	var hips := src_skel.find_bone("hips")
	var length := src_player.get_animation(anim_name).length
	var best_t := 0.0
	var best_y := INF
	for f in int(length * FPS) + 1:
		var t := f / FPS
		src_player.play(anim_name)
		src_player.seek(t, true)
		src_player.pause()
		var y := src_skel.get_bone_global_pose(hips).origin.y
		if y < best_y:
			best_y = y
			best_t = t
	return best_t
