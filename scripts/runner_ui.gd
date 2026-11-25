class_name RunnerUI
extends Control

signal start_requested
signal test_requested
signal replay_requested
signal pause_requested
signal resume_requested
signal home_requested
signal mute_requested

enum Screen { TITLE, HUD, PAUSED, HELP, OVER }

const INK := Color("#123040")
const SUBTLE := Color("#476576")
const NAVY := Color("#102b3d")
const EDGE := Color("#315260")
const SURF := Color("#14b8a4")
const PAPER := Color("#fffdf6")
const PALE := Color("#e7f4ef")
const CORAL := Color("#f57369")
const GOLD := Color("#ffd175")
const FOG := Color("#a4c5cc")
const MINT := Color("#98f6d9")
const KOREAN := preload("res://assets/ui/GowunDodum.ttf")
const DISPLAY := preload("res://assets/ui/Outfit-Medium.ttf")
const BOLD := preload("res://assets/ui/Outfit-Bold.ttf")
const HERO := preload("res://assets/ui/murang.webp")
const VEIL := preload("res://scripts/menu_veil.gdshader")
const HEART := preload("res://assets/ui/lucide/heart.png")
const PAUSE := preload("res://assets/ui/lucide/pause.png")
const PIN := preload("res://assets/ui/lucide/map-pin.png")
const TROPHY := preload("res://assets/ui/lucide/trophy.png")
const COIN := preload("res://assets/ui/lucide/coins.png")
const WALK := preload("res://assets/ui/lucide/route.png")
const WAVES := preload("res://assets/ui/lucide/sailboat.png")
const SOUND := preload("res://assets/ui/lucide/volume-2.png")
const SILENT := preload("res://assets/ui/lucide/volume-x.png")
const PLAY := preload("res://assets/ui/lucide/play.png")

var screen := Screen.TITLE
var panels: Control
var overlay: ColorRect
var score_label: Label
var meters_label: Label
var coins_label: Label
var coin_icon: TextureRect
var heart_icons: Array[TextureRect] = []
var area_label: Label
var area_icon: TextureRect
var announcement: Control
var hero: TextureRect
var hero_origin := Vector2.ZERO
var displayed_score := 0.0
var best := 0
var bank := 0
var score := 0
var meters := 0
var coins := 0
var hearts := 3
var district := 0
var pace := 0.0
var pulse := 0.0
var run_clock := 0.0
var coin_pulse := 0.0
var area_time := 0.0
var new_best := false
var test_run := false
var muted := false
var units := Vector2(1280, 720)
var portrait := false
var effects: SpeedStreaks
var transition: Tween


class SpeedStreaks extends Control:
	var strength := 0.0
	var flash := 0.0
	var clock := 0.0

	func _draw() -> void:
		if flash > 0.0:
			var tint := Color(0.98, 0.25, 0.29, flash * 0.24)
			draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, size.y * 0.029)), tint)
			draw_rect(Rect2(Vector2(0, size.y * 0.971), Vector2(size.x, size.y * 0.029)), tint)
		if strength <= 0.0:
			return
		var center := size * Vector2(0.5, 0.43)
		for i in range(26):
			var direction := -1.0 if i % 2 == 0 else 1.0
			var flow := fposmod(clock * (1.7 + i * 0.021) + i * 0.376, 1.0)
			var y := 0.13 + fposmod(i * 0.178, 0.79)
			var rim := Vector2(size.x * (0.5 + direction * (0.36 + flow * 0.165)), y * size.y)
			var line := (rim - center).normalized() * (15 + flow * 64)
			var tint := Color(0.92, 1.0, 0.99, strength * sin(flow * PI) * 0.48)
			draw_line(rim - line, rim, tint, 1.7, true)


