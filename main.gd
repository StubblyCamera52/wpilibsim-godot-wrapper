extends Node3D

var socket = WebSocketPeer.new()

var initializedsocket = false

var nt_client: NT4.NT4_Client

func _ready():
	nt_client = NT4.NT4_Client.new("godot-sim", "ws://localhost:5810/nt/godotsim")
	nt_client.connect_ws()
	while !nt_client.serverConnected:
		await get_tree().process_frame
	nt_client.subscribe(["/AdvantageKit/RealOutputs/simulatedVoltage"], false, false, 0.2)


func _process(delta):
	if !nt_client:
		return
	
	nt_client.update()
