import socket
import json
import struct
import numpy as np

class GodotBridge:
    ports_used = []
    def __init__(self, PORT=4242):
        if PORT in self.ports_used:
            print(f"[Warning] Port {PORT} already used")
            
        self.ports_used.append(PORT)
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.sock.connect(("127.0.0.1", PORT))
        # Flush recv data

    def set(self, namefunc, *args):
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
        
        message = {
            "namefunc": namefunc,
            "typefunc": "setter",
            "params": params,
        }
        # print("Message sending : ", message)
        json_message = json.dumps(message)
        try:
            self.sock.send(json_message.encode("utf-8"))
        except:
            print("[Error] No communication !")
            return

    def get(self, namefunc, *args):
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
        
        message = {
            "namefunc": namefunc,
            "typefunc": "getter",
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
            recv_data = self.sock.recv(100000)
        except ConnectionRefusedError:
            print("[Error] Connection failed")
            return
        # print("json ret message: ", json_ret_message)
        # if binary data ?
        if recv_data[0] == 0:
            bytes_data = recv_data[1:]
            float32_array = np.empty(int(len(bytes_data)/4), dtype='f')
            # print("Number of data : ", len(bytes_data)/4)
            for i in range(0, len(bytes_data), 4):
                float32_array[int(i/4)] = (struct.unpack('f', bytes_data[i: i+4])[0])
            return float32_array # return np.array

        ret_message = json.loads(recv_data)
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
            else:
                print("Unrecognized type!")
                return 0
        if "error" in ret_message:
            print(ret_message["error"])
            return None
