class_name PythonBridge
extends Node

signal python_client_connected

@export_group("UDP Server")
## Activate listening
@export var activate: bool = false:
	set(value):
		activate = value
		if activate:
			if server.is_listening():
				server.stop()
				print("Stop listening")
			server.listen(port)
			print("Listen on new port %d" % port)
		else:
			server.stop()
			print("Stop listening")
## Number port listening
@export_range(1024, 65535) var port = 4242

var server := UDPServer.new()
var client_peer: PacketPeerUDP

func _enter_tree() -> void:
	assert(name == &"PythonBridge", "PythonBridge node cannot be renamed!")

func _process(_delta):
	if not server.is_listening(): return
	server.poll()
	# A new client send a packet ?
	if server.is_connection_available():
		var peer: PacketPeerUDP = server.take_connection()
		client_peer = peer
		print("Accepted peer: %s:%s" % [peer.get_packet_ip(), peer.get_packet_port()])
		python_client_connected.emit()

	if client_peer:
		var data = client_peer.get_packet()
		if not data.is_empty():
#			print(data.get_string_from_utf8())
			parse_message(client_peer, data.get_string_from_utf8())


func parse_message(peer: PacketPeerUDP, json_message: String):
#	print("Message <%s> sending from client %s" %[json_message, peer])
	var json = JSON.new()
	var err = json.parse(json_message)
	if err:
		printerr("parse message failed %d" % err)
		return
	var message = json.data
	if "namefunc" in message:
		if has_method(message.namefunc):
#		print_debug("<%s> method exist" % message)
			var params: Array = message.params
#			print(params)
			var args: Array
			for p in params:
				if p.type == "float":
					args.append(p.value.to_float())
				elif p.type == "int":
					args.append(p.value.to_int())
			var c = Callable(self, message.namefunc)
			if message.typefunc == "setter":
#				print("return setter")
				c.callv(args)
				return
			
			var ret = await c.callv(args)
#			print("ret: ", ret)
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
			elif ret is Array:
				var ret_message = {
					"type": "array",
					"value": ret,
					}
				peer.put_packet(JSON.stringify(ret_message).to_utf8_buffer())
			elif ret is PackedByteArray:
				peer.put_packet(ret)
			else:
				pass
				var ret_message = {
					"type": "null"
					}
				peer.put_packet(JSON.stringify(ret_message).to_utf8_buffer())
			
		else:
			var ret_message = {
					"error": "function doesn't exist!"
					}
			peer.put_packet(JSON.stringify(ret_message).to_utf8_buffer())
