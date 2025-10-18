extends Node3D

var socket = WebSocketPeer.new()

var initializedsocket = false

var nt_client: NT4.NT4_Client = null

var gltf_document = GLTFDocument.new()

@onready var bot: Node3D = $bot

var bot_model: Array[Node3D] = []
var bot_model_zeroed_positions: Array = []
var number_of_components = 0

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
	var bot_config = JSON.parse_string(FileAccess.open("/Users/gavanbess/Robot_2025/config.json", FileAccess.READ).get_as_text())
	if bot_config:
		var gltf_state = GLTFState.new()
		number_of_components = bot_config.components.size()
		var error = gltf_document.append_from_file("/Users/gavanbess/Robot_2025/model.glb", gltf_state)
		if error == OK:
			var zeroed_node3d = Node3D.new()
			zeroed_node3d.name = "root"
			var model = gltf_document.generate_scene(gltf_state)
			zeroed_node3d.add_child(model)
			model.position = Vector3(bot_config.position[0], bot_config.position[1], bot_config.position[2])
			for i in range(bot_config.rotations.size()):
				match bot_config.rotations[i].axis:
					"x":
						zeroed_node3d.rotation_degrees.x = bot_config.rotations[i].degrees
					"y":
						zeroed_node3d.rotation_degrees.y = bot_config.rotations[i].degrees
					"z":
						zeroed_node3d.rotation_degrees.z = bot_config.rotations[i].degrees
			bot_model.append(zeroed_node3d)
			# now for the components
			#{
				#"zeroedRotations": [
					#{ "axis": "z" , "degrees": -90 },
					#{ "axis": "y" , "degrees": 180 }
				#],
				#"zeroedPosition": [0.085, 0.135, 0.1195]
			#},
			for i in range(bot_config.components.size()):
				gltf_state = GLTFState.new()
				error = gltf_document.append_from_file("/Users/gavanbess/Robot_2025/model_"+str(i)+".glb", gltf_state)
				if error == OK:
					zeroed_node3d = Node3D.new()
					zeroed_node3d.name = "root_"+str(i)
					model = gltf_document.generate_scene(gltf_state)
					zeroed_node3d.add_child(model)
					var zeroed_position = bot_config.components[i].zeroedPosition
					var zeroed_rotations = bot_config.components[i].zeroedRotations
					model.position = Vector3(zeroed_position[0],zeroed_position[1],zeroed_position[2])
					for j in range(zeroed_rotations.size()):
						match zeroed_rotations[j].axis:
							"x":
								zeroed_node3d.rotation_degrees.x = zeroed_rotations[j].degrees
							"y":
								zeroed_node3d.rotation_degrees.y = zeroed_rotations[j].degrees
							"z":
								zeroed_node3d.rotation_degrees.z = zeroed_rotations[j].degrees
					bot_model.append(zeroed_node3d)
		else:
			push_error("Couldn't load glTF scene (error code: %s)." % error_string(error))
		
		for i in range(bot_model.size()):
			bot.add_child(bot_model[i])
	
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
