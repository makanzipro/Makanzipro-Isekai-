extends Node
# MAKANZIPRO ISEKAI RPG - Prototype v0.2
# Contenu : monde, camera 3e personne, commandes tactiles, guilde avec porte
# qui s'ouvre, PNJ + dialogue, quete, slimes, attaque + competence,
# niveau/XP/or, sauvegarde locale. Tout est construit par code.

const SPEED := 6.0
const JUMP_FORCE := 8.0
const GRAVITY := 20.0
const JOY_RADIUS := 90.0
const SAVE_PATH := "user://save.cfg"
const GUILD_POS := Vector3(0, 0, -12)
const SPAWN_POS := Vector3(0, 1.2, 15)

# --- Joueur ---
var player: CharacterBody3D
var body_mesh: Node3D
var cam_pivot: Node3D
var cam: Camera3D
var slash: MeshInstance3D
var blast: MeshInstance3D

# --- Statistiques ---
var level := 1
var xp := 0
var gold := 0
var max_hp := 100
var hp := 100
var max_mp := 30
var mp := 30.0
var quest_state := 0  # 0 aucune, 1 en cours, 2 a rendre, 3 terminee
var kills := 0

# --- Timers ---
var attack_cd := 0.0
var skill_cd := 0.0
var hit_cd := 0.0
var slash_t := 0.0
var blast_t := 0.0
var autosave_t := 0.0

# --- Monde ---
var slimes: Array = []
var npc: Node3D
var door_pivot: Node3D
var door_open := false

# --- Commandes / interface ---
var joy_vec := Vector2.ZERO
var joy_touch := -1
var joy_center := Vector2(200, 540)
var look_touch := -1
var jump_pressed := false
var joy_base: Panel
var joy_knob: Panel
var buttons := {}
var hud_label: Label
var quest_label: Label
var dialogue_open := false
var dialogue_panel: PanelContainer
var dialogue_label: Label
var dialogue_buttons: HBoxContainer


func _ready() -> void:
	_build_world()
	_build_guild()
	_build_player()body_mesh = Node3D.new()
body_mesh.set_script(load("res://character_visual.gd"))
body_mesh.set("coat_color", Color(0.12, 0.25, 0.65))
player.add_child(body_mesh)
	_spawn_slimes()
	_build_hud()
	_load()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		_save()


# =====================  MONDE  =====================


func _build_world() -> void:
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-50, -30, 0)
    add_child(sun)

    var world_env := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.55, 0.78, 1.0)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.8, 0.8, 0.9)
    env.ambient_light_energy = 0.7
    world_env.environment = env
    add_child(world_env)

    # GRAND SOL
    _add_box(Vector3(0, -0.5, 0), Vector3(100, 1, 100), Color(0.3, 0.65, 0.3))

    # ROUTE PRINCIPALE
    _add_box(Vector3(0, 0.02, 6), Vector3(7, 0.08, 42), Color(0.35, 0.32, 0.29))

    # PLACE DEVANT LA GUILDE
    _add_box(Vector3(0, 0.04, -5), Vector3(18, 0.1, 7), Color(0.65, 0.58, 0.46))

    # MAISONS ET BOUTIQUES
    var positions = [
        Vector3(-14, 0, 8),
        Vector3(14, 0, 8),
        Vector3(-15, 0, -8),
        Vector3(15, 0, -8),
        Vector3(-25, 0, 3),
        Vector3(25, 0, 3)
    ]

    for i in range(positions.size()):
        var p: Vector3 = positions[i]

        _add_box(p + Vector3(0, 2, 0),
            Vector3(7, 4, 6), Color(0.85, 0.72, 0.55))

        _add_box(p + Vector3(0, 4.3, 0),
            Vector3(8, 1, 7), Color(0.55, 0.18, 0.16))

        _add_box(p + Vector3(0, 1, 3.05),
            Vector3(1.5, 2, 0.15), Color(0.3, 0.16, 0.08))

    # ARBRES
    var tree_positions = [
        Vector3(-9, 0, 14),
        Vector3(9, 0, 14),
        Vector3(-9, 0, 3),
        Vector3(9, 0, 3),
        Vector3(-9, 0, -5),
        Vector3(9, 0, -5),
        Vector3(-23, 0, -12),
        Vector3(23, 0, -12)
    ]

    for p in tree_positions:
        _add_box(p + Vector3(0, 1, 0),
            Vector3(0.6, 2, 0.6), Color(0.35, 0.2, 0.1))

        var leaves := MeshInstance3D.new()
        var sphere := SphereMesh.new()
        sphere.radius = 1.7
        sphere.height = 3.4
        leaves.mesh = sphere
        leaves.position = p + Vector3(0, 3, 0)
        leaves.material_override = _mat(Color(0.12, 0.48, 0.16))
        add_child(leaves)

    # LAMPADAIRES
    for z in [12, 2, -4]:
        for x in [-4, 4]:
            _add_box(Vector3(x, 1.5, z),
                Vector3(0.18, 3, 0.18), Color(0.15, 0.12, 0.1))

            _add_box(Vector3(x, 3.1, z),
                Vector3(0.8, 0.6, 0.8), Color(1, 0.8, 0.35))



