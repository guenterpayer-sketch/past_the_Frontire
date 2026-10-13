class_name CritRowData
extends Resource
## Eine Zeile einer Tabelle für Kritische Treffer.

@export_multiline var text := ""
@export var dmg := 0
@export var bleed := 0
@export var stun := 0
@export var malus := 0
@export var prone := false
@export var ko := false
@export var kill := false


func effects() -> PackedStringArray:
	var fx := PackedStringArray()
	if kill:
		fx.append("tödlich")
	if dmg:
		fx.append("+%d TP" % dmg)
	if bleed:
		fx.append("blutet %d" % bleed)
	if stun:
		fx.append("betäubt %d" % stun)
	if malus:
		fx.append("%d auf alles" % malus)
	if prone:
		fx.append("niedergeworfen")
	if ko:
		fx.append("bewusstlos")
	return fx
