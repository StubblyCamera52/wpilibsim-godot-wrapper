class_name NT4 extends Resource

const NT4_DEFAULT_PORT: int = 5810

class NT4_SubscriptionOptions:
	var periodic = 0.1
	var all = false
	var topicsOnly = false
	var prefix = false
	func toObj():
		return {
		  "periodic": periodic,
		  "all": all,
		  "topicsonly": topicsOnly,
		  "prefix": prefix
		}

class NT4_Subscription:
	var uid: int = -1
	var topics: Array[String] = []
	var options: NT4_SubscriptionOptions = NT4_SubscriptionOptions.new()
	
	func toSubscribeObj():
		return {
		  "topics": topics, # topics.keys bc the keys will be the set
		  "subuid": uid,
		  "options": options.toObj()
		}

	func toUnsubscribeObj():
		return {
		  "subuid": uid
		}

class NT4_Topic:
	var uid = -1 # "id" if server topic, "pubuid" if published
	var name = ""
	var type = ""
	var properties: Dictionary[String, Variant] = {}

	func toPublishObj():
		return {
			"name": name,
			"type": type,
			"pubuid": uid,
			"properties": properties
		}

	func toUnpublishObj():
		return {
		  "pubuid": uid
		}


class NT4_Client:
	var rng = RandomNumberGenerator.new()
	var appName: String
	var serverAddress: String
	var ws: WebSocketPeer
	var serverConnected: bool = false
	var serverConnectionRequested: bool = false
	
	var subscriptions: Dictionary[int, NT4_Subscription] = {}
	var serverTopics: Dictionary[String, NT4_Topic] = {}
	
	func _init(appName: String, serverAddress: String) -> void:
		self.appName = appName
		self.serverAddress = serverAddress
		self.ws = WebSocketPeer.new()
	
	func connect_ws():
		if (!serverConnected):
			serverConnectionRequested = true
			ws.connect_to_url(serverAddress)
	
	func update():
		if ws != null:
			ws.poll()
			if ws.get_available_packet_count() > 0:
				var packet = ws.get_packet()
				if ws.was_string_packet():
					print(packet.get_string_from_ascii())
			if (serverConnectionRequested and !serverConnected):
				if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
					serverConnected = true
					serverConnectionRequested = false

	func subscribe(topicPatterns: Array[String], prefixMode: bool, sendAll: bool = false, periodic: float = 0.1) -> int:
		var newSub = NT4_Subscription.new()
		newSub.uid = getNewUID()
		newSub.topics = topicPatterns
		newSub.options.prefix = prefixMode
		newSub.options.all = sendAll
		newSub.options.periodic = periodic

		subscriptions.set(newSub.uid, newSub)
		if (serverConnected):
			var payload = JSON.stringify([{"method": "subscribe", "params": newSub.toSubscribeObj()}])
			ws.send_text(payload)

		return newSub.uid

	func getNewUID():
		return rng.randi_range(1, 999999999)
