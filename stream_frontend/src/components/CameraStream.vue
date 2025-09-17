<<<<<<< HEAD
<script setup>
import { onMounted, ref } from 'vue'
import { MediaMTXWebRTCReader } from '../lib/MediaMTXWebRTCReader.js'

const props = defineProps({
  onplay: Function,
  onpause: Function,
  showControls: Boolean,
})

const videoElement = ref(null)
let reader = null

onMounted(() => {
  const el = videoElement.value
  el.onplay = props.onplay
  el.onpause = props.onpause

  let url = window.location.origin
  // pull port off, generic regardless of what it is
  let url_without_port = url.replace(/:\d+/, "")

  reader = new MediaMTXWebRTCReader({
    url: url_without_port + "/cam/whep",
    onError: (err) => console.warn("Stream error:", err),
    onTrack: (evt) => {
      console.log("Track received");
      el.srcObject = evt.streams[0]
    },
  })
})


/*
onUnmounted(() => {
  if (reader) reader.close()
})
*/

const getVideoElem = () => videoElement.value
defineExpose({ getVideoElem })
</script>

<template>
  <div id="camera-stream-container">
    <video
      ref="videoElement"
      id="video"
      autoplay
      playsinline
      muted
      preload="auto"
      :controls="props.showControls"
    />
  </div>
</template>
=======
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
>>>>>>> bdf691d66e9724b56b2e1e4925b67f41e5d1c2dd
