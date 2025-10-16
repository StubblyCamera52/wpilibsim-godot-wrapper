class_name WPILibStructHelper extends Resource

static func decode_struct(type: String, data: PackedByteArray) -> Variant:
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
		"Pose3d[]":
			var poses: Array = []
			for i in range(data.size()/(8*6)): # 8 bytes per float, 6 floats per pose3d
				poses.append({
					"x": data.decode_double(64*i),
					"y": data.decode_double(8+64*i),
					"z": data.decode_double(16+64*i),
					"roll": data.decode_double(24+64*i),
					"pitch": data.decode_double(32+64*i),
					"yaw": data.decode_double(48+64*i),
				})
			return poses
			
		_:
			push_warning("unknown struct: " + type)
			return null
