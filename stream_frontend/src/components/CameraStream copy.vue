<template>
  <div id="camera-stream-container">
    <video ref="videoElement" id="video" autoplay playsinline muted preload="auto" @play="onplay" @pause="onpause" :controls="showControls"></video>
  </div>
</template>

<script>
export default {
  name: 'CameraStream',

  props: {
    onplay: Function,
    onpause: Function,
    showControls: Boolean,
  },

  data() {
    return {
      pc: null,
      ws: null,
      queuedCandidates: [],
      offerData: null,
      streamLocation: window.location.protocol + "//" + window.location.hostname + ":8080",
      WEBSOCKET_RESTART_INTERVAL: 1000
    };
  },

  methods: {
    getVideoElem() {
      return this.$refs.videoElement;
    },

    start() {
      this.ws = new WebSocket(this.streamLocation.replace("http", "ws") + "/ws");

      this.ws.onopen = () => {
        console.log('WebRTC WebSocket connection established');
        this.createPeerConnection();
      };

      this.ws.onmessage = async (message) => {
        console.log("Got message", message)
        const data = JSON.parse(message.data);

        if (data.sdp) {
          await this.pc.setRemoteDescription(new RTCSessionDescription(data.sdp));
          if (data.sdp.type === 'offer') {
            const answer = await this.pc.createAnswer();
            await this.pc.setLocalDescription(answer);
            this.ws.send(JSON.stringify({ sdp: this.pc.localDescription }));
          }
        } else if (data.candidate) {
          console.log(data.candidate)
            const candidate = {
              candidate: data.candidate.candidate,
              sdpMid: data.candidate.sdpMid,
              sdpMLineIndex: data.candidate.sdpMLineIndex
          };
          await this.pc.addIceCandidate(new RTCIceCandidate(candidate));
        }
      };

      this.ws.onclose = () => {
          console.log('WebRTC WebSocket connection closed, attempting to reconnect...');
          setTimeout(() => {
              this.start();
          }, this.WEBSOCKET_RESTART_INTERVAL);
      };

      this.ws.onerror = (error) => {
          console.log('WebSocket error:', error);
          this.ws.close(); // Ensure that the connection is closed if an error occurs
      };
    },

    createPeerConnection() {
      this.pc = new RTCPeerConnection({
        iceServers: [
          //{ urls: 'stun:stun.l.google.com:19302' }
        ]
      });

      this.pc.onicecandidate = (event) => {
        console.log("Got ICE candidate", event)
        if (event.candidate) {
          this.ws.send(JSON.stringify({ candidate: event.candidate }));
        }
      };

      this.pc.ontrack = (event) => {
        console.log("Got track", event)
        this.$refs.videoElement.srcObject = event.streams[0];
      };

      this.pc.onconnectionstatechange = () => {
          console.log("Peer Connection State:", this.pc.connectionState);
          if (this.pc.connectionState === "disconnected" || this.pc.connectionState === "failed") {
              console.log("Peer connection failed, restarting...");
              this.start();
          }
      };

      this.pc.addTransceiver("video", { direction: "recvonly" });

      this.pc.createOffer().then((offer) => {
          console.log("Setting local description");
          return this.pc.setLocalDescription(offer);
      }).then(() => {
          console.log("Sending local description", this.pc.localDescription);
          this.ws.send(JSON.stringify({
              sdp: {
                  type: this.pc.localDescription.type,
                  sdp: this.pc.localDescription.sdp
              }
          }));
      }).catch((error) => {
          console.error("Error creating offer: ", error);
      });
    },
  },

  mounted() {
    this.start();
    this.$refs.videoElement.onplay = this.onplay;
    this.$refs.videoElement.onpause = this.onpause;
  },

  beforeUnmount() {
    if (this.pc !== null) {
      this.pc.close();
      this.pc = null;
    }
    if (this.ws !== null) {
      this.ws.close();
      this.ws = null;
    }
  }
};
</script>

<style scoped>
#video {
  width: 100%;
  height: auto;
  position: absolute;
  top: 50%;
  transform: translateY(-50%);
}
</style>
