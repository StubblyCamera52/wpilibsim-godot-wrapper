extends Node3D

var socket = WebSocketPeer.new()

var initializedsocket = false

var nt_client: NT4.NT4_Client = null

var gltf_document = GLTFDocument.new()

var bot: Node3D

var bot_model: Node3D
var bot_model_zeroed_positions: Array = []
var number_of_components = 0
var bot_components: Array[Node3D] = []

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
	elif topic.name == "/AdvantageKit/RealOutputs/AScope/componentPoses":
		var poses = WPILibStructHelper.decode_struct(topic.type, value)
		on_robot_comp_move(poses)

func _ready():
	bot = $bot
	var bot_config = JSON.parse_string(FileAccess.open("/Users/gavanbess/Robot_2025/config.json", FileAccess.READ).get_as_text())
	if bot_config:
		var gltf_state = GLTFState.new()
		number_of_components = bot_config.components.size()
		var error = gltf_document.append_from_file("/Users/gavanbess/Robot_2025/model.glb", gltf_state)
		if error == OK:
			var zeroed_node3d = Node3D.new()
			zeroed_node3d.name = "root"
			var model = gltf_document.generate_scene(gltf_state)
			var actual_model: Node3D = model.get_children()[0]
			actual_model.reparent(zeroed_node3d)
			actual_model.owner = zeroed_node3d
			model.queue_free()
			#rotate model because of coordinate system differences
			#actual_model.rotation.y = PI
			#actual_model.rotation.x = -PI/2
			for i in range(bot_config.rotations.size()):
				match bot_config.rotations[i].axis:
					"x":
						actual_model.rotation.x += (deg_to_rad(bot_config.rotations[i].degrees))
					"y":
						actual_model.rotation.y += (deg_to_rad(bot_config.rotations[i].degrees))
					"z":
						actual_model.rotation.z += (deg_to_rad(bot_config.rotations[i].degrees))
			actual_model.position = Vector3(bot_config.position[0], bot_config.position[1], bot_config.position[2])
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
					var zeroed_node3d_2 = Node3D.new()
					zeroed_node3d_2.name = "root_"+str(i)
					model = gltf_document.generate_scene(gltf_state)
					var actual_model_2: Node3D = model.get_children()[0]
					actual_model_2.reparent(zeroed_node3d_2)
					actual_model_2.owner = zeroed_node3d_2
					model.queue_free()
					var zeroed_position = bot_config.components[i].zeroedPosition
					var zeroed_rotations = bot_config.components[i].zeroedRotations
					# https://docs.wpilib.org/en/stable/docs/software/basic-programming/coordinate-system.html
					# https://docs.godotengine.org/en/stable/tutorials/3d/introduction_to_3d.html#coordinate-system
					# i think godot also uses CCW as positive rotation
					#actual_model_2.rotation.y = PI
					#actual_model_2.rotation.x = -PI/2
					for j in range(zeroed_rotations.size()):
						match zeroed_rotations[j].axis:
							"x":
								actual_model_2.rotation.x += (deg_to_rad(zeroed_rotations[j].degrees))
							"y":
								actual_model_2.rotation.y += (deg_to_rad(zeroed_rotations[j].degrees))
							"z":
								actual_model_2.rotation.z += (deg_to_rad(zeroed_rotations[j].degrees))
					actual_model_2.position = Vector3(zeroed_position[0],zeroed_position[1],zeroed_position[2])
					#parent the components to the robot
					bot.add_child(zeroed_node3d_2)
					bot_components.append(zeroed_node3d_2)
			bot_model = zeroed_node3d
		else:
			push_error("Couldn't load glTF scene (error code: %s)." % error_string(error))
		
		bot.add_child(bot_model)
		print(bot_model.get_children())
	
	nt_client = NT4.NT4_Client.new("godot-sim", "ws://localhost:5810/nt/godotsim")
	nt_client.on_topic_announce = on_topic_announced
	nt_client.on_new_topic_data = on_new_topic_data
	nt_client.connect_ws()
	while !nt_client.serverConnected:
		await get_tree().process_frame
	nt_client.subscribe(["/AdvantageKit/RealOutputs/FieldSimulation/RobotPose"], false, false, 0.2)
	nt_client.subscribe(["/AdvantageKit/RealOutputs/AScope/componentPoses"], false, false, 0.2)


func _process(delta):
	if !nt_client:
		return
	
	nt_client.update()
	
func on_robot_move(data):
	print(data)
	$bot.rotation.y = data.rot
	$bot.position.x = data.x
	$bot.position.z = -data.y
	
func on_robot_comp_move(data):
	for i in range(number_of_components):
		bot_components[i].position = Vector3(data[i].x,data[i].y,data[i].z)
		bot_components[i].rotation = Vector3(data[i].roll, data[i].pitch, data[i].yaw)
