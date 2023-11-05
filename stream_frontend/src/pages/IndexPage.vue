<template>
  <q-page class="video-container">
    <div class="video-wrapper" ref="videoWrapper">
    <video
      ref="video"
      id="video"
      class="video-js fullscreen-video"
      controls="false"
      autoplay
      loop
      muted
    >
      <source src="video/sample-5s.mp4" type="video/mp4">
      Your browser does not support the video tag.
    </video>
    </div>

    <q-btn round dense flat class="top-right" :ripple="false">
      <q-icon name="battery_full" size="lg" color="white" />
    </q-btn>

    <q-btn round dense flat class="bottom-right" :ripple="false">
      <q-icon name="photo_camera" size="lg" color="white" />
    </q-btn>

    <div>
      <!-- Preempt Button -->
      <q-btn v-if="showPreemptButton" color="primary" text-color="white" label="Preempt" @click="requestPreempt" style="position: absolute; bottom: 20px; left: 20px;" />
  </div>
  </q-page>
</template>

<script>
//import videojs from 'video.js';
//import 'video.js/dist/video-js.css';
import { ref, onMounted } from 'vue';
import { Dialog } from 'quasar';

export default {
  name: 'PageIndex',
  setup() {
    const showPreemptButton = ref(false);

    const videoWrapper = ref(null);
    const video = ref(null);
    let websocket;
    let scale = 1;
    let posX = 0;
    let posY = 0;
    let lastTouchEnd = 0;

    function setupWebSocket()
    {
      var url = new URL('/control', window.location.href);
      url.protocol = url.protocol.replace('http', 'ws');
      websocket = new WebSocket(url.href);
      
      websocket.onopen = () => {
        // Acquire control when socket opens
        console.log("Websocket opened")

        if (socketHandle)
        {
          clearInterval(socketHandle)
        }
        // Ping pong, most browsers time out the websocket at 1 minute
        var socketHandle = setInterval(() => { websocket.send("ping") }, 29 * 1000)

        requestControl();
      };
      
      websocket.onmessage = handleWebSocketMessage;

      websocket.onerror = (error) => {
        console.error("WebSocket Error", error);
      };

      websocket.onclose = (event) => {
        if (event.wasClean) {
          console.log(`Closed cleanly, code=${event.code}, reason=${event.reason}`);
        } else {
          console.error('Connection died');
        }
        
        // Attempt to reconnect after a delay
        setTimeout(() => {
          setupWebSocket();
        }, 10000); // Wait for 1 second before reconnecting
      };
    }

    function handleWebSocketMessage(event) {
      const data = JSON.parse(event.data);

      if (data.action === "PREEMPT_REQUEST") {
        Dialog.create({
          title: 'Preemption Request',
          message: 'Someone wants to take control. Do you allow?',
          ok: {
            label: 'Yes',
            color: 'green'
          },
          cancel: {
            label: 'No',
            color: 'red'
          }
        }).onOk(() => {
          websocket.send(JSON.stringify({ response: "YES" }));
        }).onCancel(() => {
          websocket.send(JSON.stringify({ response: "NO" }));
        });
      } else if (data.response === "PREEMPT_GRANTED") {
        // Handle UI or logic when preemption is granted
      } else if (data.response === "NO") {
        showPreemptButton.value = true;
      }
    }

    onMounted(() => {
      setupWebSocket();

      videoWrapper.value.addEventListener('wheel', (e) => {
        e.preventDefault();
        
        const rect = video.value.getBoundingClientRect();
        const offsetX = e.clientX - rect.left - (rect.width / 2);
        const offsetY = e.clientY - rect.top - (rect.height / 2);
        
        const oldScale = scale;
        scale += e.deltaY * -0.01;
        scale = Math.min(Math.max(1, scale), 3); // clamp the zoom level between 1 and 3
        
        // Adjust translations based on the mouse position
        //posX += offsetX - offsetX * (oldScale / scale);
        //posY += offsetY - offsetY * (oldScale / scale);

        updateTransform();
      });

      let startX = 0;
      let startY = 0;

      videoWrapper.value.addEventListener('mousedown', (e) => {
        startX = e.pageX - posX;
        startY = e.pageY - posY;
        document.addEventListener('mousemove', onMove);
        document.addEventListener('mouseup', () => {
          document.removeEventListener('mousemove', onMove);
        });
      });

      videoWrapper.value.addEventListener('touchstart', (e) => {
        if (e.touches.length > 1) {
          e.preventDefault();
        }
        startX = e.touches[0].pageX - posX;
        startY = e.touches[0].pageY - posY;
      });

      videoWrapper.value.addEventListener('touchmove', (e) => {
        e.preventDefault();
        posX = e.touches[0].pageX - startX;
        posY = e.touches[0].pageY - startY;
        updateTransform();
      });

      videoWrapper.value.addEventListener('touchend', (e) => {
        if (e.timeStamp - lastTouchEnd <= 300) {
          e.preventDefault();
        }
        lastTouchEnd = e.timeStamp;
      });

      function onMove(e) {
        e.preventDefault();
        posX = e.pageX - startX;
        posY = e.pageY - startY;
        updateTransform();
      }

      function updateTransform() {
        const vidDims = videoDimensions(video.value)
        const videoWidth = vidDims.width* scale;
        const videoHeight = vidDims.height * scale;
        const containerWidth = videoWrapper.value.clientWidth;
        const containerHeight = videoWrapper.value.clientHeight;
        
        const maxX = 0;
        const minX = containerWidth - videoWidth
        const maxY = 0;
        const minY = containerHeight - videoHeight

        console.log(posX, minX, maxX)
        
        // Clamp the values to keep video within the bounds of the container
        posX = clamp(posX, minX, maxX);
        posY = clamp(posY, minY, maxY);

        video.value.style.transform = `translate(${posX}px, ${posY}px) scale(${scale})`;
      }

      function clamp(value, min, max) {
        return Math.min(Math.max(value, min), max);
      }

      // https://nathanielpaulus.wordpress.com/2016/09/04/finding-the-true-dimensions-of-an-html5-videos-active-area/
      function videoDimensions(video) {
        // Ratio of the video's intrisic dimensions
        var videoRatio = video.videoWidth / parseFloat(video.videoHeight);
        // The width and height of the video element
        var width = video.offsetWidth, height = parseFloat(video.offsetHeight);
        // The ratio of the element's width to its height
        var elementRatio = width/height;
        // If the video element is short and wide
        if(elementRatio > videoRatio) width = height * videoRatio;
        // It must be tall and thin, or exactly equal to the original ratio
        else height = width / videoRatio;
        return {
          width: width,
          height: height
        };
    }

    });

    function requestControl() {
      if (websocket.readyState === WebSocket.OPEN) {
        websocket.send(JSON.stringify({ msg_type: "REQUEST_CONTROL" }));
      }
    }

    function requestPreempt() {
      if (websocket.readyState === WebSocket.OPEN) {
        websocket.send(JSON.stringify({ msg_type: "REQUEST_PREEMPT" }));
      }
    }

    return {
      showPreemptButton,
      requestControl,
      requestPreempt,
      videoWrapper,
      video
    };
  },
};
</script>

<style scoped>
.video-container {
  position: relative;
  width: 100%;
  height: 100%;
  overflow: hidden;
}

.video-wrapper {
  width: 100vw;
  height: 100vh;
}

.fullscreen-video {
  position: absolute;
  width: 100vw;
  z-index: -100;
  background: no-repeat;
  background-size: cover;
  transform-origin: top left;
  transition: transform 0.2s ease;
}


.top-right, .bottom-right {
  position: absolute;
  z-index: 100;
  background: rgba(0, 0, 0, 0.5); /* Semi-transparent black background */
  border-radius: 25%;  /* Keeps the background round */
  padding: 5px;  /* Spacing around the icon */
}

.top-right {
  top: 10px;
  right: 10px;
}

.bottom-right {
  bottom: 10px;
  right: 10px;
}

.bottom-left {
  bottom: 10px;
  left: 10px;
  z-index: 100;
  position: absolute;
}
</style>
