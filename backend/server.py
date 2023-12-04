import json
import asyncio
import websockets
import subprocess

class ScopeServer:
    def __init__(self):
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
                    subprocess.Popen(['sh', '/home/pi/Video_Streaming/scripts/screen.sh'])
                else: # mode == "wifi"
                    subprocess.Popen(['sh', '/home/pi/Video_Streaming/scripts/stream.sh'])

                await websocket.send(json.dumps(response))
            
        except:
            websocket.send(f"Unknown message recieved: '{message}'")
            return


    async def handler(self, websocket, path):
        print("Got websocket request!")
        try:
            async for message in websocket:
                await self.handle_message(websocket, message)
        except e:
            print("Got error on new websocket connection: ", e)

if __name__ == "__main__":
    print("Starting streaming service")
    subprocess.Popen(['sh', '/home/pi/Video_Streaming/scripts/screen.sh'])
    
    server = ScopeServer()

    print("Starting WebSocket server on 0.0.0.0:9000...")
    start_server = websockets.serve(server.handler, "0.0.0.0", 9000)
    asyncio.get_event_loop().run_until_complete(start_server)
    print("WebSocket server is running and ready to accept connections!")
    asyncio.get_event_loop().run_forever()
