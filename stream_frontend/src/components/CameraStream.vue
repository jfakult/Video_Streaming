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

<style scoped>
/* styles to make video fill parent container */
#camera-stream-container {
  width: 100%;
  height: 100%;
  position: relative;
}
#video {
  width: 100%;
  height: 100%;
}
</style>