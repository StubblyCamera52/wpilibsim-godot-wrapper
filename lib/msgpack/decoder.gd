class_name MsgPackDecoder extends Resource

# im gonna have ot use bitwise for this arent i

# types from the msgpack spec:
# bin means byte array
# str is also a byte array but interpreted as a string


#format name     | first byte (in binary) | first byte (in hex)
#--------------- | ---------------------- | -------------------
#positive fixint | 0xxxxxxx               | 0x00 - 0x7f
#fixmap          | 1000xxxx               | 0x80 - 0x8f
#fixarray        | 1001xxxx               | 0x90 - 0x9f
#fixstr          | 101xxxxx               | 0xa0 - 0xbf
#nil             | 11000000               | 0xc0
#(never used)    | 11000001               | 0xc1
#false           | 11000010               | 0xc2
#true            | 11000011               | 0xc3
#bin 8           | 11000100               | 0xc4
#bin 16          | 11000101               | 0xc5
#bin 32          | 11000110               | 0xc6
#ext 8           | 11000111               | 0xc7
#ext 16          | 11001000               | 0xc8
#ext 32          | 11001001               | 0xc9
#float 32        | 11001010               | 0xca
#float 64        | 11001011               | 0xcb
#uint 8          | 11001100               | 0xcc
#uint 16         | 11001101               | 0xcd
#uint 32         | 11001110               | 0xce
#uint 64         | 11001111               | 0xcf
#int 8           | 11010000               | 0xd0
#int 16          | 11010001               | 0xd1
#int 32          | 11010010               | 0xd2
#int 64          | 11010011               | 0xd3
#fixext 1        | 11010100               | 0xd4
#fixext 2        | 11010101               | 0xd5
#fixext 4        | 11010110               | 0xd6
#fixext 8        | 11010111               | 0xd7
#fixext 16       | 11011000               | 0xd8
#str 8           | 11011001               | 0xd9
#str 16          | 11011010               | 0xda
#str 32          | 11011011               | 0xdb
#array 16        | 11011100               | 0xdc
#array 32        | 11011101               | 0xdd
#map 16          | 11011110               | 0xde
#map 32          | 11011111               | 0xdf
#negative fixint | 111xxxxx               | 0xe0 - 0xff

# first one im going to try is the Pose2D struct - a fixarray of 2

# i figured out abetter way to do this than the switch statements

var example_data = PackedByteArray([148, 205, 4, 191, 206, 11, 250, 171, 78, 1, 203, 64, 38, 24, 191, 130, 188, 15, 146])

var _buffer: StreamPeerBuffer
var _decoder_function_map: Dictionary = {}

func _init() -> void:
	_buffer = StreamPeerBuffer.new()
	_generate_decoder_function_map()

# this is the dict of lambda functions for decoding the bytes of msgpack
func _generate_decoder_function_map() -> void:
	_decoder_function_map = {
		# bool formats
		0xC0: func(): return null,
		0xC2: func(): return false,
		0xC3: func(): return true,
		# byte array format
		0xC4: func(): return _read_byte_array(_buffer.get_u8()),
		0xC5: func(): return _read_byte_array(_buffer.get_u16()),
		0xC6: func(): return _read_byte_array(_buffer.get_u32()),
		# ext - yeah im not implementing this rn
		0xC7: func(): return null,
		0xC8: func(): return null,
		0xC9: func(): return null,
		# floats
		0xCA: func(): return _buffer.get_float(),
		0xCB: func(): return _buffer.get_double(),
		# unsigned ints
		0xCC: func(): return _buffer.get_u8(),
		0xCD: func(): return _buffer.get_u16(),
		0xCE: func(): return _buffer.get_u32(),
		0xCF: func(): return _buffer.get_u64(),
		# signed ints
		0xD0: func(): return _buffer.get_8(),
		0xD1: func(): return _buffer.get_16(),
		0xD2: func(): return _buffer.get_32(),
		0xD3: func(): return _buffer.get_64(),
		# fixext - yeah im not doing this rn either
		0xD4: func(): return null,
		0xD5: func(): return null,
		0xD6: func(): return null,
		0xD7: func(): return null,
		0xD8: func(): return null,
		# str
		0xD9: func(): return _read_byte_array(_buffer.get_u8()).get_string_from_ascii(),
		0xDA: func(): return _read_byte_array(_buffer.get_u16()).get_string_from_ascii(),
		0xDB: func(): return _read_byte_array(_buffer.get_u32()).get_string_from_ascii(),
		# array
		0xDC: func(): return _decode_array(_buffer.get_u16()),
		0xDD: func(): return _decode_array(_buffer.get_u32()),
		# map - not rn
	}
	# these functions add more decoders because these types have the number of elements in their type byte.
	# positive fixint
	for i in range(0x00, 0x80):
		_decoder_function_map[i] = func(i=i): return i
	# fixarray
	for i in range(0x90, 0xA0):
		_decoder_function_map[i] = func(i=i): return _decode_array(i-0x90) # subtract 0x90 to remove the type bits and get only the length of the array

func _read_byte_array(length: int) -> PackedByteArray:
	if length <= 0:
		return []
	return _buffer.get_data(length)[1] # the get data function returns two values and we dont care about the errors

func _decode_array(length: int) -> Array:
	var elements: Array = []
	for i in length:
		elements.append(_decode_value())
	return elements

func _decode_value() -> Variant:
	var type_byte: int = _buffer.get_u8()
	return _decoder_function_map[type_byte].call()

func decode(data: PackedByteArray) -> Variant:
	_buffer.data_array = data
	var decoded_data: Array = []
	while _buffer.get_position() < _buffer.get_size():
		var value = _decode_value()
		decoded_data.append(value)
	return decoded_data
