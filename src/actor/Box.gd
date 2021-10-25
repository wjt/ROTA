tool
extends KinematicBody2D
class_name Box

onready var collision_shape : CollisionShape2D = $CollisionShape2D
onready var standing_area : Area2D = $StandingArea
onready var sprite : Sprite = $Sprite
onready var arrow : Sprite = $Sprite/Arrow
onready var collision_sprite : CollisionShape2D = $Area2D/CollisionSprite
onready var audio_push : AudioStreamPlayer2D = $AudioPush

export var dir := 0 setget set_dir

var tile := 100.0
var is_floor := false
var move_clock := 0.0
export var move_time := 0.4
onready var last_pos := position
var move_weight := 5.0

var arrow_weight := 6.0
var arrow_angle := 0.0

func _ready():
	set_dir()
	arrow.rotation_degrees = arrow_angle

func rot(arg : Vector2, backwards := false):
	return arg.rotated(deg2rad((-dir if backwards else dir) * 90))

func set_dir(arg := dir):
	dir = 3 if arg < 0 else (arg % 4)
	arrow_angle = dir * 90
	if Engine.editor_hint:
		if !arrow: arrow = $Sprite/Arrow
		arrow.rotation_degrees = dir * 90

func spinner(right := false):
	set_dir(dir + (1 if right else 3))

func arrow(arg):
	if arg != dir:
		set_dir(arg)

func portal(pos):
	position = pos
	sprite.position = Vector2.ZERO

#func _input(event):
#	if event is InputEventKey and event.pressed:
#		if event.scancode == KEY_Q:
#			set_dir(dir - 1)
#		elif event.scancode == KEY_E:
#			set_dir(dir + 1)

func push(right := false):
	move(Vector2(1 if right else -1, 0))
	if position != last_pos:
		audio_push.play()

func move(vector := Vector2.ZERO):
	shrink_shape()
	# is space open
	if !test_move(transform, rot(vector) * tile):
		move_and_collide(rot(vector) * tile)
		# keep box on grid (:
		var step = Vector2(stepify(position.x, 50), stepify(position.y, 50)) - position
		if step != Vector2.ZERO:
			move_and_collide(step)
		
		# move sprite
		sprite.position -= position - last_pos
		
		# jump player
		for i in standing_area.get_overlapping_bodies():
			if i.is_in_group("player"):
				i.has_jumped = true
		print(name + ".position: ", position, " stepify: ", step)
	shrink_shape(false)

func shrink_shape(shrink := true):
	collision_shape.shape.extents = Vector2(49, 49) if shrink else Vector2(50, 50)

func _physics_process(delta):
	if Engine.editor_hint: return
	last_pos = position
	
	# on floor
	shrink_shape()
	is_floor = test_move(transform, rot(Vector2(0, tile)))
	shrink_shape(false)
	
	# move down
	if !is_floor:
		move_clock -= delta
		if move_clock < 0:
			move_clock = move_time
			move(Vector2(0, 1))
	
	# lerp sprite
	sprite.position = sprite.position.linear_interpolate(Vector2.ZERO, delta * move_weight)
	# update collision_sprite
	collision_sprite.position = sprite.position
	
	# lerp arrow
	arrow.rotation = lerp_angle(arrow.rotation, deg2rad(arrow_angle), delta * arrow_weight)
	
