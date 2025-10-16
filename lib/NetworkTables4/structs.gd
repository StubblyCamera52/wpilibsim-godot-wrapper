class_name WPILibStructHelper extends Resource

static func decode_struct(type: String, data: PackedByteArray):
	match type:
		#struct of 3 doubles
		"Pose2d":
			return {
				"x": data.decode_double(0),
				"y": data.decode_double(8),
				"rot": data.decode_double(16)
			}
		"Pose3d":
			return {
				"x": data.decode_double(0),
				"y": data.decode_double(8),
				"z": data.decode_double(16),
				"roll": data.decode_double(24),
				"pitch": data.decode_double(32),
				"yaw": data.decode_double(48),
			}
		_:
			push_warning("unknown struct: " + type)
			return null