class RecordGlints extends Control:
	var time := 0.0

	func _process(dt: float) -> void:
		time += dt
		queue_redraw()

	func _draw() -> void:
		for i in range(14):
			var side := 1 if i % 2 == 0 else -1
			var phase := fposmod(time * 0.71 + i * 0.127, 1.0)
			var at := Vector2(size.x * 0.5 + side * (84 + 141 * phase), 52 + cos(i * 3.1) * 44 * phase)
			var gleam := (4 + i % 4) * sin(phase * PI)
			draw_colored_polygon(PackedVector2Array([
				at + Vector2(gleam, 0), at + Vector2(0, gleam),
				at - Vector2(gleam, 0), at - Vector2(0, gleam)]),
				Color(1, 0.78, 0.38, sin(phase * PI) * 0.88))


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
	pulse = move_toward(pulse, 0.0, dt * 3.8)
	run_clock += dt
	effects.strength = pace if screen == Screen.HUD else 0.0
	effects.flash = pulse if screen == Screen.HUD else 0.0
	effects.clock = run_clock
	effects.queue_redraw()
	if is_instance_valid(hero):
		hero.position.y = hero_origin.y + sin(run_clock * 2.1) * 6.0
	if screen != Screen.HUD or not is_instance_valid(score_label):
		return
	displayed_score = lerpf(displayed_score, float(score), 1.0 - exp(-dt * 19.0))
	var shown := roundi(displayed_score)
	var text := format_number(shown)
	if score_label.text != text:
		_number(score_label, text)
	coin_pulse = move_toward(coin_pulse, 0.0, dt * 4.7)
	coin_icon.scale = Vector2.ONE * (1.0 + sin(coin_pulse * PI / 2.0) * 0.34)
	coins_label.modulate = Color.WHITE.lerp(MINT, coin_pulse)
	area_time = maxf(area_time - dt, 0)
	_sync_announcement()


func show_screen(target: Screen) -> void:
	var changed := screen != target
	screen = target
	_layout()
	if not changed:
		return
	if transition:
		transition.kill()
	panels.modulate.a = 0.18
	panels.position.y = 10.0
	transition = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	transition.tween_property(panels, "modulate:a", 1.0, 0.23)
	transition.tween_property(panels, "position:y", 0.0, 0.27)


func set_district(next: int, announce: bool) -> void:
	district = next
	area_time = 3.1 if announce else 0.0
	if screen == Screen.HUD and is_instance_valid(area_label):
		area_label.text = Tuning.DISTRICTS[district].name
		area_icon.texture = PIN if district == 0 else WAVES
		area_icon.modulate = MINT if district == 0 else GOLD
		_sync_announcement()


func _sync_announcement() -> void:
	if not is_instance_valid(announcement):
		return
	announcement.visible = area_time > 0.0
	var fade_in := smoothstep(0.0, 0.33, 3.1 - area_time)
	var fade_out := smoothstep(0.0, 0.53, area_time)
	announcement.modulate.a = fade_in * fade_out
	announcement.position.y = -15.0 * (1.0 - fade_in)


func update_values(current_score: int, distance: int, current_coins: int, health: int) -> void:
	if current_coins > coins:
		coin_pulse = 1.0
	if current_score < score:
		displayed_score = current_score
	score = current_score
	meters = distance
	coins = current_coins
	hearts = health
	if screen == Screen.HUD and is_instance_valid(score_label):
		_number(meters_label, "%s m" % format_number(meters))
		_number(coins_label, format_number(coins))
		for i in heart_icons.size():
			heart_icons[i].modulate = CORAL if i < hearts else Color("#668090")


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
	hero = null
	announcement = null
	heart_icons.clear()
	portrait = size.x < size.y * 0.98
	var fitting := minf(size.x / 670.0, size.y / 1050.0) if portrait else minf(size.x / 1060.0, size.y / 710.0)
	panels.scale = Vector2.ONE * fitting
	units = size / fitting
	panels.size = units
	overlay.visible = screen != Screen.HUD
	var material := overlay.material as ShaderMaterial
	material.set_shader_parameter("title", screen == Screen.TITLE)
	material.set_shader_parameter("portrait", portrait)
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
	style.shadow_color = Color(0.025, 0.09, 0.13, 0.27)
	style.shadow_size = shadow
	style.shadow_offset = Vector2(0, 5)
	return style


func _panel(rect: Rect2, fill: Color, radius := 22, edge := Color.TRANSPARENT, width := 0, shadow := 0, parent: Control = null) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _box(fill, radius, edge, width, shadow))
	(parent if parent else panels).add_child(panel)
	return panel


func _text(value: String, rect: Rect2, font_size: int, tint := INK, font: Font = KOREAN,
		align := HORIZONTAL_ALIGNMENT_LEFT, parent: Control = null) -> Label:
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
	(parent if parent else panels).add_child(label)
	return label


func _icon(texture: Texture2D, at: Vector2, edge: float, tint := Color.WHITE, parent: Control = null) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position = at
	icon.size = Vector2.ONE * edge
	icon.pivot_offset = icon.size * 0.5
	icon.modulate = tint
	icon.mouse_filter = MOUSE_FILTER_IGNORE
	(parent if parent else panels).add_child(icon)
	return icon


