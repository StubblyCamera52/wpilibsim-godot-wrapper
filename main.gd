extends Node3D

var socket = WebSocketPeer.new()

var initializedsocket = false

var nt_client: NT4.NT4_Client = null

@onready var bot: Node3D = $bot

var bot_model: Array[Node3D] = []
var bot_model_zeroed_positions: Array = []

var gltf_document_load = GLTFDocument.new()
var gltf_state_load = GLTFState.new()

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
	var bot_config = JSON.parse_string(FileAccess.open("/Users/gavanbess/3681-sim/models/Robot_2025/config.json", FileAccess.READ).get_as_text())
	if bot_config:
		var error = gltf_document_load.append_from_file("/Users/gavanbess/3681-sim/models/Robot_2025/model.glb", gltf_state_load)
		if error == OK:
			bot_model.append(gltf_document_load.generate_scene(gltf_state_load))
			bot_model[0].position = Vector3(bot_config.position[0], bot_config.position[1], bot_config.position[2])
			for i in range(bot_config.rotations.size()):
				match bot_config.rotations[i].axis:
					"x":
						pass
					"y":
						pass
					"z":
						pass
			bot.add_child(bot_model[0])
		else:
			push_error("Couldn't load glTF scene (error code: %s)." % error_string(error))
	
	#nt_client = NT4.NT4_Client.new("godot-sim", "ws://localhost:5810/nt/godotsim")
	#nt_client.on_topic_announce = on_topic_announced
	#nt_client.on_new_topic_data = on_new_topic_data
	#nt_client.connect_ws()
	#while !nt_client.serverConnected:
		#await get_tree().process_frame
	#nt_client.subscribe(["/AdvantageKit/RealOutputs/FieldSimulation/RobotPose"], false, false, 0.05)
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
