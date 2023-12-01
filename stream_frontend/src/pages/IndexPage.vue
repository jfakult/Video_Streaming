<template>
  <!-- meta tag also added to header in index.html to allow pinch zooming -->
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

    <q-btn-toggle
      :class="interactionIdleTimeExpired ? 'fade-out bottom-right' : 'bottom-right'"
      v-model="streamModeControl"
      @update:model-value="toggleStreamMode"
      rounded
      color="grey-6"
      text-color="white"
      toggle-color="primary"
      :options="[
        {value: 'scope', slot: 'one'},
        {value: 'stream', slot: 'two'},
      ]" >
      <template v-slot:one>
        <div class="row items-center no-wrap">
          <div class="text-center">
            Scope
          </div>
        </div>
      </template>

      <template v-slot:two>
        <div class="row items-center no-wrap">
          <div class="text-center">
            Stream
          </div>
        </div>
      </template>
    </q-btn-toggle>

    <div :class="interactionIdleTimeExpired ? 'fade-out controls-container bottom-right' : 'controls-container bottom-right'">
      <q-button>
        <q-icon name="help" color="white" size="2rem" />
        <q-popup-proxy
          ref="helpPopup"
          @show="voidIdleTimer"
          @hide="resetIdleTimer"
          style="max-height: 80vh !important;">
          <q-banner>
            <!--<template v-slot:avatar>
              <q-icon name="help" color="color-dark-background" />
            </template>-->
            <div class="help-menu-header">
              <q-icon style="display: inline;" name="help" color="color-dark-background" size="3rem" />
              <h5 class="text-bold">User Guide</h5>
              <q-icon name="close" color="color-dark-background" size="2rem" class="close-button" @click="closeHelpMenu" />
            </div>
            <br />
            <q-button style="cursor: default; display: block; width: fit-content; margin-left: 0;">
              <q-icon name="add_a_photo" color="white" size="1.25rem" />
            </q-button>
            <div class="help-menu-text">This button will take a screenshot and save it!</div>
            <q-button style="cursor: default; display: block; width: fit-content; margin-left: 0;">
              <q-icon name="video_call" color="white" size="1.5rem" />
            </q-button>
            <div class="help-menu-text">This button starts a video recording of the stream! The blinking  <q-icon name="stop_circle" color="red" size="1.5rem" /> indicates it is recording. Press it again to save the video</div>
            <q-button style="cursor: default; display: block; width: fit-content; margin-left: 0;">
              <q-icon name="fullscreen" color="white" size="1.5rem" />
            </q-button>
            <div class="help-menu-text">This button toggles fullscreen mode</div>
            <q-btn-toggle
              v-model="streamModeControl"
              rounded
              class="tiny"
              color="grey-6"
              text-color="white"
              toggle-color="primary"
              style="pointer-events: none; margin-bottom: 8px; right: 0;"
              :options="[
                {value: 'scope', slot: 'one'},
                {value: 'stream', slot: 'two'},
              ]" >
              <template v-slot:one>
                <div class="row items-center no-wrap">
                  <div class="text-center">
                    Scope
                  </div>
                </div>
              </template>

              <template v-slot:two>
                <div class="row items-center no-wrap">
                  <div class="text-center">
                    Stream
                  </div>
                </div>
              </template>
            </q-btn-toggle>
            <div class="help-menu-text">Use this toggle to change where the stream points. <span class="text-bold">STREAM</span> mode will live stream to your device. <span class="text-bold">SCOPE</span> mode will display the stream on the round scope screen.</div>
            <div class="help-menu-text text-bold" style="margin-bottom: 0;">Reconnecting...</div>
            <div class="help-menu-text">If the stream is down, and does not come back in a few seconds, try refreshing the page. If this does not help, verify the WiFi is still connected, and if needed, disconnect and reconnect to <span class="text-bold">WildStreamWiFi</span>. As a final measure, power the WildStream device off and back on.</div>
          </q-banner>
        </q-popup-proxy>

      </q-button>

      <q-button @click="toggleFullScreen">
        <q-icon :name="isFullscreen ? 'fullscreen_exit' : 'fullscreen'" color="white" size="2rem" />
      </q-button>

      <q-button @click.prevent="toggleRecording">
        <q-icon :name="isRecording ? 'stop_circle' : 'video_call'" :color="isRecording ? recordingBlinker : (isStreamLoading ? 'grey-9' : 'white')" size="2rem" />
      </q-button>

      <q-button @click="takeScreenShot">
        <q-icon name="add_a_photo" :color="isStreamLoading ? 'grey-9' : 'white'" size="2rem" />
      </q-button>
      <!-- Vestigial features
      <q-fab v-model="qualityControl"
             label=""
             color="color-sunset-4"
             :icon="qualityControlIcon"
             direction="left"
             class="fab-button-inside"
             :style="DEBUG_MODE ? '' : 'display: none;'"
             persistent>
            <q-fab-action color="color-sunset-1" @click="setQuality('low')" icon="cell_tower" label="Better Reliability"/>
            <q-fab-action color="color-sunset-1" @click="setQuality('high')" icon="speed" label="Better Quality"/>
      </q-fab>
      -->
      <!--<q-fab-action color="info" class="fab-button" @click="toggleHelp" icon="help" />-->
    </div>

    <!-- The stream is loading -->
    <q-inner-loading :showing="isStreamLoading"
                     transition-duration="2000"
                     transition-show="none"
                     :class="splashLoading ? 'dark-background' : ''">

        <q-img src="icons/Wildstream_logo.png" width="24vw" class="absolute" :style="splashLoading ? '' : 'display: none;'" />

        <q-spinner
          color="color-sunset-1"
          :size="splashLoading ? '30vw' : '20vw'"
          thickness="1"
          class="absolute"
        />

        <h4 class="absolute text-color-sunset-1 big-font" :style="splashLoading ? 'display: none' : ''">Reconnecting...</h4>

    </q-inner-loading>

    <q-inner-loading id="screenMode" :showing="!isStreamingMode" transition-duration="2000" transition-show="none">
        <q-img src="icons/Wildstream_logo.png" width="60vh" class="absolute" style="top: 20vh;" />

        <h4 class="absolute text-white big-font" style="">The stream has been<br>redirected to the scope screen</h4>

        <!-- Disable the default spinner by creating an empty one -->
        <q-spinner size="0vw" thickness="0" class="absolute"/>
    </q-inner-loading>

    <div ref="recording-indicator" :class="recordingBlinker == 'red' ? 'recording-indicator' : 'recording-indicator dark-border'" :style="isRecording ? '' : 'display: none'"></div>

    <!--
    <div :class="interactionIdleTimeExpired ? 'fade-out controls-container top-right' : 'controls-container top-right'">
      <q-button @click="toggleFullScreen">
        <q-icon :name="isFullscreen ? 'fullscreen_exit' : 'fullscreen'" color="white" size="2rem" />
      </q-button>

      <!-=- Show when the stream is down (but not on initial page load) -->
      <!--
        <q-icon size="3rem" color="color-sunset-2" :style="isStreamLoading && !splashLoading ? '' : 'display: none;'" :name="isStreamLoading && streamLoadingBlinker ? 'wifi' : 'wifi_off'" />
      -=->
    </div>
    -->

    <q-img class="bottom-left" width="3rem" src="icons/Wildstream_logo.png" />

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
    const helpPopup = ref(null);
    //const qualityControl = ref(null);
    const streamModeControl = ref("stream");
    //const qualityControlIcon = ref("speed");
    //const streamControlIcon = ref("wifi")
    const isRecording = ref(false);
    const recordingBlinker = ref("red")
    const recordingIndicator = ref(null);
    const isStreamingMode = ref(true);
    const isStreamLoading = ref(true)
    const streamLoadingBlinker = ref(false)
    const interactionIdleTimeExpired = ref(false)
    const isFullscreen = ref(false)

    const DEBUG_MODE = ref(window.location.search.includes("debug") || window.location.search.includes("DEBUG"))

    let streamDidStart = false
    let lastVidTime = 0;
    let PAGE_LOAD_TIMEOUT = 5000;
    let mediaRecorder;
    let recordedBlob;
    let recordedChunks = [];

    const SERVER_COMMUNICATION_TIMEOUT = 1000; // If the server doesn't respond in this time, show an error
    const STREAM_MONITOR_INTERVAL = 500;      // The rate at which we check if the stream is loading
    const WEBSOCKET_RESTART_INTERVAL = 1000;   // The rate at which we attempt to reconnect to the websocket
    let socketPingHandle = 0;
    let qualityModeHandle = 0;
    let streamModeHandle = 0;
    let interactionTimeoutHandler = 0;
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
          //streamControlIcon.value = data.data == "wifi" ? "wifi" : "smart_display";
        }
        /*
        else if (data.message_type == "quality")
        {
          console.log("Recieved quality message")
          clearInterval(qualityModeHandle)
          qualityControlIcon.value = data.data == "low" ? "cell_tower" : "speed";
        }
        */
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

      if (isStreamLoading.value)
      {
        return;
      }

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
      console.log("Toggling recording", "Is recording: ", isRecording.value, "Is stream loading: ", isStreamLoading.value)
      if (isStreamLoading.value)
      {
        return;
      }

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

    /*function setQuality(quality)
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
    }*/

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

      try
      {
        mediaRecorder.start();
      }
      catch (e)
      {
        console.log("Failed to start recording: ", e)
      }
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
        // The stream crashed while we were recording, stop it and download the video
        if (isRecording.value)
        {
          toggleRecording()
        }

        isStreamLoading.value = true;
      }
      lastVidTime = vidTime;
    }

    function voidIdleTimer()
    {
      interactionIdleTimeExpired.value = false
      clearInterval(interactionTimeoutHandler)
      console.log(interactionIdleTimeExpired.value)
    }

    function resetIdleTimer()
    {
      interactionIdleTimeExpired.value = false
      clearTimeout(interactionTimeoutHandler)
      interactionTimeoutHandler = setTimeout(() => { interactionIdleTimeExpired.value = true }, 15000)
    }

    window.addEventListener('mousemove', resetIdleTimer);
    window.addEventListener('mousedown', resetIdleTimer);
    window.addEventListener('keypress', resetIdleTimer);
    window.addEventListener('touchmove', resetIdleTimer);

    function openFullscreen() {
      const elem = document.documentElement;
      if (elem.requestFullscreen) {
        elem.requestFullscreen();
      } else if (elem.webkitRequestFullscreen) { /* Safari */
        elem.webkitRequestFullscreen();
      } else if (elem.msRequestFullscreen) { /* IE11 */
        elem.msRequestFullscreen();
      }
    }

    /* Close fullscreen */
    function closeFullscreen() {
      if (document.exitFullscreen) {
        document.exitFullscreen();
      } else if (document.webkitExitFullscreen) { /* Safari */
        document.webkitExitFullscreen();
      } else if (document.msExitFullscreen) { /* IE11 */
        document.msExitFullscreen();
      }
    }

    function toggleFullScreen()
    {
      if (!isFullscreen.value)
      {
        openFullscreen();
      }
      else
      {
        closeFullscreen();
      }
      isFullscreen.value = !isFullscreen.value
    }

    function closeHelpMenu()
    {
      helpPopup.value.hide()
    }

    onMounted(() => {
      // EDIT AS NEEDED
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
      //qualityControl,
      streamModeControl,
      recordingIndicator,
      helpPopup,

      // Variables
      splashLoading,
      //qualityControlIcon,
      isRecording,
      recordingBlinker,
      isStreamLoading,
      isStreamingMode,
      streamLoadingBlinker,
      //streamControlIcon,
      DEBUG_MODE,
      interactionIdleTimeExpired,
      isFullscreen,

      // Functions
      takeScreenShot,
      toggleRecording,
      //setQuality,
      toggleStreamMode,
      videoOnPlay,
      videoOnPause,
      toggleFullScreen,
      voidIdleTimer,
      resetIdleTimer,
      closeHelpMenu,
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
  background: var(--q-color-very-dark-background);
}

.recording-indicator {
  /* pulse red border */
  position: absolute;
  width: 100vw;
  height: 100vh;
  top: 0;
  left: 0;
  z-index: 1;
  border: 4px solid red;
  border-radius: 4px;
  pointer-events: none;
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
  bottom: 3vh;
  right: 3vh;
  z-index: 1;
}

.bottom-left {
  position: absolute;
  bottom: 3vh;
  left: 3vh;
  z-index: 1;
}

.top-right {
  position: absolute;
  top: 3vh;
  right: 3vh;
}

.q-inner-loading {
  background-color: var(--q-color-very-dark-background);
}

.controls-container {
  z-index: 2;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  align-items: center;
  padding: 0.1rem;

  background: rgba(255, 255, 255, 0.2);
  border-radius: 1.5rem;

  opacity: 1;
  transition: opacity 1s ease;
}

.big-font {
  /* Place halfway plus size of spinner */
  top: calc(50vh + 10vw);
  font-size: calc(2vw + 2vh);
  line-height: 0;
  text-align: center;
}

q-button {
  background: var(--q-color-dark-background);
  border-radius: 1rem;
  padding: 0.5rem;
  margin: 12px;
  cursor: pointer;
}

.q-btn-group--rounded {
  border-radius: 1rem;
  opacity: 1;
  transition: opacity 1s ease;
  right: calc(6vh + 3rem + 24px);
  margin-bottom: 12px;
}

.fade-out {
  opacity: 0;
  pointer-events: none;
}

.dark-background {
  background: var(--q-color-dark-background);
}

/* Have to call from root to override quasar classes */
:global(.q-menu) {
  overflow-y: visible !important;
}

.center {
  left: 50%;
  transform: translate(-50%, 0%);
}

.text-center {
  text-align: center;
  display: inline-block;
  width: 100%;
}

.tiny {
  zoom: 0.8;
}

.popup-window {
  left: 3vh;
  right: 3vh;
}

.close-button {
  cursor: pointer;
  float: right;
  background: white;
  border-radius: 100%;
  height: 100%;
  line-height: 3rem;
}

.help-menu-text {
  font-size: 1.5rem;
  line-height: 1.5rem;
  max-width: calc(97vw - 0.5rem - 64px);
  margin-bottom: 2rem;
}

.help-menu-header {
  width: 100%;
  padding: 1rem;
  border-bottom: 1px solid grey;
}
.help-menu-header h5 {
  margin: 8px;
  vertical-align: middle;
  display: inline-block;
}
</style>
