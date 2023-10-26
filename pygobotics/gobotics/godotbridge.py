import socket
import json
# import struct
import numpy as np

class GodotBridge:
    ports_used = []
    """
    Create a bridge from Python script to Godot application
    PORT : Number beetween 4243 and 65535
    """
    def __init__(self, port):
        if port in self.ports_used:
            if port == 4242:
                raise ValueError("Port 4242 cannot be used and is reserved for the gobotics engine")
            else:
                raise ValueError(f"Port {port} already used")
        self.port = port
        self.ports_used.append(port)
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.sock.connect(("127.0.0.1", port))
        # Flush recv data

    def call(self, namefunc, *args):
        params = []
        for arg in args:
            # print(arg)
            # print(type(arg))
            if type(arg) is float:
                arg_str = str(arg)
                param = {
                    "type": "float",
                    "value": arg_str,
                }
                params.append(param)
            elif type(arg) is int:
                arg_str = str(arg)
                param = {
                    "type": "int",
                    "value": arg_str,
                }
                params.append(param)
            elif type(arg) is bool:
                arg_str = str(arg)
                param = {
                    "type": "bool",
                    "value": arg_str,
                }
                params.append(param)
            elif type(arg) is str:
                arg_str = arg
                param = {
                    "type": "string",
                    "value": arg_str,
                }
                params.append(param)
            elif type(arg) is tuple:
                if len(arg) == 3:
                    param = {
                        "type": "vec3",
                        "value": arg,
                    }
                params.append(param)
        
        message = {
            "namefunc": namefunc,
            "params": params,
        }
        # print("Message sending : ", message)
        json_message = json.dumps(message)
        try:
            self.sock.send(json_message.encode("utf-8"))
        except:
            print("[Error] No communication !")
            return
        try:
            recv_data = self.sock.recv(65507)
        except ConnectionRefusedError:
            # print("[Error] Connection failed on port %d" % self.port)
            raise ConnectionRefusedError("Connection failed on port %d" % self.port)
        # print("json ret message: ", json_ret_message)
        # if binary data ?
        # if recv_data[0] == 0:
        #     bytes_data = recv_data[1:]
        #     float32_array = np.empty(int(len(bytes_data)/4), dtype='f')
        #     # print("Number of data : ", len(bytes_data)/4)
        #     for i in range(0, len(bytes_data), 4):
        #         float32_array[int(i/4)] = (struct.unpack('f', bytes_data[i: i+4])[0])
        #     return float32_array # return np.array
        
        try:
            ret_message = json.loads(recv_data)
        except UnicodeDecodeError:
            print("len: ", len(recv_data))
            return recv_data
        # print("ret message: ", ret_message)

        if "type" in ret_message:
            # print("response ret")

            if ret_message['type'] == 'null':
                return None
            elif ret_message['type'] == 'bool':
                if ret_message['value'] == 'true':
                    return True
                else:
                    return False
            elif ret_message['type'] == 'float':
                return float(ret_message['value'])
            elif ret_message['type'] == 'int':
                return int(ret_message['value'])
            elif ret_message['type'] == 'vec3':
                return ret_message['value']
            elif ret_message['type'] == 'float_array':
                return ret_message['value']
            elif ret_message['type'] == 'array':
                return ret_message['value']
            elif ret_message['type'] == 'byte_array':
                print("value: ", int(ret_message['value']))
                packed_data = bytearray()
                for num in range(int(ret_message['value'])):
                    recv_data = self.sock.recv(65507)
                    packed_data.extend(recv_data)
                return packed_data
            else:
                print("Unrecognized type!")
                return 0
        
        if "error" in ret_message:
            print(ret_message["error"])
            return None

    