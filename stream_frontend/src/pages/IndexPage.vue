<template>
  <q-page class="video-container">

    <div class="backdrop"></div>

    <div class="video-wrapper" ref="videoWrapper">
      <CameraStream ref="video" :onplay="videoOnPlay" :onpause="videoOnPause" />
    </div>

    <!--
    <q-btn round dense flat class="top-right" :ripple="false">
      <q-icon name="battery_full" size="lg" color="white" />
    </q-btn>
    -->

    <q-fab class="absolute bottom-right fab-button fab-button-big"
           v-model="settings"
           label=""
           vertical-actions-align="right"
           color="color-dark-green"
           icon="settings"
           direction="up"
           persistent
           @click.stop
           @click.prevent>
      <q-fab-action color="color-sunset-1" @click="takeScreenShot" icon="photo_camera" class="fab-button"/>
      <q-fab-action :color="isRecording ? recordingBlinker : 'color-sunset-2'" @click.prevent="toggleRecording" :icon="isRecording ? 'stop_circle' : 'videocam'" class="fab-button"/>
      <q-fab-action color="color-sunset-2" @click="toggleStreamMode" :icon="isStreamingMode ? 'preview' : 'smart_display'" class="fab-button"/>
      <q-fab v-model="qualityControl"
             label=""
             color="color-sunset-4"
             :icon="qualityControlIcon"
             direction="left"
             class="fab-button-inside"
             persistent>
            <q-fab-action color="color-sunset-4" @click="setQuality('low')" icon="cell_tower" label="Better Reliability"/>
            <q-fab-action color="color-sunset-4" @click="setQuality('high')" icon="speed" label="Better Quality"/>
      </q-fab>
      <!--<q-fab-action color="info" class="fab-button" @click="toggleHelp" icon="help" />-->
      <q-btn color="info" icon="help" class="fab-button">
        <q-popup-proxy>
          <q-banner>
            <template v-slot:avatar>
              <q-icon name="help" color="info" />
            </template>
            This is a help menu! But there is nothing helpful here yet...
          </q-banner>
        </q-popup-proxy>
      </q-btn>
    </q-fab>

    <q-inner-loading id="splashLoading" :showing="splashLoading"
                     transition-duration="2000"
                     transition-show="none">
        <q-img src="icons/favicon-240x240.png" width="24vw" class="absolute" />

        <q-spinner
          color="color-sunset-1"
          size="30vw"
          thickness="1"
          class="absolute"
        />
    </q-inner-loading>

    <q-inner-loading id="streamLoading" :style="isStreamLoading ? '' : 'display: none'"
                     transition-duration="2000"
                     transition-show="none">

        <q-spinner
          color="color-sunset-1"
          size="30vw"
          thickness="1"
          class="absolute"
        />
    </q-inner-loading>

    <q-inner-loading id="screenMode" :style="isStreamingMode ? 'display: none' : ''"
                     transition-duration="2000"
                     transition-show="none">
        <q-img src="icons/favicon-240x240.png" width="24vw" class="absolute" />

        <q-spinner
          size="0vw"
          thickness="0"
          class="absolute"
        />
    </q-inner-loading>

    <div ref="recording-indicator" :class="recordingBlinker == 'red' ? 'recording-indicator' : 'recording-indicator dark-border'" :style="isRecording ? '' : 'display: none'"></div>

    <q-icon class="stream-down-indicator" color="red" :style="isStreamLoading ? '' : display: none;'" :icon="isStreamLoading && streamLoadingBlinker ? 'wifi' : 'wifi_off'" />

  </q-page>
</template>

<script>
//import videojs from 'video.js';
//import 'video.js/dist/video-js.css';
import { ref, onMounted } from 'vue';
import { useQuasar } from 'quasar';
import CameraStream from '../components/CameraStream.vue';

