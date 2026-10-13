class_name Prefs
extends RefCounted
## Einstellungen (Ton, Würfel, Raster), gespeichert in user://settings.cfg.

const PATH := "user://settings.cfg"
static var _cfg: ConfigFile


static func _file() -> ConfigFile:
	if _cfg == null:
		_cfg = ConfigFile.new()
		_cfg.load(PATH)
	return _cfg


static func get_bool(key: String, default := true) -> bool:
	return _file().get_value("prefs", key, default)


static func set_bool(key: String, value: bool) -> void:
	_file().set_value("prefs", key, value)
	_file().save(PATH)
