class_name RunnerSave
extends RefCounted

const PATH := "user://records.cfg"

var best := 0
var furthest := 0
var bank := 0


func read_records() -> void:
	var file := ConfigFile.new()
	if file.load(PATH) != OK:
		return
	best = maxi(0, int(file.get_value("records", "best", 0)))
	furthest = maxi(0, int(file.get_value("records", "furthest", 0)))
	bank = maxi(0, int(file.get_value("records", "bank", 0)))


func record(distance: float, session_score: int, new_coins: int) -> bool:
	var was_record := session_score > best
	best = maxi(best, session_score)
	furthest = maxi(furthest, int(distance))
	bank += new_coins
	var file := ConfigFile.new()
	file.set_value("records", "best", best)
	file.set_value("records", "furthest", furthest)
	file.set_value("records", "bank", bank)
	if file.save(PATH) != OK:
		push_warning("Could not save local Murang Run records.")
	return was_record
