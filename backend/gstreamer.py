import gi
gi.require_version('Gst', '1.0')
gi.require_version('GstWebRTC', '1.0')
from gi.repository import Gst, GObject, GstWebRTC

Gst.init(None)
GObject.threads_init()

Gst.debug_set_default_threshold(Gst.DebugLevel.WARNING)

class VideoStreamer:
    def __init__(self, fd, bitrate=5000, keyframe_rate=20, width=1920, height=1080, framerate=10):
        self.bitrate = bitrate
        self.keyframe_rate = keyframe_rate
        self.width = width
        self.height = height
        self.framerate = framerate

        self.pipeline = Gst.Pipeline.new("pipeline")
        self.pipeline.use_clock(Gst.SystemClock.obtain())
        self.pipeline.set_start_time(Gst.CLOCK_TIME_NONE)

        # Raw video source from file descriptor
        self.src = Gst.ElementFactory.make("fdsrc", "source")
        self.src.set_property("fd", fd)

        # Parse based on source width and height (will be rescaled later)
        self.parse = Gst.ElementFactory.make("videoparse", "parse")
        self.parse.set_property("width", width)
        self.parse.set_property("height", height)
        self.parse.set_property("format", "i420")
        self.parse.set_property("framerate", Gst.Fraction(10, 1))

        #print("src → pad caps:", self.src.get_static_pad("src").query_caps(None).to_string())
        #print("parse → pad caps:", self.parse.get_static_pad("sink").query_caps(None).to_string())

        # Scale it down to 1080p for better streaming
        self.scale = Gst.ElementFactory.make("videoscale", "scale")
        self.caps = Gst.ElementFactory.make("capsfilter", "caps")
        self.caps.set_property("caps", Gst.Caps.from_string("video/x-raw,width=1920,height=1080"))

        # Encode raw scaled video data to H.264
        self.encoder = Gst.ElementFactory.make("x264enc", "encoder")
        self.encoder.set_property("bitrate", bitrate)
        self.encoder.set_property("tune", "zerolatency")
        self.encoder.set_property("speed-preset", "superfast")

        # Bundle the encoded video into RTP packets for WebRTC
        self.payloader = Gst.ElementFactory.make("rtph264pay", "pay")
        self.payloader.set_property("config-interval", 1)
        self.payloader.set_property("pt", 96)

        self.webrtcbin = Gst.ElementFactory.make("webrtcbin", "webrtc")
        self.webrtcbin.connect("pad-added", self._on_webrtc_pad_added)
        #self.webrtcbin.set_property("stun-server", None)
        #self.webrtcbin.set_property("turn-server", None)
        self.webrtcbin.set_property("stun-server", "stun:127.0.0.1:3478")
        self.webrtcbin.set_property("bundle-policy", "max-bundle")
        self.webrtcbin.set_property("ice-transport-policy", "all")

        self.webrtcbin.connect("on-ice-candidate", self._on_ice_candidate)
        self.webrtcbin.connect("on-negotiation-needed", self._on_negotiation_needed)
        self.webrtcbin.connect("notify::ice-gathering-state", self._on_notify_ice_gathering_state)
        self.webrtcbin.connect("notify::ice-connection-state", self._on_notify_ice_connection_state)

        for elem in [self.src, self.parse, self.scale, self.caps, self.encoder, self.payloader, self.webrtcbin]:
            self.pipeline.add(elem)
        

        # Link src → parse
        src_pad = self.src.get_static_pad("src")
        parse_sink_pad = self.parse.get_static_pad("sink")
        link_result = src_pad.link(parse_sink_pad)
        print("[GStreamer] src → parse link result:", link_result.value_nick)
        assert link_result == Gst.PadLinkReturn.OK, "Failed to link src → parse"

        # Link parse → scale
        parse_pad = self.parse.get_static_pad("src")
        scale_pad = self.scale.get_static_pad("sink")
        link_result = parse_pad.link(scale_pad)
        print("[GStreamer] parse → scale link result:", link_result.value_nick)
        assert link_result == Gst.PadLinkReturn.OK, "Failed to link parse → scale"

        # Link scale → caps
        scale_pad = self.scale.get_static_pad("src")
        caps_pad = self.caps.get_static_pad("sink")
        link_result = scale_pad.link(caps_pad)
        print("[GStreamer] scale → caps link result:", link_result.value_nick)
        assert link_result == Gst.PadLinkReturn.OK, "Failed to link scale → caps"

        # Link caps → encoder
        caps_pad = self.caps.get_static_pad("src")
        encoder_pad = self.encoder.get_static_pad("sink")
        link_result = caps_pad.link(encoder_pad)
        print("[GStreamer] caps → encoder link result:", link_result.value_nick)
        assert link_result == Gst.PadLinkReturn.OK, "Failed to link caps → encoder"

        # Link encoder → payloader
        encoder_pad = self.encoder.get_static_pad("src")
        payloader_pad = self.payloader.get_static_pad("sink")
        link_result = encoder_pad.link(payloader_pad)
        print("[GStreamer] encoder → payloader link result:", link_result.value_nick)
        assert link_result == Gst.PadLinkReturn.OK, "Failed to link encoder → payloader"


        #self.payloader.link(self.webrtcbin)

        bus = self.pipeline.get_bus()
        bus.add_signal_watch()
        bus.connect("message", self._on_bus_message)

    def _on_bus_message(self, bus, message):
        bus = self.pipeline.get_bus()
        bus.add_signal_watch()
        bus.connect("message2", self._on_bus_message)
        
        t = message.type
        if t == Gst.MessageType.ERROR:
            err, dbg = message.parse_error()
            print("[GStreamer ERROR]", err.message, dbg)
        elif t == Gst.MessageType.WARNING:
            err, dbg = message.parse_warning()
            print("[GStreamer WARNING]", err.message, dbg)

    def _on_webrtc_pad_added(self, webrtcbin, pad):
        print("[GStreamer] WebRTC pad added:", pad.get_name())
        # Link the new pad to the payloader
        #pay_src_pad = self.payloader.get_static_pad("src")
        #if not pay_src_pad.is_linked():
        #    webrtc_sink_pad = pad
        #    pay_src_pad.link(webrtc_sink_pad)
        #else:
        #    print("[GStreamer] Warning: Payloader source pad already linked.")
    
    def _on_ice_candidate(self, webrtcbin, mlineindex, candidate):
        print(f"[GStreamer] ICE candidate received: mlineindex={mlineindex}, candidate={candidate}")
        # This is where you would send the candidate to the remote peer
        # For example, via WebSocket or any other signaling mechanism
        pass

    def _on_negotiation_needed(self, webrtcbin):
        print("[GStreamer] Negotiation needed")
        # This is where you would create an offer and send it to the remote peer
        # For example, via WebSocket or any other signaling mechanism
        pass

    def _on_notify_ice_gathering_state(self, webrtcbin, state):
        print(f"[GStreamer] ICE gathering state changed: {state.value_name}")
        if state == GstWebRTC.WebRTCICEGatheringState.COMPLETE:
            print("[GStreamer] ICE gathering complete")
            # You might want to send gathered candidates to the remote peer here
        elif state == GstWebRTC.WebRTCICEGatheringState.GATHERING:
            print("[GStreamer] ICE gathering in progress")
        elif state == GstWebRTC.WebRTCICEGatheringState.NEW:
            print("[GStreamer] ICE gathering started")

    def _on_notify_ice_connection_state(self, webrtcbin, state):
        print(f"[GStreamer] ICE connection state changed: {state.value_name}")
        if state == GstWebRTC.WebRTCICEConnectionState.CONNECTED:
            print("[GStreamer] ICE connection established")
        elif state == GstWebRTC.WebRTCICEConnectionState.DISCONNECTED:
            print("[GStreamer] ICE connection disconnected")
        elif state == GstWebRTC.WebRTCICEConnectionState.FAILED:
            print("[GStreamer] ICE connection failed")
        elif state == GstWebRTC.WebRTCICEConnectionState.CLOSED:
            print("[GStreamer] ICE connection closed")

        # You might want to handle cleanup or re-negotiation here if needed.

    def start(self):
        print("Start called!")
        #caps = Gst.Caps.from_string("application/x-rtp,media=video,encoding-name=H264,payload=96")

        # Proper linking of dynamic RTP pad
        pay_src_pad = self.payloader.get_static_pad("src")
        webrtc_sink_pad = self.webrtcbin.get_request_pad("sink_%u")
        pay_src_pad.link(webrtc_sink_pad)
        
        #self.webrtcbin.emit("add-transceiver", GstWebRTC.WebRTCRTPTransceiverDirection.SENDONLY, caps)

        state_change_return = self.pipeline.set_state(Gst.State.PLAYING)

        print("[GStreamer] Pipeline set_state result:", state_change_return.value_nick)

    def stop(self):
        self.pipeline.set_state(Gst.State.NULL)