func _button(value: String, rect: Rect2, callback: Callable, primary := false, font_size := 25) -> Button:
	var button := Button.new()
	button.text = value
	button.position = rect.position
	button.size = rect.size
	button.pivot_offset = rect.size * 0.5
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", KOREAN)
	button.add_theme_font_size_override("font_size", font_size)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(color_name, Color("#092c36") if primary else INK)
	var color := SURF if primary else PAPER
	var edge := Color("#087a70") if primary else Color("#a9c9cc")
	button.add_theme_stylebox_override("normal", _box(color, 17, edge, 2, 6 if primary else 0))
	button.add_theme_stylebox_override("hover", _box(MINT if primary else PALE, 17, edge, 2, 5))
	button.add_theme_stylebox_override("pressed", _box(Color("#39ceaf") if primary else Color("#dcefed"), 17, edge, 2))
	button.add_theme_stylebox_override("focus", _box(Color.TRANSPARENT, 17, Color("#ffbc4b"), 3))
	button.mouse_entered.connect(func(): _button_scale(button, 1.026))
	button.mouse_exited.connect(func(): _button_scale(button, 1.0))
	button.button_down.connect(func(): _button_scale(button, 0.965))
	button.button_up.connect(func(): _button_scale(button, 1.014))
	button.pressed.connect(callback)
	panels.add_child(button)
	return button


func _button_scale(button: Button, amount: float) -> void:
	var prior: Tween = button.get_meta("hover_tween") if button.has_meta("hover_tween") else null
	if prior:
		prior.kill()
	var tween := button.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	button.set_meta("hover_tween", tween)
	tween.tween_property(button, "scale", Vector2.ONE * amount, 0.12)


func _title() -> void:
	var x := maxf(54.0, (units.x - 1130.0) * 0.43)
	var y := maxf(41.0, (units.y - 618.0) * 0.5)
	var width := 472.0
	var stats_y := y + 256.0
	if portrait:
		x = (units.x - width) * 0.5
		y = 49.0 + maxf(0.0, units.y - 1080.0) * 0.36
		stats_y = y + 520.0
		_panel(Rect2(x - 34, y - 25, width + 68, 955), Color(1, 0.985, 0.94, 0.96), 37, Color("#c6e3d9"), 2, 13)
		hero = _icon(HERO, Vector2(x + 56, y + 188), 360)
		hero_origin = hero.position
	else:
		_panel(Rect2(x - 24, y - 20, width + 48, 615), Color(1, 0.988, 0.945, 0.976), 34, Color("#cfecdd"), 2, 12)
		var art_size := minf(595.0, units.x - x - width - 70.0)
		var art_x := units.x - art_size - maxf(26.0, (units.x - 1280.0) * 0.34)
		var art_y := units.y * 0.5 - art_size * 0.50
		var radius := art_size * 0.79
		_panel(Rect2(art_x + (art_size - radius) / 2, art_y + 53, radius, radius),
			Color(1, 0.91, 0.69, 0.27), int(radius), Color(1, 0.92, 0.74, 0.8), 2)
		hero = _icon(HERO, Vector2(art_x, art_y), art_size)
		hero_origin = hero.position

	_panel(Rect2(x, y, 133, 32), PALE, 16)
	_icon(PIN, Vector2(x + 9, y + 7), 18, Color("#137c70"))
	_text("시티 파크", Rect2(x + 36, y + 1, 96, 30), 18)
	_panel(Rect2(x + 143, y, 151, 32), Color("#ffe8d7"), 16)
	_icon(WAVES, Vector2(x + 154, y + 7), 18, Color("#963e39"))
	_text("산호빛 항구", Rect2(x + 182, y + 1, 112, 30), 18)
	_text("v0.2", Rect2(x + 398, y, 72, 31), 18, SUBTLE, DISPLAY, HORIZONTAL_ALIGNMENT_RIGHT)
	var title := _text("무랑 런", Rect2(x - 3, y + 45, width, 105), 98 if not portrait else 92)
	title.add_theme_constant_override("outline_size", 5)
	title.add_theme_color_override("font_outline_color", INK)
	_text("MURANG RUN", Rect2(x + 2, y + 155, width, 44), 45, Color("#237d73"), BOLD)

	_metric("최고 기록", format_number(best), Rect2(x, stats_y, 228, 72), TROPHY, GOLD)
	_metric("누적 코인", format_number(bank), Rect2(x + 244, stats_y, 228, 72), COIN, GOLD)
	var by := stats_y + 89.0
	_button("게임 시작  ·  0m", Rect2(x, by, width, 62), func(): start_requested.emit(), true, 28)
	_icon(PLAY, Vector2(x + 21, by + 18), 24, INK)
	var controls_y := by + 74.0
	if Tuning.ENABLE_DISTRICT_TEST:
		_button("신규 맵 테스트  ·  %sm" % format_number(int(Tuning.DISTRICTS[Tuning.TEST_DISTRICT].start)), Rect2(x, controls_y, width, 55), func(): test_requested.emit(), false, 23)
		_icon(WAVES, Vector2(x + 21, controls_y + 15), 23, Color("#137c70"))
		controls_y += 66.0
	_button("조작 방법", Rect2(x, controls_y, 353, 50), func(): show_screen(Screen.HELP), false, 22)
	_button("", Rect2(x + 369, controls_y, 103, 50), func(): mute_requested.emit())
	_icon(SILENT if muted else SOUND, Vector2(x + 407, controls_y + 13), 24, INK)


