<template>
  <q-page class="video-container">
    <div class="backdrop"></div>

    <div class="video-wrapper" ref="videoWrapper">
      <CameraStream
        ref="video"
        :onplay="videoOnPlay"
        :onpause="videoOnPause"
        :controls="isFullscreen && isIOS"
      />
    </div>

    <div :class="interactionIdleTimeExpired ? 'fade-out controls-container bottom-right' : 'controls-container bottom-right'">
      <q-btn @click="toggleFullScreen">
        <q-icon :name="isFullscreen ? 'fullscreen_exit' : 'fullscreen'" color="white" size="2rem" />
      </q-btn>

      <q-btn @click.prevent="toggleRecording">
        <q-icon :style="isVideoDownloading ? 'visibility: hidden' : ''"
                :name="isRecording ? 'stop_circle' : 'video_call'"
                :color="isRecording ? recordingBlinker : (isStreamLoading || !supportsMediaRecorder ? 'grey-9' : 'white')"
                size="2rem" />
        <q-spinner-oval v-if="isVideoDownloading" color="grey-6" size="2rem" thickness="2" class="absolute center-spinner" />
      </q-btn>

      <q-btn @click="takeScreenShot">
        <q-icon :style="isPhotoDownloading ? 'visibility: hidden' : ''"
                name="add_a_photo"
                :color="isStreamLoading ? 'grey-9' : 'white'" size="2rem" />
        <q-spinner-oval v-if="isPhotoDownloading" color="grey-6" size="2rem" thickness="2" class="absolute center-spinner" />
      </q-btn>
    </div>

    <!-- Spinner shown while stream loads -->
    <q-inner-loading :showing="isStreamLoading"
                     transition-duration="2000"
                     transition-show="none"
                     :class="splashLoading ? 'dark-background' : ''">
      <q-img src="icons/Wildstream_logo.png" width="24vw" class="absolute" :style="splashLoading ? '' : 'display: none;'" />
      <q-spinner color="color-sunset-1" :size="splashLoading ? '30vw' : '20vw'" thickness="1" class="absolute"/>
      <h4 class="absolute text-color-sunset-1 big-font" :style="splashLoading ? 'display: none' : ''">Reconnecting...</h4>
    </q-inner-loading>

    <div ref="recording-indicator"
         :class="recordingBlinker == 'red' ? 'recording-indicator' : 'recording-indicator dark-border'"
         :style="isRecording ? '' : 'display: none'"></div>

    <q-img class="bottom-left" width="3rem" src="icons/Wildstream_logo.png" />
  </q-page>
</template>

<script>
import { ref, onMounted } from 'vue';
import { useQuasar } from 'quasar';
import CameraStream from '../components/CameraStream.vue';

