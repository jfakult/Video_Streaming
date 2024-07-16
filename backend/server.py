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

#os.environ['GST_DEBUG'] = '3'  # Set debug level to 3 (INFO)

'''
import ArducamSDK

# Camera configuration
arducam_config = {
    "u32CameraType": 0x4D091031,
    "u32Width": 1920,
    "u32Height": 1080,
    "u8PixelBytes": 1,
    "u8PixelBits": 8,
    "u32I2cAddr": 0x20,
    "emI2cMode": 3,
    "emImageFmtMode": 0,
    "u32TransLvl": 64
}

def init_camera(config):
    handle, rtn_val = ArducamSDK.Py_ArduCam_autoopen(arducam_config)
    if rtn_val == 0:
        return handle
    else:
        raise RuntimeError(f"Failed to open camera, return value: {rtn_val}")

camera = init_camera(arducam_config)
'''

### STREAMING CONSTANTS
STREAM_BITRATE = 7000000
STREAM_KEYFRAME_INTERVAL = 45
#STREAM_DESIRED_LATENCY = 5

# Constants
LIBCAMERA_IN_PORT = 5000
#GSTREAMER_OUT_PORT = 5001
#STREAM_OUT_PORT = 5002
WEBSOCKET_CONTROL_PORT = 5001
WEBSOCKET_VIDEO_PORT = 5002
ROOT_PATH = "/home/pi/Video_Streaming"
IS_STREAMING = False

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

async def capture_frames():
    buffer = bytearray()
    start_code = b'\x00\x00\x00\x01' # Start code of h264 nal unit

    udp_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    udp_sock.bind(("0.0.0.0", 5000))

    STREAM_KEYFRAME_SIZE_FACTOR = 50   # Keyframes are big, make sure the buffer doesn't overflow
    buffer_size = int((STREAM_BITRATE / 8) * STREAM_KEYFRAME_SIZE_FACTOR)
    
    udp_sock.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, buffer_size)
    #udp_sock.settimeout(STREAM_KEYFRAME_INTERVAL / 30)  # Small timeout to prevent blocking

    print("Setting UDP buffer size to", buffer_size / (1024*1024), "MB")

    try:
        #ArducamSDK.Py_ArduCam_beginCaptureImage(camera)
        while True:
            await asyncio.sleep(0.01) # reduce CPU usage, sleep less than a half a frame
            #await asyncio.sleep(0.01) # reduce cpu usage, sleep less than a half a frame
            if len(clients) == 0:
                continue
            
            try:
                data, addr = udp_sock.recvfrom(2 ** 18)  # 2**15 ~= 16K which should be larger than UDP MTU
            except socket.timeout:
                print("Socket read timeout")
                continue
            '''
            rtn_val = ArducamSDK.Py_ArduCam_captureImage(handle)
            if rtn_val != 0:
                print(f"Failed to capture image, return value: {rtn_val}")
                continue
            
            rtn_val, data, rtn_cfg = ArducamSDK.Py_ArduCam_readImage(handle)
            if rtn_val != 0:
                print(f"Failed to read image, return value: {rtn_val}")
                continue
            '''

            buffer.extend(data)

            nal_units = []
            while True:
                start_pos = buffer.find(start_code)
                #print(start_pos, len(buffer))
                if start_pos == -1:
                    break

                end_pos = buffer.find(start_code, start_pos + 4)
                if end_pos == -1:
                    break

                nal_units.append(buffer[start_pos:end_pos])

                buffer = buffer[end_pos:]

            # It should always be one. Will monitor this for a while and simplify if it really is
            #if len(nal_units) > 1:
                #print("UH OH, got more than 1 NAL unit. That shouldn't happen!")

            for nal_unit in nal_units:
                for websocket in clients:
                    try:
                        await websocket.send(nal_unit)
                    except websockets.exceptions.ConnectionClosedError as e:
                        print(f"WebSocket connection error: {e}")
                        clients.remove(websocket)

    except Exception as e:
        print("Error sending h264 data", e)
    finally:
        udp_sock.close()
        #ArducamSDK.Py_ArduCam_endCaptureImage(handle)
        #ArducamSDK.Py_ArduCam_close(handle)

async def websocket_handler(websocket, path):
    #global pipeline
    #global clients
    print("Got request to open video streaming websocket")
    clients.add(websocket)
    
    print(f"Client connected: {path}")
    try:
        async for message in websocket:
            pass
    finally:
        clients.remove(websocket)

async def start_video_websocket():
    print("Starting up video streaming websocket")
    try:
        start_server = await websockets.serve(websocket_handler, "0.0.0.0", WEBSOCKET_VIDEO_PORT)
        await start_server.wait_closed()
    except Exception as e:
        print("Failed to open video websocket:", e)
    print("Closing video websocket")



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

async def start_control_websocket():
    server = ScopeServer()
    try:
        start_server = await websockets.serve(server.handler, "0.0.0.0", WEBSOCKET_CONTROL_PORT)
        await start_server.wait_closed()
    except Exception as e:
        print("Failed to open control websocket:", e)
    print("Done")

async def start_libcamera_vid():
    print("Starting libcamera")
    try:
        process = await asyncio.create_subprocess_shell(f'sh {ROOT_PATH}/scripts/stream.sh {STREAM_BITRATE} {STREAM_KEYFRAME_INTERVAL}')
    except Exception as e:
        print(f"Failed to start subprocess: {e}")


#################
### MAIN LOOP ###
#################
print("Starting...")

async def main():
    await asyncio.gather(
        start_libcamera_vid(),
        start_control_websocket(),
        start_video_websocket(),
        capture_frames(),
        #start_gstreamer_pipeline()
    )

if __name__ == "__main__":
    asyncio.run(main())