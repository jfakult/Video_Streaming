<template>
  <!-- meta tag also added to header in index.html to allow pinch zooming -->
  <q-page class="video-container">

    <div class="backdrop"></div>

    <div class="video-wrapper" ref="videoWrapper">
      <!-- EDIT AS NEEDED -->
      <CameraStream ref="video" :onplay="videoOnPlay" :onpause="videoOnPause" :controls="isFullscreen && isIOS" />
      
<!--
      <video ref="video" class="fullscreen-video" controls playsinline autoplay muted loop>
        <source src="video/sample-5s.mp4" type="video/mp4">
      </video>
    -->
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
          @hide="resetIdleTimer">
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
        <q-icon :style="isVideoDownloading ? 'visibility: hidden' : ''" :name="isRecording ? 'stop_circle' : 'video_call'" :color="isRecording ? recordingBlinker : (isStreamLoading || !supportsMediaRecorder ? 'grey-9' : 'white')" size="2rem" />
        <q-spinner-oval
              :style="isVideoDownloading ? '' : 'display: none;'"
              color="grey-6"
              size="2rem"
              thickness="2"
              class="absolute center-spinner"
            />
      </q-button>

      <q-button @click="takeScreenShot">
        <q-icon :style="isPhotoDownloading ? 'visibility: hidden' : ''" name="add_a_photo" :color="isStreamLoading ? 'grey-9' : 'white'" size="2rem" />
        <q-spinner-oval
            :style="isPhotoDownloading ? '' : 'display: none;'"
            color="grey-6"
            size="2rem"
            thickness="2"
            class="absolute center-spinner"
          />
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
    <q-inner-loading :showing="isStreamLoading && isStreamingMode"
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
        <q-img src="icons/Wildstream_logo.png" class="logo-size absolute" />

        <div class="absolute text-white big-font">The stream has been<br>redirected to the scope</div>

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
/*
import { FFmpeg } from '@ffmpeg/ffmpeg';
import { toBlobURL } from '@ffmpeg/util';
*/

