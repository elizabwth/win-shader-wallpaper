extends Panel
const helpers = preload("res://scripts/helpers.gd")

var time = 0

var shaders = []
var timescale = 1

func _load_shaders():
	var dir = Directory.new()
	dir.open("res://shaders")
	dir.list_dir_begin(true)
	var shader = dir.get_next()
	while shader != "":
		shaders.append(load("res://shaders/" + shader))
		shader = dir.get_next()

func _ready():
	# set_process(true)
	_load_shaders()

func _process(delta):
	var mouse = get_global_mouse_position()
	var screen = get_viewport().get_viewport().size
	mouse.x /= screen.x
	mouse.y /= -screen.y
	self.material.set_shader_param("mouse", mouse)
	self.material.set_shader_param("time", time)
	time += delta * timescale
	pass
	
remote func set_shader(index):
	self.material.shader = shaders[index]

remote func set_timescale(value):
	timescale = value
