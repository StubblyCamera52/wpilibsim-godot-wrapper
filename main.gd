extends Node3D

var socket = WebSocketPeer.new()

var initializedsocket = false


func _ready():
	socket.connect_to_url("ws://localhost:5810/nt/godotsim")


func _process(delta):
	socket.poll()
	var state = socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		if !initializedsocket:
			initializedsocket = true
			socket.send_text(JSON.stringify([{ "method": "subscribe", "params": {"topics": ["/AdvantageKit/RealOutputs/FieldSimulation/RobotPose"], "subuid": 474, "options": {"periodic": 0.1, "all": false, "topicsonly": false, "prefix": false}} }]))
		while socket.get_available_packet_count():
			var packet = socket.get_packet()
			if socket.was_string_packet():
				print(packet.get_string_from_ascii())
	elif state == WebSocketPeer.STATE_CLOSING:
		# Keep polling to achieve proper close.
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = socket.get_close_code()
		var reason = socket.get_close_reason()
		print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		set_process(false) # Stop processing.
