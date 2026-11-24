class_name RunnerUI
extends Control

signal start_requested
signal pause_requested
signal resume_requested
signal home_requested
signal mute_requested

enum Screen { TITLE, HUD, PAUSED, HELP, OVER }

const INK := Color("#143b36")
const SUBTLE := Color("#42635b")
const MINT := Color("#bcead8")
const TEAL := Color("#116856")
const PAPER := Color("#fffdf5")
const PALE := Color("#eaf6e9")
const CORAL := Color("#e85c6d")
const GOLD := Color("#cf9120")
const KOREAN := preload("res://assets/ui/GowunDodum.ttf")
const DISPLAY := preload("res://assets/ui/Outfit-Medium.ttf")
const BOLD := preload("res://assets/ui/Outfit-Bold.ttf")
const HERO := preload("res://assets/ui/murang.webp")
const VEIL := preload("res://scripts/menu_veil.gdshader")

var screen := Screen.TITLE
var panels: Control
var overlay: ColorRect
var score_label: Label
var meters_label: Label
var coins_label: Label
var hearts_label: Label
var best := 0
var bank := 0
var score := 0
var meters := 0
var coins := 0
var hearts := 3
var pace := 0.0
var pulse := 0.0
var run_clock := 0.0
var new_best := false
var muted := false
var touch := false
var units := Vector2(1280, 720)
var portrait := false
var effects: Control


class SpeedStreaks extends Control:
	var strength := 0.0
	var flash := 0.0
	var clock := 0.0

	func _draw() -> void:
		if flash > 0.0:
			var tint := Color(0.96, 0.21, 0.29, flash * 0.24)
			draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, size.y * 0.035)), tint)
			draw_rect(Rect2(Vector2(0, size.y * 0.965), Vector2(size.x, size.y * 0.035)), tint)
		if strength <= 0.0:
			return
		var center := size * Vector2(0.5, 0.42)
		for i in range(20):
			var direction := -1.0 if i % 2 == 0 else 1.0
			var flow := fposmod(clock * (1.3 + i * 0.017) + i * 0.376, 1.0)
			var y := 0.13 + fposmod(i * 0.178, 0.79)
			var road_edge := Vector2(size.x * (0.5 + direction * (0.34 + flow * 0.17)), y * size.y)
			var stretch := (road_edge - center).normalized() * (22 + flow * 56)
			draw_line(road_edge - stretch, road_edge, Color(0.94, 1.0, 0.99, strength * sin(flow * PI) * 0.37), 1.6, true)


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	effects = SpeedStreaks.new()
	effects.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(effects)
	effects.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	overlay = ColorRect.new()
	overlay.mouse_filter = MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = VEIL
	overlay.material = material
	add_child(overlay)
	overlay.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	panels = Control.new()
	panels.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(panels)
	resized.connect(_layout)
	_layout.call_deferred()


func _process(dt: float) -> void:
	pulse = move_toward(pulse, 0.0, dt * 2.6)
	run_clock += dt
	var streaks := effects as SpeedStreaks
	streaks.strength = pace if screen == Screen.HUD else 0.0
	streaks.flash = pulse if screen == Screen.HUD else 0.0
	streaks.clock = run_clock
	streaks.queue_redraw()


func show_screen(target: Screen) -> void:
	screen = target
	_layout()


func update_values(current_score: int, distance: int, current_coins: int, health: int) -> void:
	score = current_score
	meters = distance
	coins = current_coins
	hearts = health
	if screen == Screen.HUD and is_instance_valid(score_label):
		score_label.text = format_number(score)
		meters_label.text = "%s m" % format_number(meters)
		coins_label.text = format_number(coins)
		hearts_label.text = "♥".repeat(hearts) + "♡".repeat(3 - hearts)


static func format_number(value: int) -> String:
	var digits := str(value)
	var output := ""
	for i in digits.length():
		if i > 0 and (digits.length() - i) % 3 == 0:
			output += ","
		output += digits[i]
	return output


func _layout() -> void:
	if not is_instance_valid(panels) or size.x < 1 or size.y < 1:
		return
	for child in panels.get_children():
		panels.remove_child(child)
		child.queue_free()
	portrait = size.x < size.y * 0.98
	var fitting := minf(size.x / 670.0, size.y / 960.0) if portrait else minf(size.x / 1060.0, size.y / 710.0)
	panels.scale = Vector2.ONE * fitting
	units = size / fitting
	panels.size = units
	overlay.visible = screen != Screen.HUD
	var shader_material := overlay.material as ShaderMaterial
	shader_material.set_shader_parameter("title", screen == Screen.TITLE)
	shader_material.set_shader_parameter("portrait", portrait)
	match screen:
		Screen.TITLE: _title()
		Screen.HUD: _hud()
		Screen.HELP: _help()
		Screen.PAUSED: _paused()
		Screen.OVER: _over()


