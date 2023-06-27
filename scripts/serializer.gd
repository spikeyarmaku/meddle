class_name Serializer

# TODO use StreamPeerBuffer
var _stream_peer : StreamPeer

var _word_size : int = 8 # How many bytes is a word

func from_bytes(bytes = PackedByteArray([]), little_endian : bool = true) -> void:
	_stream_peer = StreamPeerBuffer.new()
	_stream_peer.big_endian = not little_endian
	_stream_peer.data_array = bytes

func from_network(connection : StreamPeerTCP):
	_stream_peer = connection

func read_word_size():
	_word_size = _stream_peer.get_u8()
	
func set_word_size(word_size : int):
	_word_size = word_size

func feed_bytes(bytes : PackedByteArray) -> void:
	_stream_peer.put_data(bytes)

func has_finished() -> bool:
	return _stream_peer.get_available_bytes() == 0

func read_bytes(count : int = 0):
	return _stream_peer.get_data(count)

func read_rest() -> PackedByteArray:
	var arr = _stream_peer.get_data(_stream_peer.get_available_bytes())
	return arr[1]

func read_int8() -> int:
	return _stream_peer.get_8()
	
func read_int16() -> int:
	return _stream_peer.get_16()
	
func read_uint8() -> int:
	return _stream_peer.get_u8()
	
func read_uint16() -> int:
	return _stream_peer.get_u16()

func read_uint32() -> int:
	return _stream_peer.get_u32()

func read_uint64() -> int:
	return _stream_peer.get_u64()
	
func read_word() -> int:
	var bytes = _stream_peer.get_data(_word_size)[1]
	if _stream_peer.big_endian == true:
		var num : int = 0
		const base : int = 256
		for b in bytes:
			num += b
			num *= base
		return num
	else:
		var num : int = 0
		var factor : int = 1
		const base : int = 256
		for b in bytes:
			num += factor * b
			factor *= base
		return num

func read_float() -> float:
	return Serializer._read_float(_stream_peer.get_data(4)[1])

func read_null_terminated_string() -> String:
	var bytes : PackedByteArray = PackedByteArray([])
	var byte : int = read_uint8()
	while byte != 0:
		bytes.append(byte)
		byte = read_uint8()
	return Serializer._read_as_string(bytes)

# TODO `msg.to_ascii()` doesn't work in Godot 3.3.3 due to a bug in String that
# sometimes crashes when a string is converted to ascii or utf8.
# See https://github.com/godotengine/godot/issues/40957
# Temporarily reverting the fix to see if it happens in Godot 4 as well
func write_string(msg : String):
	var buf = msg.to_ascii_buffer()
	_stream_peer.put_data(buf)
#	var arr = []
#	for c in msg:
#		arr.append(ord(c))
#	var lng = write_uint64_le(msg.length())
#	lng.append_array(PackedByteArray(arr))
#	return lng
	
# instead of read_string, just use PackedByteArray.get_string_from_ascii()

# -------------
# Raw functions
# -------------

# Workaround for the binary serialization API
# https://docs.godotengine.org/en/stable/tutorials/misc/binary_serialization_api.html
# print(Serializer.read_float([195, 245, 72, 64])) outputs 3.14
static func _read_float(bytes):
	var arr = PackedByteArray([3, 0, 0, 0])
	arr.append_array(bytes)
	return bytes_to_var(arr)

static func _read_as_string(bytes) -> String:
	return bytes.get_string_from_ascii()

static func write_uint8_be(num) -> PackedByteArray:
	var arr = var_to_bytes(num).slice(4, -5)
	arr.invert()
	return arr

static func write_uint16_be(num) -> PackedByteArray:
	var arr = write_uint16_le(num)
	arr.invert()
	return arr

static func write_uint16_le(num) -> PackedByteArray:
	var arr = var_to_bytes(num).slice(4, -3)
	return arr

static func write_uint32_be(num) -> PackedByteArray:
	var arr = var_to_bytes(num).slice(4, -1)
	return arr

static func write_uint32_le(num) -> PackedByteArray:
	var arr = write_uint32_be(num)
	arr.invert()
	return arr

static func write_float(f : float) -> PackedByteArray:
	var arr = var_to_bytes(f).slice(4, -1)
	arr.invert()
	return arr

static func write_uint64_le(num) -> PackedByteArray:
	var arr1 = write_uint32_le(0)
	var arr2 = write_uint32_le(num)
	arr1.append_array(arr2)
	return arr1