export default {
  name: 'PageIndex',

  components: {
    // EDIT AS NEEDED
    CameraStream,
  },

  setup() {
    const $q = useQuasar()

    const videoWrapper = ref(null);
    const video = ref(null);
    const splashLoading = ref(true); // probably don't need this anymore
    const helpPopup = ref(null);
    //const qualityControl = ref(null);
    const streamModeControl = ref("");
    //const qualityControlIcon = ref("speed");
    //const streamControlIcon = ref("wifi")
    const isRecording = ref(false);
    const recordingBlinker = ref("red");
    const recordingIndicator = ref(null);
    const isPhotoDownloading = ref(false);
    const isVideoDownloading = ref(false);
    const isStreamingMode = ref(true);
    const isStreamLoading = ref(true);
    const streamLoadingBlinker = ref(false);
    const interactionIdleTimeExpired = ref(false);
    const isFullscreen = ref(false);
    const isIOS = ref(detectIOS());
    const supportsMediaRecorder = ref(window.MediaRecorder !== undefined);

    notifyWarning("Touch points:" + navigator.maxTouchPoints + "\nSystem Platform: " + navigator.platform + "\n" + "User Agent: " + navigator.userAgent + "\n" + "Is iOS: " + isIOS.value + "\n" + "Supports Media Recorder: " + supportsMediaRecorder.value)

    /*let ffmpeg;
    if (!supportsMediaRecorder.value)
    {
      ffmpeg = new FFmpeg();
      (async () => {
        ffmpeg.on('log', ({ message }) => {
            console.log(message);
        });
        if (!crossOriginIsolated) SharedArrayBuffer = ArrayBuffer;
        await ffmpeg.load({
          coreURL: new URL("js/ffmpeg-core.js", window.location.href).href,
          wasmURL: new URL("js/ffmpeg-core.wasm", window.location.href).href,
          workerURL: new URL("js/ffmpeg-core.worker.js", window.location.href).href,
        });
        console.log("FFmpeg loaded")
        //await ffmpeg.load()
      })();
    }
    */

    const DEBUG_MODE = ref(window.location.search.includes("debug") || window.location.search.includes("DEBUG"))

    const streamDidStart = ref(false)
    let lastVidTime = 0;
    let PAGE_LOAD_TIMEOUT = 5000;
    let canvasRecorder;
    let recordedVideoFrames = [];
    let mediaRecorder;
    let recordedBlob;
    let recordedChunks = [];
    let videoRef;

    let gotWebsocketInitMessage = false;
    const SERVER_COMMUNICATION_TIMEOUT = 3000; // If the server doesn't respond in this time, show an error
    const STREAM_MONITOR_INTERVAL = 500;      // The rate at which we check if the stream is loading
    const WEBSOCKET_RESTART_INTERVAL = 1000;   // The rate at which we attempt to reconnect to the websocket
    let socketPingHandle = 0;
    let qualityModeHandle = 0;
    let streamModeHandle = 0;
    let interactionTimeoutHandler = 0;
    let websocket;
    // Canvas for drawing video frames, used for screenshots and video recordings
    let frameCanvas = document.createElement('canvas');
    let frameCanvasCtx = frameCanvas.getContext('2d');
    let canvasAnimationHandle = 0;

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
          message: msg ? msg : 'Something went wrong, try refreshing the page',
          timeout: 8000,
          actions: [
            { icon: 'close', color: 'white', round: true, handler: () => { /* ... */ } }
          ]
      })
      console.log("Sending error message: " + msg)
    }

    function notifyWarning(msg)
    {
      $q.notify({
          type: 'warning',
          position: 'top',
          message: msg ? msg : 'Something went wrong, try refreshing the page',
        timeout: 8000,
          multiLine: true,
          actions: [
            { icon: 'close', color: 'white', round: true, handler: () => { /* ... */ } }
          ]
      })
      console.log("Sending warning message: " + msg)
    }

    function detectIOS()
    {
      if (/iPad|iPhone|iPod/.test(navigator.platform)) {
        return true;
      } else { // iPad Pro reports itself as running MacOSX
        return navigator.maxTouchPoints && (navigator.maxTouchPoints > 2) && /MacIntel/.test(navigator.platform)
      }
    }

    function setupWebSocket()
    {
      var url = new URL('/control', window.location.href);
      // EDIT AS NEEDED
      url.protocol = url.protocol.replace('http', 'ws');
      //url.protocol = url.protocol.replace('https', 'wss');
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

        // Add this?
        //streamModeControl.value = "stream"
        //toggleStreamMode("stream") 
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
          gotWebsocketInitMessage = true;
          clearTimeout(streamModeHandle);
          isStreamingMode.value = data.data == "stream" ? true : false;
          streamModeControl.value = data.data == "stream" ? "stream" : "scope";
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

    function drawVideoFrameToCanvas()
    {
      // Set the canvas dimensions to the video dimensions
      frameCanvas.width = videoRef.videoWidth;
      frameCanvas.height = videoRef.videoHeight;

      // Draw the video frame to the canvas
      frameCanvasCtx.drawImage(videoRef, 0, 0, frameCanvas.width, frameCanvas.height);
    }

    function takeScreenShot(event)
    {
      event.stopPropagation();
      event.preventDefault();

      if (isStreamLoading.value || isPhotoDownloading.value)
      {
        return;
      }

      isPhotoDownloading.value = true;
      
      drawVideoFrameToCanvas();

      // Convert the canvas to a data URL
      let dataURL = frameCanvas.toDataURL('image/png', 1);

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
      isPhotoDownloading.value = false;
    }

    function toggleRecording(event)
    {
      if (!supportsMediaRecorder.value)
      {
        //notifyWarning("Warning, this browser does not support native video recording. The resulting video may display lower quality or framerates")
        notifyWarning("Warning, this browser does not support native video recording. In order to record try updating the current browser or use a different browser such as Google Chrome.")
        return;
      }
      if (isStreamLoading.value || isVideoDownloading.value)
      {
        return;
      }

      isRecording.value = !isRecording.value;

      if (event)
      {
        event.stopPropagation();
        event.preventDefault();
      }

      // Note these seem backwards, but we flip the bool above
      if (isRecording.value)
      {
        recordedVideoFrames = [];
        startRecording()
      }
      else
      {
        stopRecording()
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

    function stopRecording()
    {
      notifyWarning("stopping recording: " + supportsMediaRecorder.value)
      if (!supportsMediaRecorder.value)
      {
        cancelAnimationFrame(canvasAnimationHandle)
        downloadVideo();
      }
      else
      {
        notifyWarning("Calling stop on media recorder  " + mediaRecorder.state)
        mediaRecorder.stop();
      }
    }

    function startRecording()
    {
      let options;
      let type;
      let stream;

      if (!supportsMediaRecorder.value)
      {
        options = { mimeType: "video/mp4" };
        type = "video/mp4";
        function step() {
          drawVideoFrameToCanvas();
          recordedVideoFrames.push(frameCanvas.toDataURL('image/jpeg', 0.9));
          canvasAnimationHandle = window.requestAnimationFrame(step);
        }
        canvasAnimationHandle = window.requestAnimationFrame(step);
        stream = frameCanvas.captureStream();
      }
      else
      {
        options = { mimeType: "video/webm; codecs=vp9" };
        type = "video/webm";
        stream = videoRef.captureStream(); // This captures the stream from the video element
      }

      mediaRecorder = new MediaRecorder(stream);

      mediaRecorder.ondataavailable = (event) => {
        if (event.data.size > 0) {
          recordedChunks.push(event.data);
        }
      };

      mediaRecorder.onstop = () => {
        notifyWarning("media recorder stopped")
        recordedBlob = new Blob(recordedChunks, {
          type: "video/webm",
        });
        recordedChunks = []; // Clear the recorded chunks
        downloadVideo();
      };

      try
      {
        notifyWarning("mediarecorder starting recording")
        mediaRecorder.start();
        notifyWarning("media recorder started")
      }
      catch (e)
      {
        console.log("Failed to start recording: ", e)
      }
    }

    async function compileVideo(filename) {
      for (let i = 0; i < recordedVideoFrames.length; i++) {
        const frame = recordedVideoFrames[i];
        const response = await fetch(frame);
        const blob = await response.blob();
        const arrayBuffer = await blob.arrayBuffer();
        const uint8Array = new Uint8Array(arrayBuffer);
        await ffmpeg.writeFile(`frame${i}.jpeg`, uint8Array);
      }

      await ffmpeg.exec(['-framerate', '30', '-i', 'frame%d.jpeg', '-c:v', 'libx264', filename]);

      const data = await ffmpeg.readFile(filename);
      const videoBlob = new Blob([data.buffer], { type: 'video/mp4' });
      const url = URL.createObjectURL(videoBlob);

      // Save us some memory?
      recordedVideoFrames = [];

      return url;
    }

    function downloadVideo()
    {
      notifyWarning("starting download")
      isVideoDownloading.value = true;
      let filename;
      let url;
      try {
      if (supportsMediaRecorder.value)
      {
        filename = `wildstream_${new Date().toISOString().replace(/\..+/, '').replace(/:/g, '-').replace(/T/, ':')}.webm`;
        //mediaRecorder.stop()
        url = URL.createObjectURL(recordedBlob);
      }
      else
      {
        filename = `wildstream_${new Date().toISOString().replace(/\..+/, '').replace(/:/g, '-').replace(/T/, ':')}.mp4`;
        url = compileVideo(filename)
      }

      const a = document.createElement("a");
      document.body.appendChild(a);
      a.style = "display: none";
      a.href = url;
      a.download = filename;
      a.click();
      window.URL.revokeObjectURL(url);
      document.body.removeChild(a);
      isVideoDownloading.value = false;
    } catch(e) { notifyWarning("Error downloading video: " + e) }
    }

    function videoOnPlay() {
      console.log("Video playing")
    }
    function videoOnPause() {
      console.log("Video paused")
    }

    function monitorStreamStatus()
    {
      if (!videoRef || !gotWebsocketInitMessage)
      {
        return;
      }

      const vidTime = videoRef.currentTime;

      if (vidTime > lastVidTime)
      {
        streamDidStart.value = true;

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

      if (isIOS.value)
      {
        videoRef.webkitEnterFullscreen();
        return;
      }
      else
      {
        if (elem.requestFullscreen) {
          elem.requestFullscreen();
        } else if (elem.webkitRequestFullscreen) { /* Safari */
          elem.webkitRequestFullscreen();
        } else if (elem.msRequestFullscreen) { /* IE11 */
          elem.msRequestFullscreen();
        }
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

      videoRef = video.value.getVideoElem();
      //videoRef = video.value;

      setInterval(monitorStreamStatus, STREAM_MONITOR_INTERVAL)

      // If the stream never loads eventually, signal to the user that something went wrong
      setTimeout(() => {
        splashLoading.value = false;

        if (!streamDidStart.value && isStreamingMode.value)
        {
          notifyError("Failed to reach the camera. The camera stream may be down.")
        }
      }, PAGE_LOAD_TIMEOUT);

      videoRef.addEventListener("fullscreenchange", function () {
        if (!document.fullscreen)
        {
          isFullscreen.value = false
        }
      }, false);
      videoRef.addEventListener("mozfullscreenchange", function () {
          if (!document.mozIsFullScreen)
          {
            isFullscreen.value = false
          }
      }, false);
      videoRef.addEventListener("webkitfullscreenchange", function () {
          if (!document.webkitIsFullScreen)
          {
            isFullscreen.value = false
          }
      }, false);
    });

    return {
      // Element References
      videoWrapper,
      video,
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
      isIOS,
      supportsMediaRecorder,
      isPhotoDownloading,
      isVideoDownloading,
      streamDidStart,

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
html {
  position: fixed;
}

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
  /*z-index: -100;*/
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

.logo-size {
  top: 50%;
  transform: translateY(-50%);
  width: calc(15vw + 25vh);
  height: calc(15vw + 25vh);
}

.big-font {
  /* Place halfway plus size of spinner */
  top: calc(50vh - 7.5vw - 12.5vh - 72px);
  font-size: 18px;
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

.center-spinner {
  left: 0;
  right: 0;
  margin: auto;
}
</style>