export default {
  name: 'PageIndex',

  components: {
    CameraStream,
  },

  setup() {
    const $q = useQuasar()

    const videoWrapper = ref(null);
    const video = ref(null);
    const splashLoading = ref(true);
    const settings = ref(null);
    const qualityControl = ref(null);
    const qualityControlIcon = ref("speed");
    const isRecording = ref(false);
    const recordingBlinker = ref("red")
    const recordingIndicator = ref(null);
    const isStreamingMode = ref(true);
    const isStreamLoading = ref(false)
    const streamLoadingBlinker = ref(false)

    let lastVidTime = 0;

    let mediaRecorder;
    let recordedBlob;
    let recordedChunks = [];

    let socketPingHandle = 0;
    let websocket;

    /*
    // This should be handled by monitorStreamStatus()
    setTimeout(() => {
      splashLoading.value = false;
    }, 2000);
    */

    setInterval(() => {
      recordingBlinker.value = recordingBlinker.value == "red" ? "black" : "red";
      streamLoadingBlinker.value = !streamLoadingBlinker.value
    }, 1000);

    function setupWebSocket()
    {
      var url = new URL('/control', window.location.href);
      url.protocol = url.protocol.replace('http', 'ws');
      websocket = new WebSocket(url.href);
      
      websocket.onopen = () => {
        // Acquire control when socket opens
        console.log("Websocket opened")

        if (socketPingHandle)
        {
          clearInterval(socketPingHandle)
        }
        // Ping pong, most browsers time out the websocket at 1 minute
        clearInterval(socketPingHandle)
        socketPingHandle = setInterval(() => { websocket.send("ping") }, 29 * 1000)
      };
      
      websocket.onmessage = handleWebSocketMessage;

      websocket.onerror = (error) => {
        console.error("WebSocket Error", error);
      };

      websocket.onclose = (event) => {
        if (event.wasClean)
        {
          console.log(`Closed cleanly, code=${event.code}, reason=${event.reason}`);
        }
        else
        {
          console.error('Connection died');
        }
        
        // Attempt to reconnect after a delay
        setTimeout(() => {
          setupWebSocket();
        }, 1000); // Wait for 1 second before attempting to reconnect
      };
    }

    function handleWebSocketMessage(event)
    {
      if (event.data == "pong")
      {
        return;
      }

      const data = JSON.parse(event.data);
    }

    function takeScreenShot(event)
    {
      event.stopPropagation();
      event.preventDefault();
      settings.value = true
      let canvas = document.createElement('canvas');

      // Set the canvas dimensions to the video dimensions
      canvas.width = video.value.getVideoElem().videoWidth;
      canvas.height = video.value.getVideoElem().videoHeight;

      // Draw the video frame to the canvas
      let ctx = canvas.getContext('2d');
      ctx.drawImage(video.value.getVideoElem(), 0, 0, canvas.width, canvas.height);

      // Convert the canvas to a data URL
      let dataURL = canvas.toDataURL('image/png');

      // Create a link element, set the download attribute with a filename
      const date = new Date();
      const filename = `wildstream_${new Date().toISOString().replace(/\..+/, '').replace(/:/g, '-').replace(/T/, ':')}.png`;
      let link = document.createElement('a');
      link.href = dataURL;
      link.download = filename;

      // Append the link to the body, click it, and remove it
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
    }

    function toggleRecording(event)
    {
      isRecording.value = !isRecording.value;

      event.stopPropagation();
      event.preventDefault();
      settings.value = true

      if (isRecording.value)
      {
        startRecording()
      }
      else
      {
        mediaRecorder.stop()
      }
    }

    function toggleStreamMode(event)
    {
      isStreamingMode.value = !isStreamingMode.value;

      event.stopPropagation();
      event.preventDefault();
      settings.value = true

      if (websocket && websocket.readyState === WebSocket.OPEN)
      {
        websocket.send(JSON.stringify({ msg_type: "stream_mode", data: isStreamingMode.value ? "wifi" : "screen" }));
      }
      else
      {
        $q.notify({
          type: 'negative',
          position: 'top',
          message: 'Failed to reach the Camera. Try waiting or refresh the screen.'
        })
      }
    }

    function setQuality(quality)
    {
      if (websocket && websocket.readyState === WebSocket.OPEN)
      {
        websocket.send(JSON.stringify({ msg_type: "quality", data: "low" }));

        if (quality == "low")
        {
          qualityControlIcon.value = "cell_tower";
        }
        else
        {
          qualityControlIcon.value = "speed";
        }
      }
      else
      {
        $q.notify({
          type: 'negative',
          position: 'top',
          message: 'Failed to reach the Camera. Try waiting or refresh the screen.'
        })
      }
    }

    function startRecording()
    {
      const options = { mimeType: "video/webm; codecs=vp9" };
      console.log(video.value.getVideoElem())
      const stream = video.value.getVideoElem().captureStream(); // This captures the stream from the video element
      mediaRecorder = new MediaRecorder(stream, options);

      mediaRecorder.ondataavailable = (event) => {
        if (event.data.size > 0) {
          recordedChunks.push(event.data);
        }
      };

      mediaRecorder.onstop = () => {
        recordedBlob = new Blob(recordedChunks, {
          type: "video/webm",
        });
        recordedChunks = []; // Clear the recorded chunks
        downloadVideo();
      };

      mediaRecorder.start();
    }

    function downloadVideo()
    {
      mediaRecorder.stop()
      const url = URL.createObjectURL(recordedBlob);
      const a = document.createElement("a");
      document.body.appendChild(a);
      a.style = "display: none";
      a.href = url;
      const filename = `wildstream_${new Date().toISOString().replace(/\..+/, '').replace(/:/g, '-').replace(/T/, ':')}.webm`;
      a.download = filename;
      a.click();
      window.URL.revokeObjectURL(url);
      document.body.removeChild(a);
    }

    function videoOnPlay() {
      console.log("Video playing")
    }
    function videoOnPause() {
      console.log("Video paused")
    }

    function monitorStreamStatus()
    {
      const vidRef = video.value.getVideoElem();
      if (!vidRef)
      {
        return;
      }

      const vidTime = vidRef.currentTime;

      console.log(vidTime)
      if (vidTime > lastVidTime)
      {
        isStreamLoading.value = false;
      }
      else
      {
        isStreamLoading.value = true;
      }
      lastVidTime = vidTime;
    }

    onMounted(() => {
      //setupWebSocket();

      setInterval(monitorStreamStatus, 500)
    });

    return {
      // Element References
      videoWrapper,
      video,
      settings,
      qualityControl,
      recordingIndicator,

      // Variables
      splashLoading,
      qualityControlIcon,
      isRecording,
      recordingBlinker,
      isStreamingMode,
      streamLoadingBlinker,

      // Functions
      takeScreenShot,
      toggleRecording,
      setQuality,
      toggleStreamMode,
      videoOnPlay,
      videoOnPause,
    };
  },
};
</script>

