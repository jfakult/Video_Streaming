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
            msg_type = data["msg_type"]

            if msg_type == "quality":
                quality = data["data"]
                if quality == "low":
                    pass
                else:
                    pass
            if msg_type == "stream_mode":
                print("Setting stream mode")
                mode = data["data"]
                if mode == "screen":
                    subprocess.Popen(['sh', '/home/pi/Video_Streaming/scripts/screen.sh'])
                else: # mode == "wifi"
                    subprocess.Popen(['sh', '/home/pi/Video_Streaming/scripts/stream.sh'])
            
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
    server = ScopeServer()

    print("Starting WebSocket server on 0.0.0.0:9000...")
    start_server = websockets.serve(server.handler, "0.0.0.0", 9000)
    asyncio.get_event_loop().run_until_complete(start_server)
    print("WebSocket server is running and ready to accept connections!")
    asyncio.get_event_loop().run_forever()
