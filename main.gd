extends Node3D

var socket = WebSocketPeer.new()

var initializedsocket = false

var nt_client: NT4.NT4_Client

@onready var botComponents = []

func on_topic_announced(topic: NT4.NT4_Topic):
	pass

func on_new_topic_data(topic: NT4.NT4_Topic, timestamp_us: int, value: Variant):
	print("data")
	if topic.name == "/AdvantageKit/RealOutputs/FieldSimulation/RobotPose":
		print("movebot")
		print(value)
		var pose = WPILibStructHelper.decode_struct(topic.type, value)
		print(pose)
		on_robot_move(pose)

func _ready():
	nt_client = NT4.NT4_Client.new("godot-sim", "ws://localhost:5810/nt/godotsim")
	nt_client.on_topic_announce = on_topic_announced
	nt_client.on_new_topic_data = on_new_topic_data
	nt_client.connect_ws()
	while !nt_client.serverConnected:
		await get_tree().process_frame
	nt_client.subscribe(["/AdvantageKit/RealOutputs/FieldSimulation/RobotPose"], false, false, 0.05)
	#nt_client.subscribe(["/AdvantageKit/RealOutputs/AScope/componentPoses"], false, false, 0.05)
	

func _process(delta):
	if !nt_client:
		return
	
	nt_client.update()
	
func on_robot_move(data):
	if data[0][3] != null:
		$bot.rotation.y = data[0][3]["rot"]
		$bot.position.x = data[0][3]["x"]
		$bot.position.z = -data[0][3]["y"]
