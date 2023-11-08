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
      <q-fab v-model="streamModeControl"
             label=""
             color="color-sunset-4"
             :icon="streamControlIcon"
             direction="left"
             class="fab-button-inside"
             persistent>
            <q-fab-action color="color-sunset-1" @click="toggleStreamMode('wifi')" icon="wifi" label="WiFi"/>
            <q-fab-action color="color-sunset-1" @click="toggleStreamMode('screen')" icon="smart_display" label="Scope Screen"/>
      </q-fab>
      <q-fab v-model="qualityControl"
             label=""
             color="color-sunset-4"
             :icon="qualityControlIcon"
             direction="left"
             class="fab-button-inside"
             persistent>
            <q-fab-action color="color-sunset-1" @click="setQuality('low')" icon="cell_tower" label="Better Reliability"/>
            <q-fab-action color="color-sunset-1" @click="setQuality('high')" icon="speed" label="Better Quality"/>
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

    <q-inner-loading :showing="isStreamLoading"
                     transition-duration="2000"
                     transition-show="none">

        <q-img src="icons/favicon-240x240.png" width="24vw" class="absolute" :style="splashLoading ? '' : 'display: none;'" />

        <q-spinner
          color="color-sunset-1"
          :size="splashLoading ? '30vw' : '20vw'"
          thickness="1"
          class="absolute"
        />
    </q-inner-loading>

    <q-inner-loading id="screenMode" :showing="!isStreamingMode" transition-duration="2000" transition-show="none">
        <q-img src="icons/favicon-240x240.png" width="24vw" class="absolute" />

        <q-spinner size="0vw" thickness="0" class="absolute" />
    </q-inner-loading>

    <div ref="recording-indicator" :class="recordingBlinker == 'red' ? 'recording-indicator' : 'recording-indicator dark-border'" :style="isRecording ? '' : 'display: none'"></div>

    <!-- Show when the stream is down (but not on initial page load) -->
    <q-icon class="top-right" size="4rem" color="color-sunset-2" :style="isStreamLoading && !splashLoading ? '' : 'display: none;'" :name="isStreamLoading && streamLoadingBlinker ? 'wifi' : 'wifi_off'" />

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
    const splashLoading = ref(true); // probably don't need this anymore
    const settings = ref(null);
    const qualityControl = ref(null);
    const streamModeControl = ref(null);
    const qualityControlIcon = ref("speed");
    const streamControlIcon = ref("wifi")
    const isRecording = ref(false);
    const recordingBlinker = ref("red")
    const recordingIndicator = ref(null);
    const isStreamingMode = ref(true);
    const isStreamLoading = ref(false)
    const streamLoadingBlinker = ref(false)

    let streamDidStart = false
    let lastVidTime = 0;
    let PAGE_LOAD_TIMEOUT = 10000;
    let mediaRecorder;
    let recordedBlob;
    let recordedChunks = [];

    const SERVER_COMMUNICATION_TIMEOUT = 1000; // If the server doesn't respond in this time, show an error
    const STREAM_MONITOR_INTERVAL = 500;      // The rate at which we check if the stream is loading
    const WEBSOCKET_RESTART_INTERVAL = 1000;   // The rate at which we attempt to reconnect to the websocket
    let socketPingHandle = 0;
    let qualityModeHandle = 0;
    let streamModeHandle = 0;
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

    function notifyError(msg)
    {
      $q.notify({
          type: 'negative',
          position: 'top',
          message: msg ? msg : 'Something went wrong, try refreshing the page'
      })
      console.log("Sending error message: " + msg)
    }

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
        }, WEBSOCKET_RESTART_INTERVAL);
      };
    }

    function handleWebSocketMessage(event)
    {
      if (event.data == "pong")
      {
        return;
      }

      console.log("Recieved message from server: ", event.data)

      try {
        const data = JSON.parse(event.data);

        if (data.message_type == "stream_mode")
        {
          clearInterval(streamModeHandle)
          isStreamingMode.value = data.data == "wifi" ? true : false;
          streamControlIcon.value = data.data == "wifi" ? "wifi" : "smart_display";
          streamModeControl.value = false // Close the menu
        }
        else if (data.message_type == "quality")
        {
          console.log("Recieved quality message")
          clearInterval(qualityModeHandle)
          qualityControlIcon.value = data.data == "low" ? "cell_tower" : "speed";
          qualityControl.value = false // Close the menu
        }
        else
        {
          console.log("Recieved unknown message type from server: ", data.message_type)
        }
      }
      catch (e)
      {
        console.log("Recieved invalid message from server: ", e)
      }
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

    function toggleStreamMode(mode)
    {
      streamModeControl.value = true

      if (websocket && websocket.readyState === WebSocket.OPEN)
      {
        websocket.send(JSON.stringify({ message_type: "stream_mode", data: mode }));
        streamModeHandle = setTimeout(() => { notifyError("The camera did not respond in time. Try waiting or refresh the screen.") }, SERVER_COMMUNICATION_TIMEOUT)
      }
      else
      {
        notifyError("Failed to reach the camera. Try waiting or refresh the screen.")
      }
    }

    function setQuality(quality)
    {
      qualityControl.value = true;

      if (websocket && websocket.readyState === WebSocket.OPEN)
      {
        websocket.send(JSON.stringify({ message_type: "quality", data: quality }));
        qualityModeHandle = setTimeout(() => { notifyError("The camera did not respond in time. Try waiting or refresh the screen.") }, SERVER_COMMUNICATION_TIMEOUT)
      }
      else
      {
        notifyError("Failed to reach the camera. Try waiting or refresh the screen.")
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

      if (vidTime > lastVidTime)
      {
        streamDidStart = true;

        isStreamLoading.value = false;
        // Only used so that we don't blink the "stream down" indicator on page load
        splashLoading.value = false
      }
      else
      {
        isStreamLoading.value = true;
      }
      lastVidTime = vidTime;
    }

    onMounted(() => {
      setupWebSocket();

      setInterval(monitorStreamStatus, STREAM_MONITOR_INTERVAL)

      // If the stream never loads eventually, signal to the user that something went wrong
      setTimeout(() => {
        splashLoading.value = false;

        if (!streamDidStart)
        {
          notifyError("Failed to reach the camera. The camera stream may be down.")
        }
      }, PAGE_LOAD_TIMEOUT);
    });

    return {
      // Element References
      videoWrapper,
      video,
      settings,
      qualityControl,
      streamModeControl,
      recordingIndicator,

      // Variables
      splashLoading,
      qualityControlIcon,
      isRecording,
      recordingBlinker,
      isStreamLoading,
      isStreamingMode,
      streamLoadingBlinker,
      streamControlIcon,

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
  margin: 0;
  position: absolute;
  top: 50%;
  -ms-transform: translateY(-50%);
  transform: translateY(-50%);
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
  position: absolute;
  bottom: 5vh;
  right: 5vh;
}

.top-right {
  position: absolute;
  top: 5vh;
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