export default {
  name: 'PageIndex',
  components: { CameraStream },

  setup() {
    const $q = useQuasar();

    const videoWrapper = ref(null);
    const video = ref(null);
    const splashLoading = ref(true);
    const isRecording = ref(false);
    const recordingBlinker = ref("red");
    const isPhotoDownloading = ref(false);
    const isVideoDownloading = ref(false);
    const isStreamingMode = ref(true);
    const isStreamLoading = ref(true);
    const streamLoadingBlinker = ref(false);
    const interactionIdleTimeExpired = ref(false);
    const isFullscreen = ref(false);
    const isIOS = ref(detectIOS());
    const supportsMediaRecorder = ref(window.MediaRecorder !== undefined);
    const streamDidStart = ref(false);

    let interactionTimeoutHandler;
    let videoRef;
    let frameCanvas = document.createElement('canvas');
    let frameCanvasCtx = frameCanvas.getContext('2d');
    let mediaRecorder;
    let recordedChunks = [];
    let recordedBlob;
    let canvasAnimationHandle;
    let recordedVideoFrames = [];

    setInterval(() => {
      recordingBlinker.value = recordingBlinker.value == "red" ? "black" : "red";
      streamLoadingBlinker.value = !streamLoadingBlinker.value
    }, 1000);

    function detectIOS() {
      if (/iPad|iPhone|iPod/.test(navigator.platform)) return true;
      return navigator.maxTouchPoints && navigator.maxTouchPoints > 2 && /MacIntel/.test(navigator.platform);
    }

    function videoOnPlay() { console.log("Video playing"); }
    function videoOnPause() { console.log("Video paused"); }

    function drawVideoFrameToCanvas() {
      frameCanvas.width = videoRef.videoWidth;
      frameCanvas.height = videoRef.videoHeight;
      frameCanvasCtx.drawImage(videoRef, 0, 0, frameCanvas.width, frameCanvas.height);
    }

    function takeScreenShot() {
      if (isStreamLoading.value || isPhotoDownloading.value) return;
      isPhotoDownloading.value = true;

      try {
        drawVideoFrameToCanvas();
        const dataURL = frameCanvas.toDataURL('image/png', 1);
        const filename = `wildstream_${new Date().toISOString().replace(/[:.]/g, '-')}.png`;
        const link = document.createElement('a');
        link.href = dataURL;
        link.download = filename;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
      } catch (e) {
        $q.notify({ type: 'negative', message: 'Screenshot failed: ' + e.message });
      } finally {
        isPhotoDownloading.value = false;
      }
    }

    function toggleRecording() {
      if (!supportsMediaRecorder.value) {
        $q.notify({ type: 'warning', message: 'Browser does not support native video recording' });
        return;
      }
      if (isStreamLoading.value || isVideoDownloading.value) return;

      isRecording.value = !isRecording.value;
      if (isRecording.value) startRecording();
      else stopRecording();
    }

    function startRecording() {
      let stream;
      if (!supportsMediaRecorder.value) {
        recordedVideoFrames = [];
        function step() {
          drawVideoFrameToCanvas();
          recordedVideoFrames.push(frameCanvas.toDataURL('image/jpeg', 0.9));
          canvasAnimationHandle = window.requestAnimationFrame(step);
        }
        canvasAnimationHandle = window.requestAnimationFrame(step);
        stream = frameCanvas.captureStream();
      } else {
        try {
          stream = videoRef.captureStream();
        } catch (e) {
          $q.notify({ type: 'negative', message: 'Error capturing stream: ' + e.message });
          return;
        }
      }

      try {
        mediaRecorder = new MediaRecorder(stream, { mimeType: 'video/mp4' });
      } catch (e) {
        $q.notify({ type: 'negative', message: 'Error creating recorder: ' + e.message });
        return;
      }

      recordedChunks = [];
      mediaRecorder.ondataavailable = (e) => { if (e.data.size) recordedChunks.push(e.data); };
      mediaRecorder.onstop = () => {
        recordedBlob = new Blob(recordedChunks, { type: 'video/mp4' });
        downloadVideo();
      };
      mediaRecorder.onerror = (e) => {
        $q.notify({ type: 'negative', message: 'Recording error: ' + e.message });
      };

      mediaRecorder.start();
    }

    function stopRecording() {
      if (!supportsMediaRecorder.value) {
        cancelAnimationFrame(canvasAnimationHandle);
        downloadVideo();
      } else {
        try { mediaRecorder.stop(); }
        catch (e) {
          $q.notify({ type: 'negative', message: 'Stop error: ' + e.message });
        }
      }
    }

    function downloadVideo() {
      isVideoDownloading.value = true;
      try {
        const filename = `wildstream_${new Date().toISOString().replace(/[:.]/g, '-')}.mp4`;
        const url = URL.createObjectURL(recordedBlob);
        const a = document.createElement('a');
        document.body.appendChild(a);
        a.style = 'display:none';
        a.href = url;
        a.download = filename;
        a.click();
        URL.revokeObjectURL(url);
        document.body.removeChild(a);
      } finally {
        isVideoDownloading.value = false;
      }
    }

    function toggleFullScreen() {
      if (!isFullscreen.value) {
        const elem = document.documentElement;
        if (isIOS.value) videoRef.webkitEnterFullscreen();
        else elem.requestFullscreen?.();
      } else document.exitFullscreen?.();
      isFullscreen.value = !isFullscreen.value;
    }

    function voidIdleTimer() {
      interactionIdleTimeExpired.value = false;
      clearInterval(interactionTimeoutHandler)
    }

    function resetIdleTimer() {
      interactionIdleTimeExpired.value = false;
      clearTimeout(interactionTimeoutHandler)
      interactionTimeoutHandler = setTimeout(() => {
        interactionIdleTimeExpired.value = true
      }, 15000)
    }

    window.addEventListener('mousemove', resetIdleTimer);
    window.addEventListener('mousedown', resetIdleTimer);
    window.addEventListener('keypress', resetIdleTimer);
    window.addEventListener('touchmove', resetIdleTimer);

    onMounted(() => {
      videoRef = video.value.getVideoElem();
      supportsMediaRecorder.value = supportsMediaRecorder.value && videoRef.captureStream !== undefined;

      videoRef.addEventListener("playing", () => {
        streamDidStart.value = true;
        isStreamLoading.value = false;
        splashLoading.value = false;
      });

      setTimeout(() => {
        if (!streamDidStart.value && isStreamingMode.value) {
          splashLoading.value = false;
          $q.notify({
            type: 'negative',
            position: 'top',
            message: "Failed to reach the camera. The camera stream may be down.",
            timeout: 8000
          })
        }
      }, 5000);
    });

    return {
      videoWrapper, video,
      isRecording, recordingBlinker,
      isPhotoDownloading, isVideoDownloading,
      isStreamingMode, isStreamLoading, splashLoading,
      streamDidStart, streamLoadingBlinker,
      interactionIdleTimeExpired, isFullscreen, isIOS,
      supportsMediaRecorder,
      takeScreenShot, toggleRecording,
      videoOnPlay, videoOnPause, toggleFullScreen,
      voidIdleTimer, resetIdleTimer
    };
  },
};
</script>

<style scoped>
/* ⬇ same working styles you had (with fullscreen video fix) */
html { position: fixed; }
.backdrop {
  position: absolute; width: 100vw; height: 100vh;
  z-index: -1; background: var(--q-color-very-dark-background);
}
.recording-indicator {
  position: absolute; width: 100vw; height: 100vh;
  top: 0; left: 0; z-index: 1;
  border: 4px solid red; border-radius: 4px; pointer-events: none;
}
.dark-border { border: 4px solid var(--q-color-sunset-2); }
.video-container {
  position: relative; width: 100%; height: 100%;
  margin: 0; position: absolute; top: 50%;
  transform: translateY(-50%); overflow: hidden;
}
.video-wrapper { width: 100vw; height: 100vh; position: relative; }
.video-wrapper video {
  position: absolute; top: 0; left: 0;
  width: 100vw; height: 100vh; object-fit: cover; background: black;
}
.bottom-right { position: absolute; bottom: 3vh; right: 3vh; z-index: 1; }
.bottom-left { position: absolute; bottom: 3vh; left: 3vh; z-index: 1; }
.controls-container {
  z-index: 2; display: flex; flex-direction: column;
  align-items: center; padding: 0.1rem;
  background: rgba(255, 255, 255, 0.2); border-radius: 1.5rem;
  opacity: 1; transition: opacity 1s ease;
}
.fade-out { opacity: 0; pointer-events: none; }
.center-spinner { left: 0; right: 0; margin: auto; }
</style>
