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
	#print("data")
	if topic.name == "/AdvantageKit/RealOutputs/FieldSimulation/RobotPose":
		#print("movebot")
		#print(value)
		var pose = WPILibStructHelper.decode_struct(topic.type, value)
		#print(pose)
		#on_robot_move(pose)
	elif topic.name == "/AdvantageKit/RealOutputs/AScope/componentPoses":
		print(value)
		var poses = WPILibStructHelper.decode_struct(topic.type, value)
		print(poses)
		on_robot_comp_move(poses)

func _ready():
	bot = $bot
	var bot_config = JSON.parse_string(FileAccess.open("/Users/gavanbess/Robot_2025/config.json", FileAccess.READ).get_as_text())
	if bot_config:
		var gltf_state = GLTFState.new()
		number_of_components = bot_config.components.size()
		var error = gltf_document.append_from_file("/Users/gavanbess/Robot_2025/model.glb", gltf_state)
		if error == OK:
			var model = gltf_document.generate_scene(gltf_state)
			var root_node = Node3D.new()
			bot_model = root_node
			bot_model.add_child(model)
			for r in bot_config.rotations:
				match r.axis:
					"x":
						root_node.rotate_x(deg_to_rad(r.degrees))
					"y":
						root_node.rotate_y(deg_to_rad(r.degrees))
					"z":
						root_node.rotate_z(deg_to_rad(r.degrees))
			root_node.transform.origin = Vector3(bot_config.position[0], bot_config.position[1], bot_config.position[2])
			#root_node.transform.basis = Basis.looking_at(Vector3.UP, Vector3.BACK)
			var count = 0
			for c in bot_config.components:
				gltf_state = GLTFState.new()
				error = gltf_document.append_from_file("/Users/gavanbess/Robot_2025/model_"+str(count)+".glb", gltf_state)
				count += 1
				if error == OK:
					var component_root_node = Node3D.new()
					var component_model = gltf_document.generate_scene(gltf_state)
					component_root_node.add_child(component_model)
					for r in c.zeroedRotations:
						match r.axis:
							"x":
								component_root_node.rotate_x(deg_to_rad(r.degrees))
							"y":
								component_root_node.rotate_y(deg_to_rad(r.degrees))
							"z":
								component_root_node.rotate_z(deg_to_rad(r.degrees))
					component_root_node.transform.origin = Vector3(c.zeroedPosition[0],c.zeroedPosition[1],c.zeroedPosition[2])
					var positioner_node = Node3D.new()
					positioner_node.add_child(component_root_node)
					bot_components.append(positioner_node)
		else:
			push_error("Couldn't load glTF scene (error code: %s)." % error_string(error))
		
		bot.add_child(bot_model)
		var count = 0
		for c in bot_components:
			bot.add_child(c)
		print(bot_model.get_children())
		bot.transform.basis = Basis.looking_at(Vector3.DOWN, Vector3.BACK)
	
	nt_client = NT4.NT4_Client.new("godot-sim", "ws://localhost:5810/nt/godotsim")
	nt_client.on_topic_announce = on_topic_announced
	nt_client.on_new_topic_data = on_new_topic_data
	nt_client.connect_ws()
	while !nt_client.serverConnected:
		await get_tree().process_frame
	nt_client.subscribe(["/AdvantageKit/RealOutputs/FieldSimulation/RobotPose"], false, false, 0.02)
	nt_client.subscribe(["/AdvantageKit/RealOutputs/AScope/componentPoses"], false, false, 0.02)


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
		bot_components[i].transform.basis = Basis(Quaternion(data[i].qx,data[i].qy,data[i].qz,data[i].w))
