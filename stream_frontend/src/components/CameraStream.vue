<template>
  <div id="camera-stream-container">
    <video ref="videoElement" id="video" autoplay playsinline muted preload="auto" @play="onplay" @pause="onpause" :controls="showControls"></video>
  </div>
</template>

<script>
import JMuxer from 'jmuxer';

export default {
  name: 'CameraStream',

  props: {
    onplay: Function,
    onpause: Function,
    showControls: Boolean,
  },

  data() {
    return {
      streamLocation: window.location.protocol + "//" + window.location.hostname + "/stream",
      VIDEO_WEBSOCKET_RESTART_INTERVAL: 500,
      jmuxer: undefined,
    };
  },

  methods: {
    getVideoElem() {
      return this.$refs.videoElement
    },

    setupWebsocket(jmuxer)
    {
      const url = new URL(this.streamLocation)
      url.protocol = url.protocol.replace('http', 'ws');
      this.ws = new WebSocket(url);

      this.ws.binaryType = 'arraybuffer';
      this.ws.onopen = function() {
        
        console.log("Video websocket opened")
      }
      this.ws.onmessage = function(event) {
        if (jmuxer)
        {
          jmuxer.feed({ video: new Uint8Array(event.data) });
        }
      };
      this.ws.onerror = (error) => {
        console.error('Video WebSocket error:', error);
        this.ws.close()
      };

      this.ws.onclose = () => {
        console.log('Video WebSocket connection closed, restarting soon');
        setTimeout(() => {
          console.log('Reconnecting video WebSocket...');
          this.setupWebsocket();
        }, this.VIDEO_WEBSOCKET_RESTART_INTERVAL);
      }
    }
  },

  mounted() {
    this.$refs.videoElement.src = this.streamLocation
    this.$refs.videoElement.onplay = this.onplay;
    this.$refs.videoElement.onpause = this.onpause;

    this.jmuxer = new JMuxer({
        node: 'video',
        mode: 'video',
        flushingTime: 0,
        clearBuffer: true,
        //debug: true,
        fps: 30,
    })

    this.setupWebsocket(this.jmuxer);
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