func _build_guild() -> void:
	var wall_color := Color(0.75, 0.7, 0.8)
	# Sol interieur
	_add_box(GUILD_POS + Vector3(0, 0.025, 0), Vector3(11.6, 0.05, 9.6), Color(0.5, 0.35, 0.2))
	# Murs (la porte est au milieu du mur avant, z = +5)
	_add_box(GUILD_POS + Vector3(0, 2, -5), Vector3(12.4, 4, 0.4), wall_color)
	_add_box(GUILD_POS + Vector3(-6, 2, 0), Vector3(0.4, 4, 10), wall_color)
	_add_box(GUILD_POS + Vector3(6, 2, 0), Vector3(0.4, 4, 10), wall_color)
	_add_box(GUILD_POS + Vector3(-3.5, 2, 5), Vector3(5, 4, 0.4), wall_color)
	_add_box(GUILD_POS + Vector3(3.5, 2, 5), Vector3(5, 4, 0.4), wall_color)
	_add_box(GUILD_POS + Vector3(0, 3.5, 5), Vector3(2, 1, 0.4), wall_color)

	var sign_label := Label3D.new()
	sign_label.text = "GUILDE"
	sign_label.position = GUILD_POS + Vector3(0, 5.2, 5.3)
	sign_label.pixel_size = 0.012
	sign_label.font_size = 96
	add_child(sign_label)

	# Porte avec charniere : elle pivote vers l'interieur
	door_pivot = Node3D.new()
	door_pivot.position = GUILD_POS + Vector3(-1, 0, 5)
	add_child(door_pivot)
	var door := _make_box_body(Vector3(2, 2.2, 0.2), Color(0.4, 0.25, 0.1))
	door.position = Vector3(1, 1.1, 0)
	door_pivot.add_child(door)

	# Receptionniste
	npc = Node3D.new()
	npc.position = GUILD_POS + Vector3(0, 0, -3)
	var m := MeshInstance3D.new()
	var c := CapsuleMesh.new()
	c.radius = 0.4
	c.height = 1.8
	m.mesh = c
	m.position.y = 0.9
	m.material_override = _mat(Color(0.3, 0.4, 0.9))
	npc.add_child(m)
	var nb := StaticBody3D.new()
	var ncol := CollisionShape3D.new()
	var nshape := CapsuleShape3D.new()
	nshape.radius = 0.4
	nshape.height = 1.8
	ncol.shape = nshape
	ncol.position.y = 0.9
	nb.add_child(ncol)
	npc.add_child(nb)
	var nl := Label3D.new()
	nl.text = "Réceptionniste"
	nl.position = Vector3(0, 2.4, 0)
	nl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	nl.pixel_size = 0.01
	nl.font_size = 48
	npc.add_child(nl)
	add_child(npc)


