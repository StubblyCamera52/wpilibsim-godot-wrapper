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
			root_node.transform.basis = Basis.looking_at(Vector3.UP, Vector3.FORWARD)
		else:
			push_error("Couldn't load glTF scene (error code: %s)." % error_string(error))
		
		bot.add_child(bot_model)
		print(bot_model.get_children())
	
	#nt_client = NT4.NT4_Client.new("godot-sim", "ws://localhost:5810/nt/godotsim")
	#nt_client.on_topic_announce = on_topic_announced
	#nt_client.on_new_topic_data = on_new_topic_data
	#nt_client.connect_ws()
	#while !nt_client.serverConnected:
		#await get_tree().process_frame
	#nt_client.subscribe(["/AdvantageKit/RealOutputs/FieldSimulation/RobotPose"], false, false, 0.2)
	#nt_client.subscribe(["/AdvantageKit/RealOutputs/AScope/componentPoses"], false, false, 0.2)


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
