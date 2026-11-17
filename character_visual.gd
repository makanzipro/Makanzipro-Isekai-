
extends Node3D

@export var coat_color: Color = Color(0.12, 0.25, 0.65)

var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var torso: Node3D
var head: Node3D

var anim_time := 0.0
var move_speed := 0.0
var in_air := false
var attack_timer := 0.0
var skill_timer := 0.0

func _ready() -> void:
    _build_humanoid()

func _material(color: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = 0.8
    return m

func _part(parent: Node3D, mesh: Mesh, pos: Vector3, color: Color) -> MeshInstance3D:
    var instance := MeshInstance3D.new()
    instance.mesh = mesh
    instance.position = pos
    instance.material_override = _material(color)
    parent.add_child(instance)
    return instance

func _capsule(parent: Node3D, radius: float, height: float, pos: Vector3, color: Color) -> void:
    var mesh := CapsuleMesh.new()
    mesh.radius = radius
    mesh.height = height
    _part(parent, mesh, pos, color)

func _build_humanoid() -> void:
    var skin := Color(0.92, 0.68, 0.52)
    var hair := Color(0.16, 0.09, 0.06)
    var trousers := Color(0.12, 0.15, 0.28)
    var shoes := Color(0.12, 0.08, 0.06)

    # CORPS
    torso = Node3D.new()
    torso.position.y = 1.12
    add_child(torso)

    var chest := BoxMesh.new()
    chest.size = Vector3(0.62, 0.76, 0.38)
    _part(torso, chest, Vector3.ZERO, coat_color)

    var shirt := BoxMesh.new()
    shirt.size = Vector3(0.24, 0.55, 0.035)
    _part(torso, shirt, Vector3(0, 0, -0.205), Color.WHITE)

    var belt := BoxMesh.new()
    belt.size = Vector3(0.64, 0.10, 0.4)
    _part(torso, belt, Vector3(0, -0.30, 0), Color(0.3, 0.16, 0.07))

    # TETE
    head = Node3D.new()
    head.position = Vector3(0, 0.60, 0)
    torso.add_child(head)

    var face := SphereMesh.new()
    face.radius = 0.27
    face.height = 0.54
    _part(head, face, Vector3(0, 0.12, 0), skin)

    var hair_mesh := SphereMesh.new()
    hair_mesh.radius = 0.29
    hair_mesh.height = 0.34
    _part(head, hair_mesh, Vector3(0, 0.31, 0.025), hair)

    # YEUX
    for x in [-0.09, 0.09]:
        var eye := SphereMesh.new()
        eye.radius = 0.035
        eye.height = 0.07
        _part(head, eye, Vector3(x, 0.13, -0.245), Color(0.04, 0.03, 0.02))

    # BRAS
    left_arm = Node3D.new()
    left_arm.position = Vector3(-0.39, 0.30, 0)
    torso.add_child(left_arm)
    _capsule(left_arm, 0.12, 0.68, Vector3(0, -0.32, 0), coat_color)
    _make_hand(left_arm, skin)

    right_arm = Node3D.new()
    right_arm.position = Vector3(0.39, 0.30, 0)
    torso.add_child(right_arm)
    _capsule(right_arm, 0.12, 0.68, Vector3(0, -0.32, 0), coat_color)
    _make_hand(right_arm, skin)

    # JAMBES
    left_leg = Node3D.new()
    left_leg.position = Vector3(-0.18, -0.42, 0)
    torso.add_child(left_leg)
    _capsule(left_leg, 0.14, 0.76, Vector3(0, -0.34, 0), trousers)
    _make_shoe(left_leg, shoes)

    right_leg = Node3D.new()
    right_leg.position = Vector3(0.18, -0.42, 0)
    torso.add_child(right_leg)
    _capsule(right_leg, 0.14, 0.76, Vector3(0, -0.34, 0), trousers)
    _make_shoe(right_leg, shoes)

func _make_hand(parent: Node3D, skin: Color) -> void:
    var hand := SphereMesh.new()
    hand.radius = 0.105
    hand.height = 0.19
    _part(parent, hand, Vector3(0, -0.67, 0), skin)

func _make_shoe(parent: Node3D, color: Color) -> void:
    var shoe := BoxMesh.new()
    shoe.size = Vector3(0.30, 0.16, 0.40)
    _part(parent, shoe, Vector3(0, -0.72, -0.06), color)

func set_motion(speed: float, airborne: bool) -> void:
    move_speed = speed
    in_air = airborne

func play_attack() -> void:
    attack_timer = 0.38

func play_skill() -> void:
    skill_timer = 0.65

func _process(delta: float) -> void:
    anim_time += delta

    attack_timer = maxf(attack_timer - delta, 0.0)
    skill_timer = maxf(skill_timer - delta, 0.0)

    var wave := sin(anim_time * 9.0)
    var idle := sin(anim_time * 2.0)

    # REPOS
    var arm_l := 0.04 + idle * 0.025
    var arm_r := -0.04 - idle * 0.025
    var leg_l := 0.0
    var leg_r := 0.0

    # MARCHE ET COURSE
    if move_speed > 0.3 and not in_air:
        var intensity := 0.48 if move_speed < 4.5 else 0.85
        var frequency := 7.0 if move_speed < 4.5 else 11.0
        var movement := sin(anim_time * frequency) * intensity

        leg_l = movement
        leg_r = -movement
        arm_l = -movement * 0.7
        arm_r = movement * 0.7

    # SAUT
    if in_air:
        arm_l = -0.65
        arm_r = -0.65
        leg_l = 0.35
        leg_r = -0.35

    # ATTAQUE
    if attack_timer > 0.0:
        var progress := 1.0 - attack_timer / 0.38
        arm_r = -1.2 + progress * 2.6
        leg_l = -0.12
        torso.rotation.x = -0.12 + progress * 0.25
    else:
        torso.rotation.x = 0.0

    # MAGIE
    if skill_timer > 0.0:
        arm_l = -1.8
        arm_r = -1.8

    left_arm.rotation.x = arm_l
    right_arm.rotation.x = arm_r
    left_leg.rotation.x = leg_l
    right_leg.rotation.x = leg_r

    # RESPIRATION
    torso.position.y = 1.12 + idle * 0.018