func _make_box_body(size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _mat(color)
	body.add_child(mesh)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	return body


func _add_box(pos: Vector3, size: Vector3, color: Color) -> void:
	var body := _make_box_body(size, color)
	body.position = pos
	add_child(body)


func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	return m


func _spawn_slimes() -> void:
	for p in [Vector3(10, 0.7, 8), Vector3(-10, 0.7, 10), Vector3(14, 0.7, 18), Vector3(-14, 0.7, 20)]:
		var s := CharacterBody3D.new()
		s.position = p
		s.set_meta("hp", 30)
		var mesh := MeshInstance3D.new()
		var sph := SphereMesh.new()
		sph.radius = 0.6
		sph.height = 1.2
		mesh.mesh = sph
		mesh.material_override = _mat(Color(0.2, 0.85, 0.3))
		s.add_child(mesh)
		var col := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 0.6
		col.shape = shape
		s.add_child(col)
		add_child(s)
		slimes.append(s)


# =====================  JOUEUR  =====================

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.position = SPAWN_POS

	body_mesh = Node3D.new()
	player.add_child(body_mesh)

	var capsule_mesh := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.4
	cap.height = 1.8
	capsule_mesh.mesh = cap
	capsule_mesh.material_override = _mat(Color(0.9, 0.3, 0.3))
	body_mesh.add_child(capsule_mesh)

	var nose := MeshInstance3D.new()
	var nose_box := BoxMesh.new()
	nose_box.size = Vector3(0.2, 0.2, 0.3)
	nose.mesh = nose_box
	nose.position = Vector3(0, 0.5, -0.45)
	nose.material_override = _mat(Color(1, 1, 1))
	body_mesh.add_child(nose)

	# Effet de coup d'epee
	slash = MeshInstance3D.new()
	var sb := BoxMesh.new()
	sb.size = Vector3(1.8, 0.1, 1.4)
	slash.mesh = sb
	slash.position = Vector3(0, 0.3, -1.3)
	slash.material_override = _mat(Color(1, 0.95, 0.5))
	slash.visible = false
	body_mesh.add_child(slash)

	# Effet de competence (explosion)
	blast = MeshInstance3D.new()
	var bs := SphereMesh.new()
	bs.radius = 4.5
	bs.height = 9.0
	blast.mesh = bs
	var bm := StandardMaterial3D.new()
	bm.albedo_color = Color(1, 0.5, 0.1, 0.35)
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	blast.material_override = bm
	blast.visible = false
	player.add_child(blast)

	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.8
	col.shape = shape
	player.add_child(col)
	add_child(player)

	cam_pivot = Node3D.new()
	cam_pivot.position = Vector3(0, 1.5, 0)
	cam_pivot.rotation.x = -0.3
	player.add_child(cam_pivot)
	cam = Camera3D.new()
	cam.position = Vector3(0, 0.5, 5.5)
	cam_pivot.add_child(cam)
	cam.make_current()


func _physics_process(delta: float) -> void:
	if dialogue_open:
		player.velocity.x = 0.0
		player.velocity.z = 0.0
	else:
		var move := joy_vec
		var kb := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		if kb != Vector2.ZERO:
			move = kb
		var dir := Vector3(move.x, 0, move.y).rotated(Vector3.UP, cam_pivot.rotation.y)
		player.velocity.x = dir.x * SPEED
		player.velocity.z = dir.z * SPEED
		if dir.length() > 0.1:
			var target := atan2(-dir.x, -dir.z)
			body_mesh.rotation.y = lerp_angle(body_mesh.rotation.y, target, 10.0 * delta)

	if not player.is_on_floor():
		player.velocity.y -= GRAVITY * delta
	elif jump_pressed and not dialogue_open:
		player.velocity.y = JUMP_FORCE
	jump_pressed = false
	player.move_and_slide()

	if player.position.y < -10.0:
		_respawn()

	hit_cd = maxf(hit_cd - delta, 0.0)
	_update_slimes(delta)


func _update_slimes(delta: float) -> void:
	for s in slimes:
		var to_p: Vector3 = player.global_position - s.global_position
		to_p.y = 0.0
		var dist := to_p.length()
		var v := Vector3.ZERO
		if dist < 12.0 and dist > 1.2:
			v = to_p.normalized() * 2.5
		s.velocity.x = v.x
		s.velocity.z = v.z
		if not s.is_on_floor():
			s.velocity.y -= GRAVITY * delta
		else:
			s.velocity.y = 0.0
		s.move_and_slide()
		if dist < 1.8 and hit_cd <= 0.0:
			hit_cd = 1.0
			_hurt(5)


func _hurt(amount: int) -> void:
	hp -= amount
	if hp <= 0:
		_respawn()


func _respawn() -> void:
	player.position = SPAWN_POS
	player.velocity = Vector3.ZERO
	hp = max_hp
	mp = float(max_mp)


# =====================  COMBAT  =====================

func _attack() -> void:
	if dialogue_open or attack_cd > 0.0:
		return
	attack_cd = 0.4
	slash.visible = true
	slash_t = 0.15
	var fwd := -body_mesh.global_transform.basis.z
	for s in slimes.duplicate():
		var to_s: Vector3 = s.global_position - player.global_position
		to_s.y = 0.0
		var d := to_s.length()
		if d < 2.6 and (d < 0.8 or fwd.dot(to_s.normalized()) > 0.2):
			_damage_slime(s, 15)


func _skill() -> void:
	if dialogue_open or skill_cd > 0.0 or mp < 10.0:
		return
	mp -= 10.0
	skill_cd = 3.0
	blast.visible = true
	blast_t = 0.25
	for s in slimes.duplicate():
		if player.global_position.distance_to(s.global_position) < 4.5:
			_damage_slime(s, 40)


func _damage_slime(s: CharacterBody3D, dmg: int) -> void:
	var h := int(s.get_meta("hp")) - dmg
	s.set_meta("hp", h)
	if h <= 0:
		slimes.erase(s)
		s.queue_free()
		_gain(10, 5)
		if quest_state == 1:
			kills += 1
			if kills >= 3:
				quest_state = 2
		_save()


func _gain(add_xp: int, add_gold: int) -> void:
	xp += add_xp
	gold += add_gold
	while xp >= level * 30:
		xp -= level * 30
		level += 1
		max_hp += 10
		max_mp += 5
		hp = max_hp
		mp = float(max_mp)


# =====================  INTERACTIONS  =====================

func _dist2d(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _nearest_interactable() -> String:
	var p := player.global_position
	var d_npc := _dist2d(p, npc.global_position)
	var d_door := _dist2d(p, GUILD_POS + Vector3(0, 0, 5))
	if d_npc < 3.0 and d_npc <= d_door:
		return "npc"
	if d_door < 3.0:
		return "door"
	return ""


func _interact() -> void:
	if dialogue_open:
		return
	match _nearest_interactable():
		"door":
			_toggle_door()
		"npc":
			_talk_to_npc()


func _toggle_door() -> void:
	door_open = not door_open
	var tw := create_tween()
	tw.tween_property(door_pivot, "rotation_degrees:y", 90.0 if door_open else 0.0, 0.5)


func _talk_to_npc() -> void:
	match quest_state:
		0:
			_show_dialogue("Bienvenue à la guilde, aventurier ! Des slimes menacent le village. Peux-tu en éliminer 3 ?", [["Accepter", "accept"], ["Plus tard", "close"]])
		1:
			_show_dialogue("Il reste %d slime(s) à éliminer. Courage !" % (3 - kills), [["OK", "close"]])
		2:
			_show_dialogue("Bravo ! Voici ta récompense : 50 or et 40 XP.", [["Récupérer", "reward"]])
		_:
			_show_dialogue("Tu es maintenant aventurier de rang E. Merci pour ton aide !", [["OK", "close"]])


func _show_dialogue(text: String, choices: Array) -> void:
	dialogue_open = true
	joy_vec = Vector2.ZERO
	joy_touch = -1
	look_touch = -1
	dialogue_label.text = text
	for c in dialogue_buttons.get_children():
		c.queue_free()
	for ch in choices:
		var b := Button.new()
		b.text = ch[0]
		b.custom_minimum_size = Vector2(220, 64)
		b.add_theme_font_size_override("font_size", 26)
		b.pressed.connect(_on_choice.bind(ch[1]))
		dialogue_buttons.add_child(b)
	dialogue_panel.visible = true


func _on_choice(action: String) -> void:
	match action:
		"accept":
			quest_state = 1
			kills = 0
		"reward":
			quest_state = 3
			_gain(40, 50)
	dialogue_open = false
	dialogue_panel.visible = false
	_save()


# =====================  INTERFACE  =====================

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var sw := get_viewport().get_visible_rect().size.x

	hud_label = _make_label(layer, Vector2(20, 12))
	quest_label = _make_label(layer, Vector2(20, 120))

	joy_base = _circle(JOY_RADIUS * 2.0, Color(1, 1, 1, 0.25))
	joy_base.position = joy_center - joy_base.size / 2.0
	layer.add_child(joy_base)
	joy_knob = _circle(70.0, Color(1, 1, 1, 0.6))
	joy_knob.position = joy_center - joy_knob.size / 2.0
	layer.add_child(joy_knob)

	_make_button(layer, "attack", "ATTAQUE", Vector2(sw - 190.0, 520.0), 130.0, Color(1, 0.3, 0.3, 0.55))
	_make_button(layer, "jump", "SAUT", Vector2(sw - 320.0, 590.0), 100.0, Color(1, 0.8, 0.2, 0.5))
	_make_button(layer, "skill", "Z", Vector2(sw - 330.0, 460.0), 90.0, Color(0.5, 0.4, 1, 0.55))
	_make_button(layer, "interact", "ACTION", Vector2(sw - 200.0, 380.0), 100.0, Color(0.3, 0.9, 0.5, 0.6))

	dialogue_panel = PanelContainer.new()
	dialogue_panel.custom_minimum_size = Vector2(900, 220)
	dialogue_panel.position = Vector2((sw - 900.0) / 2.0, 470.0)
	var vb := VBoxContainer.new()
	dialogue_panel.add_child(vb)
	dialogue_label = Label.new()
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.custom_minimum_size = Vector2(860, 100)
	dialogue_label.add_theme_font_size_override("font_size", 28)
	vb.add_child(dialogue_label)
	dialogue_buttons = HBoxContainer.new()
	vb.add_child(dialogue_buttons)
	dialogue_panel.visible = false
	layer.add_child(dialogue_panel)


func _make_label(layer: CanvasLayer, pos: Vector2) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", 26)
	l.add_theme_color_override("font_shadow_color", Color.BLACK)
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(l)
	return l


func _circle(diameter: float, color: Color) -> Panel:
	var p := Panel.new()
	p.size = Vector2(diameter, diameter)
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(int(diameter / 2.0))
	p.add_theme_stylebox_override("panel", style)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


func _make_button(layer: CanvasLayer, key: String, text: String, pos: Vector2, d: float, color: Color) -> void:
	var b := _circle(d, color)
	b.position = pos
	var l := Label.new()
	l.text = text
	l.size = b.size
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(l)
	layer.add_child(b)
	buttons[key] = b


func _process(delta: float) -> void:
	attack_cd = maxf(attack_cd - delta, 0.0)
	skill_cd = maxf(skill_cd - delta, 0.0)
	mp = minf(mp + 2.0 * delta, float(max_mp))
	if slash_t > 0.0:
		slash_t -= delta
		if slash_t <= 0.0:
			slash.visible = false
	if blast_t > 0.0:
		blast_t -= delta
		if blast_t <= 0.0:
			blast.visible = false
	autosave_t += delta
	if autosave_t >= 15.0:
		autosave_t = 0.0
		_save()
	_update_hud()


func _update_hud() -> void:
	var rank := "F" if quest_state < 3 else "E"
	hud_label.text = "Niv %d  Rang %s\nPV %d/%d   PM %d/%d\nXP %d/%d   Or %d" % [level, rank, hp, max_hp, int(mp), max_mp, xp, level * 30, gold]
	match quest_state:
		0:
			quest_label.text = "Quête : va parler à la réceptionniste de la guilde"
		1:
			quest_label.text = "Quête : éliminer des slimes (%d/3)" % kills
		2:
			quest_label.text = "Quête : retourne voir la réceptionniste"
		_:
			quest_label.text = "Quête terminée !"

	var near := _nearest_interactable()
	var ib: Panel = buttons["interact"]
	ib.visible = near != "" and not dialogue_open
	if near == "door":
		(ib.get_child(0) as Label).text = "FERMER" if door_open else "OUVRIR"
	elif near == "npc":
		(ib.get_child(0) as Label).text = "PARLER"
	for key in buttons:
		if key != "interact":
			(buttons[key] as Panel).visible = not dialogue_open


func _press(key: String) -> void:
	match key:
		"jump":
			jump_pressed = true
		"attack":
			_attack()
		"skill":
			_skill()
		"interact":
			_interact()


func _input(event: InputEvent) -> void:
	if dialogue_open:
		return
	var screen_w := get_viewport().get_visible_rect().size.x

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				_press("jump")
			KEY_F:
				_press("attack")
			KEY_Z:
				_press("skill")
			KEY_E:
				_press("interact")

	elif event is InputEventScreenTouch:
		if event.pressed:
			for key in buttons:
				var b: Panel = buttons[key]
				if b.visible and b.get_global_rect().has_point(event.position):
					_press(key)
					return
			if event.position.x < screen_w * 0.4 and joy_touch == -1:
				joy_touch = event.index
				joy_center = event.position
				joy_base.position = joy_center - joy_base.size / 2.0
				_update_joystick(event.position)
			elif look_touch == -1:
				look_touch = event.index
		else:
			if event.index == joy_touch:
				joy_touch = -1
				joy_vec = Vector2.ZERO
				joy_knob.position = joy_center - joy_knob.size / 2.0
			elif event.index == look_touch:
				look_touch = -1

	elif event is InputEventScreenDrag:
		if event.index == joy_touch:
			_update_joystick(event.position)
		elif event.index == look_touch:
			cam_pivot.rotation.y -= event.relative.x * 0.005
			cam_pivot.rotation.x = clamp(cam_pivot.rotation.x - event.relative.y * 0.005, -1.2, 0.2)


func _update_joystick(pos: Vector2) -> void:
	var d := pos - joy_center
	if d.length() > JOY_RADIUS:
		d = d.normalized() * JOY_RADIUS
	joy_vec = d / JOY_RADIUS
	joy_knob.position = joy_center + d - joy_knob.size / 2.0


# =====================  SAUVEGARDE  =====================

func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("p", "level", level)
	cfg.set_value("p", "xp", xp)
	cfg.set_value("p", "gold", gold)
	cfg.set_value("p", "max_hp", max_hp)
	cfg.set_value("p", "hp", hp)
	cfg.set_value("p", "max_mp", max_mp)
	cfg.set_value("p", "quest_state", quest_state)
	cfg.set_value("p", "kills", kills)
	cfg.set_value("p", "pos", player.position)
	cfg.save(SAVE_PATH)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	level = int(cfg.get_value("p", "level", 1))
	xp = int(cfg.get_value("p", "xp", 0))
	gold = int(cfg.get_value("p", "gold", 0))
	max_hp = int(cfg.get_value("p", "max_hp", 100))
	hp = clampi(int(cfg.get_value("p", "hp", max_hp)), 1, max_hp)
	max_mp = int(cfg.get_value("p", "max_mp", 30))
	mp = float(max_mp)
	quest_state = int(cfg.get_value("p", "quest_state", 0))
	kills = int(cfg.get_value("p", "kills", 0))
	var pos = cfg.get_value("p", "pos", SPAWN_POS)
	if pos is Vector3:
		player.position = pos
