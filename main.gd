extends Node3D

var socket = WebSocketPeer.new()

var initializedsocket = false

var nt_client: NT4.NT4_Client

func _ready():
	nt_client = NT4.NT4_Client.new("godot-sim", "ws://localhost:5810/nt/godotsim")

func _process(delta):
	if !nt_client:
		return
	
	nt_client.update()
