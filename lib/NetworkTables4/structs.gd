class_name WPILibStructHelper extends Resource

static func decode_struct(type: String, data: PackedByteArray) -> Variant:
	match type:
		#struct of 3 doubles
		"struct:Pose2d":
			return {
				"x": data.decode_double(0),
				"y": data.decode_double(8),
				"rot": data.decode_double(16)
			}
		"struct:Pose3d":
			return {
				"x": data.decode_double(0),
				"y": data.decode_double(8),
				"z": data.decode_double(16),
				"w": data.decode_double(24),
				"qx": data.decode_double(32),
				"qy": data.decode_double(40),
				"qz": data.decode_double(48),
			}
		"struct:Pose3d[]":
			var poses: Array = []
			for i in range(data.size()/(8*6)): # 8 bytes per float, 7 floats per pose3d
				poses.append({
					"x": data.decode_double(56*i),
					"y": data.decode_double(8+56*i),
					"z": data.decode_double(16+56*i),
					"w": data.decode_double(24+56*i),
					"qx": data.decode_double(32+56*i),
					"qy": data.decode_double(40+56*i),
					"qz": data.decode_double(48+56*i),
				})
			return poses
			
		_:
			push_warning("unknown struct: " + type)
			return null