<style scoped>

.backdrop {
  position: absolute;
  width: 100vw;
  height: 100vh;
  z-index: -1;
  background: var(--q-color-dark-background);
}

.recording-indicator {
  /* pulse red border */
  position: absolute;
  width: 100vw;
  height: 100vh;
  top: 0;
  left: 0;
  z-index: 100;
  border: 4px solid red;
  border-radius: 4px;
}

.dark-border {
  border: 4px solid var(--q-color-sunset-2);
}

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

.bottom-right {
  bottom: 5vh;
  right: 5vh;
}

.q-inner-loading {
  background-color: var(--q-color-dark-background);
}

.fab-button, .fab-button-inside {
  width: 4vw;
  height: 4vw;
}
div.fab-button-big {
  width: 5vw;
  height: 5vw;
}
:deep(.fab-button-big > a) {
  border-radius: 5vw;
}
:deep(.fab-button-inside > a) {
  border-radius: 4vw;
}

:deep(div.q-fab--form-rounded, .fab-button, .fab-button-big) {
  margin: 0;
}
button.fab-button {
  margin: 0;
  border-radius: 100%;
}
:deep(.q-fab__actions) {
  margin: 0;
}
div.fab-button-inside, :deep(.q-fab__actions--opened>a.q-fab--form-rounded) {
  margin: 0;
  margin-top: 2vh;
  margin-left: 1vw;
  border-radius: 5vw;
}
:deep(div.q-fab__actions--opened) {
  margin-bottom: 3vh !important;
}
:deep(div.fab-button-inside > .q-fab__actions--opened) {
  margin-right: 1vw !important;
}
:deep(.fab-button-inside > a) {
  margin: 0;
}
</style>
