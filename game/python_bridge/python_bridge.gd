class_name PythonBridge extends Node

signal python_client_connected

@export_group("UDP Server")
## Listen UDP port if [b]listen is true[/b]
@export var activate: bool = false:
	set(value):
		activate = value
		if server:
			set_activate(activate)

## UDP port number
@export var port : int = 4243

@export_group("Exposed functions")
## Array of nodes containing the functions exposed to a python script
@export var nodes: Array[Node]

var server := UDPServer.new()
var client_peer: PacketPeerUDP
#var _script_nodes = Array()

func _ready():
	set_activate(activate)

func _process(_delta):
	if not server.is_listening(): return
	server.poll()
	# A new client send a packet ?
	if server.is_connection_available():
		var peer: PacketPeerUDP = server.take_connection()
		client_peer = peer
#		print("Accepted peer: %s:%s on PORT %d" % [peer.get_packet_ip(), peer.get_packet_port(), port])
		python_client_connected.emit()

	if client_peer:
		var data = client_peer.get_packet()
		if not data.is_empty():
#			print(data.get_string_from_utf8())
			parse_call_from_python(client_peer, data.get_string_from_utf8())

func get_script_node(method: String) -> Node:
	for node in nodes:
		if node.has_method(method):
			return node
	return null
	
func set_activate(enable):
	if enable:
		if server.is_listening():
			server.stop()
#				print("Stop listening")
		server.listen(port)
#		print("Listen on new port %d" % port)
	else:
		server.stop()
#		print("Stop listening")
		
func parse_call_from_python(peer: PacketPeerUDP, json_message: String):
	var json = JSON.new()
	var err = json.parse(json_message)
	if err:
		printerr("parse message failed %d" % err)
		return
	var message = json.data
#	print("Message: ", message)
	if "namefunc" in message:
		var caller = get_script_node(message.namefunc)
		if caller:
			#print("method %s exits" % [message.namefunc])
			var params: Array = message.params
#			print(params)
			var args = Array()
			for p in params:
				if p.type == "float":
					args.append(p.value.to_float())
				elif p.type == "int":
					args.append(p.value.to_int())
				elif p.type == "bool":
					var value = true if p.value == "True" else false
					#print("value:" , value)
					args.append(value)
				elif p.type == "string":
					args.append(p.value)
				elif p.type == "vec3":
					var vec3 = Vector3(p.value[0], p.value[1], p.value[2])
					args.append(vec3)

			var c = Callable(caller, message.namefunc)
			#print("c: %s , args: %s" % [c, args])
			## Call function and wait a response
			var ret = await c.callv(args)
			if ret is float:
				var ret_message = {
					"type": "float",
					"value": str(ret),
					}
				peer.put_packet(JSON.stringify(ret_message).to_utf8_buffer())
			elif ret is int:
				var ret_message = {
					"type": "int",
					"value": str(ret),
					}
				peer.put_packet(JSON.stringify(ret_message).to_utf8_buffer())
			elif ret is bool:
				var ret_message = {
					"type": "bool",
					"value": str(ret),
				}
				peer.put_packet(JSON.stringify(ret_message).to_utf8_buffer())
			elif ret is Vector3:
				var vec3_value = PackedFloat32Array([ret.x, ret.y, ret.z])
				var ret_message = {
					"type": "vec3",
					"value": vec3_value,
					}
				peer.put_packet(JSON.stringify(ret_message).to_ascii_buffer())
			elif ret is PackedFloat32Array:
				var ret_message = {
					"type": "float_array",
					"value": ret,
					}
				peer.put_packet(JSON.stringify(ret_message).to_ascii_buffer())
			elif ret is Array:
				var ret_message = {
					"type": "array",
					"value": ret,
					}
				peer.put_packet(JSON.stringify(ret_message).to_utf8_buffer())
			elif ret is PackedByteArray:
				var packed_num : int = ceili(len(ret)/65507.0)
				var ret_message = {
					"type": "byte_array",
					"value": packed_num,
				}
				err = peer.put_packet(JSON.stringify(ret_message).to_utf8_buffer())
				if err:
					printerr("Error %d" % err)
					return
				for num in packed_num:
					var end : int = (num+1) * 65507
					if end > len(ret):
						end = len(ret)
					var packed_data : PackedByteArray = ret.slice(num*65507, end) 
					err = peer.put_packet(packed_data)
					print("packed %d" % num)
#					print("packed data: ", packed_data)
					if err:
						printerr("Error %d" % err)
			else:
				var ret_message = {
					"type": "null"
					}
				peer.put_packet(JSON.stringify(ret_message).to_utf8_buffer())
		else:
			var ret_message = {
					"error": "Unrecognized function name!"
					}
			peer.put_packet(JSON.stringify(ret_message).to_utf8_buffer())