func _box(color: Color, radius: int, border := Color.TRANSPARENT, width := 0, shadow := 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_border_width_all(width)
	style.border_color = border
	style.shadow_color = Color(0.03, 0.18, 0.16, 0.16)
	style.shadow_size = shadow
	style.shadow_offset = Vector2(0, 4)
	return style


func _panel(rect: Rect2, fill: Color, radius := 22, edge := Color.TRANSPARENT, width := 0, shadow := 0) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _box(fill, radius, edge, width, shadow))
	panels.add_child(panel)
	return panel


func _text(value: String, rect: Rect2, font_size: int, tint := INK, font: Font = KOREAN, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = value
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	panels.add_child(label)
	return label


func _button(value: String, rect: Rect2, callback: Callable, primary := false, font_size := 25, font: Font = KOREAN) -> Button:
	var button := Button.new()
	button.text = value
	button.position = rect.position
	button.size = rect.size
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", font_size)
	var fg := PAPER if primary else INK
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(color_name, fg)
	var color := TEAL if primary else PAPER
	var edge := Color("#105342") if primary else Color("#bcd9cc")
	button.add_theme_stylebox_override("normal", _box(color, 19, edge, 2, 5 if primary else 0))
	button.add_theme_stylebox_override("hover", _box(Color("#187a65") if primary else PALE, 19, edge, 2, 4))
	button.add_theme_stylebox_override("pressed", _box(Color("#095447") if primary else MINT, 19, edge, 2))
	var focus := _box(Color.TRANSPARENT, 19, Color("#f3bd53"), 3)
	button.add_theme_stylebox_override("focus", focus)
	button.pressed.connect(callback)
	panels.add_child(button)
	return button


func _hero(rect: Rect2) -> void:
	var art := TextureRect.new()
	art.texture = HERO
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.position = rect.position
	art.size = rect.size
	art.mouse_filter = MOUSE_FILTER_IGNORE
	panels.add_child(art)


func _title() -> void:
	var inset := maxf(43.0, (units.x - 1080.0) * 0.52)
	var copy_x := inset if not portrait else (units.x - 474.0) * 0.5
	var y := maxf(75.0, (units.y - 560.0) * 0.5)
	if portrait:
		y = 44.0 + maxf(0.0, units.y - 980.0) * 0.39
		_hero(Rect2((units.x - 458) * 0.5, y + 215, 458, 448))
	else:
		var art_size := minf(590.0, units.x * 0.50)
		var art_x := minf(units.x - art_size - 35.0, copy_x + 494.0)
		var center := Vector2(art_x + art_size * 0.53, units.y * 0.51)
		var halo := art_size * 0.81
		_panel(Rect2(center - Vector2.ONE * halo * 0.5, Vector2.ONE * halo), Color(0.90, 0.99, 0.87, 0.37), int(halo), Color(1, 1, 0.94, 0.67), 2)
		_hero(Rect2(art_x, center.y - art_size * 0.5, art_size, art_size))
	_panel(Rect2(copy_x, y, 160, 34), MINT, 17)
	_text("시티 파크", Rect2(copy_x, y + 1, 160, 31), 19, INK, KOREAN, HORIZONTAL_ALIGNMENT_CENTER)
	var title_label := _text("무랑 런", Rect2(copy_x - 4, y + 41, 460, 105), 96 if not portrait else 87)
	title_label.add_theme_constant_override("outline_size", 5)
	title_label.add_theme_color_override("font_outline_color", INK)
	_text("MURANG RUN", Rect2(copy_x + 1, y + 156, 440, 40), 38, TEAL, BOLD)
	_text("도시와 공원을 누비는 3D 무한 달리기", Rect2(copy_x + 2, y + 200, 465, 35), 23, SUBTLE)
	var cards_y := y + 256 if not portrait else y + 664.0
	_summary_card("최고 기록", format_number(best), Rect2(copy_x, cards_y, 222, 75), TEAL)
	_summary_card("누적 코인", format_number(bank), Rect2(copy_x + 238, cards_y, 222, 75), GOLD)
	var buttons_y := cards_y + 94
	_button("게임 시작  ›", Rect2(copy_x, buttons_y, 280, 66), func(): start_requested.emit(), true, 30)
	_button("조작 방법", Rect2(copy_x + 294, buttons_y, 166, 66), func(): show_screen(Screen.HELP), false, 23)
	if not portrait:
		_text("이동  A / D      점프  SPACE      슬라이드  S", Rect2(copy_x + 1, buttons_y + 84, 460, 32), 17, SUBTLE)
	_text("v0.1", Rect2(copy_x + 2, units.y - 46, 84, 30), 18, SUBTLE, DISPLAY)
	_button("소리 끔" if muted else "소리 켬", Rect2(units.x - 134, units.y - 58, 106, 38), func(): mute_requested.emit(), false, 16)


func _summary_card(caption: String, value: String, rect: Rect2, accent: Color) -> Label:
	_panel(rect, PAPER, 19, Color("#d8e5d7"), 2, 3)
	_panel(Rect2(rect.position + Vector2(15, 15), Vector2(5, rect.size.y - 30)), accent, 3)
	_text(caption, Rect2(rect.position + Vector2(30, 9), Vector2(rect.size.x - 38, 24)), 18, SUBTLE)
	return _text(value, Rect2(rect.position + Vector2(29, 30), Vector2(rect.size.x - 38, 39)), 32, INK, BOLD)


func _hud() -> void:
	var w := units.x
	var y := 22.0
	var gap := 10.0
	var cards_width := minf(452.0, w - 225.0)
	var card_width := (cards_width - gap * 2.0) / 3.0
	score_label = _summary_card("점수", format_number(score), Rect2(22, y, card_width, 69), TEAL)
	meters_label = _summary_card("거리", "%s m" % format_number(meters), Rect2(22 + card_width + gap, y, card_width, 69), TEAL)
	coins_label = _summary_card("코인", format_number(coins), Rect2(22 + (card_width + gap) * 2.0, y, card_width, 69), GOLD)
	_panel(Rect2(w - 198.0, y + 3, 112, 59), PAPER, 18, Color("#f2dfd8"), 2, 3)
	hearts_label = _text("♥".repeat(hearts) + "♡".repeat(3 - hearts), Rect2(w - 197, y + 3, 111, 58), 26, CORAL, KOREAN, HORIZONTAL_ALIGNMENT_CENTER)
	_button("Ⅱ", Rect2(w - 76, y + 3, 54, 59), func(): pause_requested.emit(), false, 25)
	if score == 0:
		var guide := "상하좌우로 스와이프" if touch else "A / D 이동    SPACE 점프    S 슬라이드"
		var tip := _text(guide, Rect2(w * 0.5 - 230, units.y - 105, 460, 39), 23, PAPER, KOREAN, HORIZONTAL_ALIGNMENT_CENTER)
		tip.add_theme_color_override("font_outline_color", INK)
		tip.add_theme_constant_override("outline_size", 8)
		var fade := create_tween()
		fade.tween_interval(3.0)
		fade.tween_property(tip, "modulate:a", 0.0, 0.6)


func _modal(height: float, title: String, caption: String) -> Vector2:
	var width := 545.0
	var at := (units - Vector2(width, height)) * 0.5
	_panel(Rect2(at, Vector2(width, height)), PAPER, 32, Color("#d9eee3"), 2, 10)
	_text(caption, Rect2(at + Vector2(35, 27), Vector2(width - 70, 30)), 20, TEAL, KOREAN, HORIZONTAL_ALIGNMENT_CENTER)
	_text(title, Rect2(at + Vector2(28, 61), Vector2(width - 56, 61)), 47, INK, KOREAN, HORIZONTAL_ALIGNMENT_CENTER)
	return at


func _help() -> void:
	var at := _modal(468, "조작 방법", "시티 파크")
	for i in range(4):
		var controls := [
			["레인 이동", "A / D · ← / →", "좌우 스와이프"],
			["점프", "W · SPACE · ↑", "위로 스와이프"],
			["슬라이드", "S · ↓", "아래로 스와이프"],
			["일시정지", "ESC", "일시정지 버튼"],
		]
		var row: Array = controls[i]
		var start := at + Vector2(30, 150 + i * 52)
		_panel(Rect2(start, Vector2(485, 46)), PALE, 10)
		_text(row[0], Rect2(start + Vector2(15, 0), Vector2(112, 46)), 19)
		_text(row[1], Rect2(start + Vector2(132, 0), Vector2(170, 46)), 19, TEAL)
		_text(row[2], Rect2(start + Vector2(319, 0), Vector2(150, 46)), 19, SUBTLE)
	_button("돌아가기", Rect2(at + Vector2(30, 379), Vector2(485, 56)), func(): show_screen(Screen.TITLE), true)


func _paused() -> void:
	var at := _modal(341, "일시정지", "시티 파크")
	_button("계속 달리기", Rect2(at + Vector2(35, 148), Vector2(475, 55)), func(): resume_requested.emit(), true)
	_button("소리 끔" if muted else "소리 켬", Rect2(at + Vector2(35, 218), Vector2(231, 55)), func(): mute_requested.emit(), false, 23)
	_button("메인 화면", Rect2(at + Vector2(279, 218), Vector2(231, 55)), func(): home_requested.emit(), false, 23)


func _over() -> void:
	var at := _modal(478, "달리기 종료", "새로운 최고 기록!" if new_best else "시티 파크")
	_summary_card("최종 점수", format_number(score), Rect2(at + Vector2(30, 145), Vector2(235, 73)), TEAL)
	_summary_card("이동 거리", "%s m" % format_number(meters), Rect2(at + Vector2(280, 145), Vector2(235, 73)), TEAL)
	_summary_card("획득 코인", format_number(coins), Rect2(at + Vector2(30, 231), Vector2(235, 73)), GOLD)
	_summary_card("최고 기록", format_number(best), Rect2(at + Vector2(280, 231), Vector2(235, 73)), CORAL)
	_button("다시 달리기  ›", Rect2(at + Vector2(30, 345), Vector2(300, 65)), func(): start_requested.emit(), true)
	_button("메인 화면", Rect2(at + Vector2(344, 345), Vector2(171, 65)), func(): home_requested.emit(), false, 22)
