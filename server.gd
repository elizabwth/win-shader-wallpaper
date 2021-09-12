extends Node
const helpers = preload("res://scripts/helpers.gd")

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var shader_node = get_node("main/margin/shader")

func _start_server():
	var SERVER_PORT = 8010
	var MAX_PLAYERS = 5
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(SERVER_PORT, MAX_PLAYERS)
	get_tree().network_peer = peer
	get_tree().connect("network_peer_connected", self, "_client_connected")
	pass
	
func _client_connected(id):
	print("client connected with id = " + str(id))
	
remote func get_shaders():
	rpc_unreliable("get_shaders", helpers.list_files_in_directory("res://shaders"))

remote func set_shader(index):
	shader_node.set_shader(index)

remote func set_timescale(value):
	shader_node.set_timescale(value)
	
remote func close():
	get_tree().quit()

# Called when the node enters the scene tree for the first time.
func _ready():
	_start_server()
	pass # Replace with function body.
