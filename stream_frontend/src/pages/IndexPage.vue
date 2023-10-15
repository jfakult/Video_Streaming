<template>
  <q-page class="video-container">
    <video
      id="my-video"
      class="video-js fullscreen-video"
      controls
      autoplay
      loop
      muted
    ></video>

    <q-icon name="battery_full" class="top-right" size="md" />
    <q-icon name="photo_camera" class="bottom-right" size="md" />
  </q-page>
</template>

<script>
import videojs from 'video.js';
import 'video.js/dist/video-js.css';

export default {
  name: 'PageIndex',
  mounted() {
    this.player = videojs('my-video');
    this.player.src({
      src: 'video/sample-5s.mp4', // replace with your live stream URL
      type: 'application/x-mpegURL'
    });
  },
  beforeUmount() {
    if (this.player) {
      this.player.dispose();
    }
  }
}
</script>

<style scoped>
.video-container {
  position: relative;
  width: 100%;
  height: 100vh;
  overflow: hidden;
}

.fullscreen-video {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  min-width: 100%;
  min-height: 100%;
  width: auto;
  height: auto;
  z-index: -100;
  background: no-repeat;
  background-size: cover;
}

.top-right, .bottom-right {
  position: absolute;
  z-index: 100;
}

.top-right {
  top: 10px;
  right: 10px;
}

.bottom-right {
  bottom: 10px;
  right: 10px;
}
</style>