import gi
import socket
import threading

gi.require_version('Gst', '1.0')
gi.require_version('GstRtspServer', '1.0')
from gi.repository import Gst, GstRtspServer, GLib, GstRtsp

class RtspMediaFactory(GstRtspServer.RTSPMediaFactory):
    def __init__(self):
        super(RtspMediaFactory, self).__init__()

    def do_create_element(self, url):
        pipeline_str = (
            "udpsrc port=5000 caps='application/x-rtp, media=video, clock-rate=90000, encoding-name=H264, payload=96' ! "
            "rtpjitterbuffer latency=200 ! "
            "rtph264depay ! h264parse ! rtph264pay config-interval=1 name=pay0 pt=96"
        )
        return Gst.parse_launch(pipeline_str)

class GstServer:
    def __init__(self):
        self.server = GstRtspServer.RTSPServer()
        self.server.set_service('8554')
        self.factory = RtspMediaFactory()
        self.factory.set_shared(True)
        self.mounts = self.server.get_mount_points()
        self.mounts.add_factory("/stream", self.factory)
        self.server.attach(None)

def listen_for_keyframe_command():
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind(('0.0.0.0', 5001))
    while True:
        data, _ = sock.recvfrom(1024)  # Buffer size is 1024 bytes
        if data.decode() == 'keyframe':
            generate_keyframe()

def generate_keyframe():
    # Sending a keyframe request to the GStreamer pipeline
    print("Keyframe command received, generating keyframe...")
    keyframe_event = Gst.Event.new_custom(Gst.EventType.CUSTOM_UPSTREAM, Gst.Structure.new_empty("GstForceKeyUnit"))
    keyframe_event.get_structure().set_boolean("all-headers", True)
    
    # Assuming the pipeline and elements are accessible globally or via the server instance
    pipeline = server.factory.get_element()
    if pipeline:
        srcpad = pipeline.get_static_pad("src")
        if srcpad:
            srcpad.send_event(keyframe_event)

if __name__ == "__main__":
    Gst.init(None)
    server = GstServer()

    # Start the thread to listen for keyframe commands
    keyframe_thread = threading.Thread(target=listen_for_keyframe_command)
    keyframe_thread.daemon = True
    keyframe_thread.start()

    loop = GLib.MainLoop()
    loop.run()
