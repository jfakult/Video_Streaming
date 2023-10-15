import json
import asyncio
import websockets

MOTOR_DISABLED = True

class ScopeServer:
    def __init__(self):
        self.users = set()  # Keeps track of active users
        self.motor_owner = None  # Current user who has control over the motor

    async def register(self, websocket):
        print("Registering new websocket client")
        self.users.add(websocket)

    async def unregister(self, websocket):
        self.users.remove(websocket)
        if self.motor_owner == websocket:
            self.motor_owner = None

    # Data comes into the websocket
    async def handle_message(self, websocket, message):
        if message == "ping":
            websocket.send("pong")
            return
        
        try:
            data = json.loads(message)
            msg_type = data["msg_type"]

            if msg_type == "POSITION":
                left_right = float(data["left_right"])
                up_down = float(data["up_down"])
                print(f"Positional data received: Left/Right = {left_right}, Up/Down = {up_down}")

            # The following two elif statements control logic to allow a single user to control the motor at a time
            # It also provides the option for preemption if the current controller gives permission
            elif msg_type == "REQUEST_CONTROL":
                print("Got new control request")
                if MOTOR_DISABLED:
                    await websocket.send(json.dumps({"response": "DISABLED"}))
                if self.motor_owner is None:
                    self.motor_owner = websocket
                    await websocket.send(json.dumps({"response": True}))
                else:
                    await websocket.send(json.dumps({"response": False}))

            elif msg_type == "REQUEST_PREEMPT":
                print("Got request to preempt control")
                if self.motor_owner and self.motor_owner != websocket:
                    await self.motor_owner.send(json.dumps({"action": "PREEMPT_REQUEST"}))
                    try:
                        response_data = json.loads(await asyncio.wait_for(self.motor_owner.recv(), timeout=10))
                        response = response_data["PREEMPT_RESPONSE"]
                    except asyncio.TimeoutError:
                        response = False
                        
                    if response == True:
                        self.motor_owner = websocket
                        await websocket.send(json.dumps({"response": "PREEMPT_GRANTED"}))
                    else:
                        await websocket.send(json.dumps({"response": "PREEMPT_DENIED"}))
                else:
                    await websocket.send(json.dumps({"response": "PREEMPT_GRANTED"}))

        except:
            websocket.send(f"Unknown message recieved: '{message}'")
            return


    async def handler(self, websocket, path):
        print("Got websocket request!")
        await self.register(websocket)
        try:
            async for message in websocket:
                await self.handle_message(websocket, message)
        finally:
            await self.unregister(websocket)

if __name__ == "__main__":
    server = ScopeServer()

    print("Starting WebSocket server on 0.0.0.0:9000...")
    start_server = websockets.serve(server.handler, "0.0.0.0", 9000)
    asyncio.get_event_loop().run_until_complete(start_server)
    print("WebSocket server is running and ready to accept connections!")
    asyncio.get_event_loop().run_forever()
