import json
import time
import uuid
import asyncio
import websockets
import subprocess

# EDIT AS NEEDED
SERVER_PORT = 9000
#SERVER_PORT = 10020
ROOT_PATH = "/home/pi/Video_Streaming"
#ROOT_PATH = "~/webapps/Video_Streaming"

class ScopeServer:
    def __init__(self):
        self.socket_connections = {}
        self.PI_STATE = "scope"
        pass

    # Data comes into the websocket
    async def handle_message(self, websocket, message):
        print("Got message: ", message)

        if message == "ping":
            await websocket.send("pong")

            return
        
        try:
            data = json.loads(message)
            message_type = data["message_type"]

            if message_type == "quality":
                quality = data["data"]
                response = {"message_type": "quality", "data": quality}
                if quality == "low":
                    pass
                else:
                    pass

                await websocket.send(json.dumps(response))

            if message_type == "stream_mode":
                mode = data["data"]
                response = {"message_type": "stream_mode", "data": mode}

                if mode == "scope":
                    subprocess.Popen(['sh', f'{ROOT_PATH}/scripts/screen.sh'])
                    self.PI_STATE = "scope"
                else: # mode == "wifi"
                    subprocess.Popen(['sh', f'{ROOT_PATH}/scripts/stream.sh'])
                    self.PI_STATE = "stream"

                for uuid, socket in self.socket_connections.items():
                    try:
                        await socket.send(json.dumps(response))
                    except:
                        print("Error sending message to socket: ", uuid)
                        del self.socket_connections[uuid]

                #await websocket.send(json.dumps(response))
            
        except:
            print("Unknown message recieved: ", message)
            await websocket.send(f"Unknown message recieved: '{message}'")
            return


    async def handler(self, websocket, path):
        print("Got websocket request!")
        websocket.uuid = uuid.uuid4()
        self.socket_connections[websocket.uuid] = websocket

        print([x for x in self.socket_connections])

        await websocket.send( json.dumps({"message_type": "stream_mode", "data": self.PI_STATE}) )
        try:
            async for message in websocket:
                await self.handle_message(websocket, message)
        except websockets.ConnectionClosedOK:
            print("Connection closed!")
        except websockets.ConnectionClosedError as e:
            print("Connection closed (with error!", e)

        del self.socket_connections[websocket.uuid]

if __name__ == "__main__":
    print("Starting streaming service")
    logo = subprocess.Popen(['sh', f'{ROOT_PATH}/scripts/logo.sh'])
    time.sleep(1)
    logo.terminate()
    print("terminated logo")
    subprocess.Popen(['sh', f'{ROOT_PATH}/scripts/screen.sh'])
    
    server = ScopeServer()

    print(f"Starting WebSocket server on 0.0.0.0:{SERVER_PORT}...")
    start_server = websockets.serve(server.handler, "0.0.0.0", SERVER_PORT)
    asyncio.get_event_loop().run_until_complete(start_server)
    print("WebSocket server is running and ready to accept connections!")
    asyncio.get_event_loop().run_forever()
