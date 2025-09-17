import asyncio
import socket
from aiohttp import web
from aiortc import RTCPeerConnection, RTCSessionDescription, MediaStreamTrack
from av import VideoFrame

class RTPVideoStreamTrack(MediaStreamTrack):
    kind = "video"

    def __init__(self):
        super().__init__()  # Initialize the base class
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.sock.bind(("127.0.0.1", 5004))
        self.sock.setblocking(False)

    async def recv(self):
        data, _ = await asyncio.get_event_loop().sock_recvfrom(self.sock, 65536)
        pts, time_base = await self.next_timestamp()
        frame = VideoFrame.from_ndarray(data, format="h264")
        frame.pts = pts
        frame.time_base = time_base
        return frame

pcs = set()

async def offer(request):
    params = await request.json()
    offer = RTCSessionDescription(sdp=params["sdp"], type=params["type"])

    pc = RTCPeerConnection()
    pcs.add(pc)

    # Add the RTP video track before setting the remote description
    pc.addTrack(RTPVideoStreamTrack())

    await pc.setRemoteDescription(offer)
    answer = await pc.createAnswer()
    await pc.setLocalDescription(answer)

    return web.json_response({
        "sdp": pc.localDescription.sdp,
        "type": pc.localDescription.type
    })

app = web.Application()
app.router.add_post("/webrtc_control", offer)

web.run_app(app, port=5001)
