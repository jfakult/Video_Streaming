import gi
import os
import json
import time
import uuid
import socket
import asyncio
import threading
import websockets
import subprocess
from socketserver import ThreadingMixIn
from h26x_extractor.h26x_parser import H26xParser
from http.server import BaseHTTPRequestHandler, HTTPServer

# GStreamer and GLib initialization
gi.require_version('Gst', '1.0')
from gi.repository import Gst, GLib

Gst.init(None)

os.environ['GST_DEBUG'] = '3'  # Set debug level to 3 (INFO)

# Constants
LIBCAMERA_IN_PORT = 5000
#GSTREAMER_OUT_PORT = 5001
#STREAM_OUT_PORT = 5002
WEBSOCKET_CONTROL_PORT = 5001
WEBSOCKET_VIDEO_PORT = 5002
ROOT_PATH = "/home/pi/Video_Streaming"

pipeline = None

clients = set()

#######################################
######## GSTREAMER RELATED CODE #######
#######################################
def on_new_sample(sink, data):
    print("Got sample")
    sample = sink.emit('pull-sample')
    buf = sample.get_buffer()
    caps = sample.get_caps()
    size = buf.get_size()
    data = buf.extract_dup(0, size)
    
    for client in clients:
        asyncio.run_coroutine_threadsafe(client.send(data), asyncio.get_event_loop())
    
    return Gst.FlowReturn.OK

def start_gstreamer_pipeline():
    print("Starting gstreamer pipeline")
    gstreamer_string = (
        f"udpsrc port={LIBCAMERA_IN_PORT} ! queue ! h264parse ! mpegtsmux ! appsink name=appsink"
    )
    print("Running gstreamer command")
    print("gst-launch-1.0 " + gstreamer_string)
    return
    pipeline = Gst.parse_launch(gstreamer_string)

    '''
    bus = pipeline.get_bus()
    bus.add_signal_watch()
    bus.connect("message::error", on_error)
    bus.connect("message::eos", on_eos)
    bus.connect("message::state-changed", on_state_changed)
    '''

    appsink = pipeline.get_by_name('appsink')
    appsink.set_property('emit-signals', True)
    appsink.set_property('sync', False)

    appsink.connect('new-sample', on_new_sample, appsink)

    pipeline.set_state(Gst.State.PLAYING)
    loop = GLib.MainLoop()
    try:
        loop.run()
    except Exception as e:
        print(f"GStreamer pipeline error: {e}")
        pipeline.set_state(Gst.State.NULL)

''' for gstreamer debugging
def on_error(bus, msg):
    err, debug = msg.parse_error()
    print(f"Error: {err}, {debug}")

def on_eos(bus, msg):
    print("End-Of-Stream reached")

def on_state_changed(bus, msg):
    old, new, pending = msg.parse_state_changed()
    print(f"Pipeline state changed from {old} to {new}")
'''

async def websocket_handler(websocket, path):
    global pipeline
    print("Got request to open video streaming websocket")
    clients.add(websocket)
    
    # Force a keyframe when a new client connects
    #event = Gst.Event.new_custom(Gst.EventType.CUSTOM_UPSTREAM, Gst.Structure.new_empty("GstForceKeyUnit"))
    #event.get_structure().set_boolean("all-headers", True)
    #pipeline.send_event(event)
    
    print(f"Client connected: {path}")
    udp_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    udp_sock.bind(("0.0.0.0", 5000))

    buffer = bytearray()
    start_code = b'\x00\x00\x00\x01' # Start code of h264 nal unit

    try:
        while True:
            data, addr = udp_sock.recvfrom(65536)
            buffer.extend(data)

            while True:
                start_pos = buffer.find(start_code)
                if start_pos == -1:
                    break

                end_pos = buffer.find(start_code, start_pos + 4)
                if end_pos == -1:
                    break

                nal_unit = buffer[start_pos:end_pos]
                await websocket.send(nal_unit)

                buffer = buffer[end_pos:]
    except websockets.exceptions.ConnectionClosed:
        print("Client disconnected")
    finally:
        udp_sock.close()

def start_video_websocket():
    print("Starting up video streaming websocket")
    asyncio.set_event_loop(asyncio.new_event_loop())
    start_server = websockets.serve(websocket_handler, "0.0.0.0", WEBSOCKET_VIDEO_PORT)
    asyncio.get_event_loop().run_until_complete(start_server)
    asyncio.get_event_loop().run_forever()



##################################
### SCOPE CONTROL RELATED CODE ###
##################################
class ScopeServer:
    def __init__(self):
        self.socket_connections = {}
        self.PI_STATE = "stream"
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
        print("Got websocket control request!")
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

def start_control_websocket():
    print("Starting up control websocket")
    server = ScopeServer()
    asyncio.set_event_loop(asyncio.new_event_loop())
    start_server = websockets.serve(server.handler, "0.0.0.0", WEBSOCKET_CONTROL_PORT)
    asyncio.get_event_loop().run_until_complete(start_server)
    asyncio.get_event_loop().run_forever()




#################
### MAIN LOOP ###
#################
print("Starting...")
if __name__ == "__main__":
    threading.Thread(target=start_control_websocket).start()
    threading.Thread(target=start_video_websocket).start()
    
    subprocess.Popen(['sh', f'{ROOT_PATH}/scripts/stream.sh'])
    time.sleep(3)

    #start_gstreamer_pipeline()