func _metric(caption: String, value: String, rect: Rect2, texture: Texture2D, accent: Color, animate := false) -> Label:
	var small := rect.size.x < 182.0
	var chip := 31.0 if small else 37.0
	var pic := 19.0 if small else 23.0
	var inset := 10.0 if small else 13.0
	var text_x := 49.0 if small else 61.0
	_panel(rect, NAVY, 18, EDGE, 2)
	_panel(Rect2(rect.position + Vector2(inset, (rect.size.y - chip) * 0.5), Vector2.ONE * chip), EDGE, 10)
	var glyph := _icon(texture, rect.position + Vector2(inset + (chip - pic) * 0.5, (rect.size.y - pic) * 0.5), pic, accent)
	if animate:
		coin_icon = glyph
	var available := rect.size.x - text_x - 7.0
	_text(caption, Rect2(rect.position + Vector2(text_x, 6), Vector2(available, 25)), 17, FOG)
	var label := _text("", Rect2(rect.position + Vector2(text_x, 27), Vector2(available, 38)), 29, PAPER, BOLD)
	label.set_meta("number_width", available)
	_number(label, value)
	return label


func _number(label: Label, value: String) -> void:
	if label.text == value:
		return
	var width: float = label.get_meta("number_width")
	var preferred := BOLD.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 29).x
	var height := mini(29, floori(29.0 * width / maxf(preferred, 1.0)))
	label.add_theme_font_size_override("font_size", maxi(13, height))
	label.text = value


func _hud() -> void:
	var top := 19.0
	var left := 21.0
	var w := units.x
	var width := minf(512.0, w - 206.0)
	var card := (width - 14.0) / 3.0
	score_label = _metric("점수", format_number(score), Rect2(left, top, card, 65), TROPHY, GOLD)
	meters_label = _metric("거리", "%s m" % format_number(meters), Rect2(left + card + 7, top, card, 65), WALK, MINT)
	coins_label = _metric("코인", format_number(coins), Rect2(left + (card + 7) * 2.0, top, card, 65), COIN, GOLD, true)
	_panel(Rect2(w - 165, top + 3, 91, 56), NAVY, 17, EDGE, 2)
	for n in range(3):
		heart_icons.append(_icon(HEART, Vector2(w - 157 + n * 24, top + 20), 21,
			CORAL if n < hearts else Color("#668090")))
	var pause_at := Vector2(w - 66, top + 3)
	_button("", Rect2(pause_at, Vector2(48, 56)), func(): pause_requested.emit())
	_icon(PAUSE, pause_at + Vector2(13, 17), 22, INK)
	var area_y := top + 75.0
	_panel(Rect2(left, area_y, 157, 37), NAVY, 16, EDGE, 2)
	area_icon = _icon(PIN if district == 0 else WAVES, Vector2(left + 12, area_y + 8), 21, MINT if district == 0 else GOLD)
	area_label = _text(Tuning.DISTRICTS[district].name, Rect2(left + 42, area_y, 114, 36), 19, PAPER)
	if test_run:
		_panel(Rect2(left + 167, area_y, 119, 37), GOLD, 16)
		_text("TEST MODE", Rect2(left + 167, area_y, 119, 36), 17, INK, BOLD, HORIZONTAL_ALIGNMENT_CENTER)
	announcement = Control.new()
	announcement.mouse_filter = MOUSE_FILTER_IGNORE
	panels.add_child(announcement)
	var banner_y := area_y + (51 if portrait else 3)
	var banner_x := w * 0.5 - 172.0
	_panel(Rect2(banner_x, banner_y, 344, 52), NAVY, 16, GOLD, 2, 6, announcement)
	_icon(WAVES, Vector2(banner_x + 20, banner_y + 15), 22, GOLD, announcement)
	_text("산호빛 항구 진입", Rect2(banner_x + 56, banner_y, 276, 50), 24, PAPER, KOREAN, HORIZONTAL_ALIGNMENT_LEFT, announcement)
	_sync_announcement()


