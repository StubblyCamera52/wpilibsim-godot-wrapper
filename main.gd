extends Node3D

var socket = WebSocketPeer.new()

var initializedsocket = false

var nt_client: NT4.NT4_Client

func _ready():
	nt_client = NT4.NT4_Client.new("godot-sim", "ws://localhost:5810/nt/godotsim")
	nt_client.connect_ws()
	print(MsgPackDecoder.new().decode(PackedByteArray([82, 145, 180, 189, 45, 72, 45, 64, 218, 89, 176, 78, 118, 27, 242, 63, 30, 47, 49, 170, 21, 130, 237, 191])))
	while !nt_client.serverConnected:
		await get_tree().process_frame
	#nt_client.subscribe(["/AdvantageKit/RealOutputs/FieldSimulation/RobotPose"], false, false, 0.2)


func _process(delta):
	if !nt_client:
		return
	
	nt_client.update()
