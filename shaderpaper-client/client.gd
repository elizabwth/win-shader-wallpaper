extends Node

var shaders = []

onready var timescale_label = get_node("Control/Panel/MarginContainer/VBoxContainer/GridContainer/timescale_label")

# Called when the node enters the scene tree for the first time.
func _ready():
	self.start_client()

func start_client():
	var SERVER_IP = "127.0.0.1"
	var SERVER_PORT = 8010
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(SERVER_IP, SERVER_PORT)
	get_tree().network_peer = peer
	get_tree().connect("connected_to_server", self, "_connection_succeeded")

func _connection_succeeded():
	print("i'm connected!")
	rpc_unreliable("get_shaders")
	
remote func get_shaders(x):
	shaders = x
	for i in len(shaders):
		var shader = shaders[i]
		var shader_select = get_node("Control/Panel/MarginContainer/VBoxContainer/GridContainer/shader_select")
		shader_select.add_item(shader, i)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_shader_select_item_selected(index):
	rpc_unreliable("set_shader", index)

func _on_timescale_slider_value_changed(value):
	rpc_unreliable("set_timescale", value)
	timescale_label.set_text("Timescale " + str(value))

func _on_close_pressed():
	rpc_unreliable("close")