func _dialog(height: float, name: String, caption: String) -> Vector2:
	var width := 530.0
	var at := (units - Vector2(width, height)) * 0.5
	_panel(Rect2(at, Vector2(width, height)), PAPER, 31, Color("#a5d7d2"), 3, 12)
	_panel(Rect2(at + Vector2(23, 23), Vector2(width - 46, 30)), PALE, 14)
	_text(caption, Rect2(at + Vector2(35, 22), Vector2(width - 70, 32)), 18, SUBTLE, KOREAN, HORIZONTAL_ALIGNMENT_CENTER)
	_text(name, Rect2(at + Vector2(20, 65), Vector2(width - 40, 64)), 43, INK, KOREAN, HORIZONTAL_ALIGNMENT_CENTER)
	return at


func _help() -> void:
	var at := _dialog(449, "조작 방법", "무랑 런")
	var controls := [
		["레인 이동", "A / D · ← / →", "좌우 스와이프"],
		["점프", "W · SPACE · ↑", "위로 스와이프"],
		["슬라이드", "S · ↓", "아래로 스와이프"],
		["일시정지", "ESC", "일시정지 버튼"],
	]
	for i in range(controls.size()):
		var row: Array = controls[i]
		var start := at + Vector2(27, 144 + i * 49)
		_panel(Rect2(start, Vector2(476, 42)), PALE, 10)
		_text(row[0], Rect2(start + Vector2(13, 0), Vector2(111, 42)), 19)
		_text(row[1], Rect2(start + Vector2(126, 0), Vector2(165, 42)), 19, SUBTLE)
		_text(row[2], Rect2(start + Vector2(308, 0), Vector2(152, 42)), 19, SUBTLE)
	_button("돌아가기", Rect2(at + Vector2(28, 359), Vector2(474, 56)), func(): show_screen(Screen.TITLE), true)


func _paused() -> void:
	var caption: String = "TEST MODE" if test_run else Tuning.DISTRICTS[district].name
	var at := _dialog(307, "일시정지", caption)
	_button("계속 달리기", Rect2(at + Vector2(28, 145), Vector2(474, 58)), func(): resume_requested.emit(), true)
	_button("소리 끔" if muted else "소리 켬", Rect2(at + Vector2(28, 220), Vector2(230, 53)), func(): mute_requested.emit(), false, 22)
	_button("메인 화면", Rect2(at + Vector2(273, 220), Vector2(229, 53)), func(): home_requested.emit(), false, 22)


func _over() -> void:
	var caption := "TEST MODE" if test_run else ("새로운 최고 기록!" if new_best else Tuning.DISTRICTS[district].name as String)
	var at := _dialog(505, "달리기 결과", caption)
	_panel(Rect2(at + Vector2(26, 136), Vector2(478, 120)), NAVY, 23, EDGE, 2)
	_text("최종 점수", Rect2(at + Vector2(28, 145), Vector2(474, 24)), 18, GOLD, KOREAN, HORIZONTAL_ALIGNMENT_CENTER)
	_text(format_number(score), Rect2(at + Vector2(28, 170), Vector2(474, 71)), 61, PAPER, BOLD, HORIZONTAL_ALIGNMENT_CENTER)
	if new_best:
		var glints := RecordGlints.new()
		glints.position = at + Vector2(26, 143)
		glints.size = Vector2(478, 100)
		glints.mouse_filter = MOUSE_FILTER_IGNORE
		panels.add_child(glints)
	_metric("이동 거리", "%s m" % format_number(meters), Rect2(at + Vector2(26, 273), Vector2(154, 70)), WALK, MINT)
	_metric("획득 코인", format_number(coins), Rect2(at + Vector2(188, 273), Vector2(154, 70)), COIN, GOLD)
	_metric("최고 기록", format_number(best), Rect2(at + Vector2(350, 273), Vector2(154, 70)), TROPHY, GOLD)
	if test_run:
		_text("이 주행의 점수와 코인은 저장되지 않습니다", Rect2(at + Vector2(26, 350), Vector2(478, 32)), 19, SUBTLE, KOREAN, HORIZONTAL_ALIGNMENT_CENTER)
	_button("다시 달리기", Rect2(at + Vector2(26, 390), Vector2(296, 65)), func(): replay_requested.emit(), true, 25)
	_button("메인 화면", Rect2(at + Vector2(335, 390), Vector2(169, 65)), func(): home_requested.emit(), false, 22)
