<template>
  <q-page class="video-container">
    <video
      id="my-video"
      class="video-js fullscreen-video"
      controls="false"
      autoplay
      loop
      muted
    >
      <source src="video/sample-5s.mp4" type="video/mp4">
      Your browser does not support the video tag.
    </video>

    <q-btn round dense flat class="top-right" :ripple="false">
      <q-icon name="battery_full" size="lg" color="white" />
    </q-btn>

    <q-btn round dense flat class="bottom-right" :ripple="false">
      <q-icon name="photo_camera" size="lg" color="white" />
    </q-btn>

    <div>
      <!-- Joystick Container -->
      <div ref="joystickContainer" class="bottom-left" style="width: 200px; height: 200px;"></div>

      <!-- Preempt Button -->
      <q-btn v-if="showPreemptButton" color="primary" text-color="white" label="Preempt" @click="requestPreempt" style="position: absolute; bottom: 20px; left: 20px;" />
  </div>
  </q-page>
</template>

<script>
//import videojs from 'video.js';
//import 'video.js/dist/video-js.css';
import nipplejs from 'nipplejs';
import { ref, onMounted } from 'vue';
import { Dialog } from 'quasar';

export default {
  name: 'PageIndex',
  setup() {
    const joystickContainer = ref(null);
    const showPreemptButton = ref(false);
    let joystick;
    let websocket;

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

      joystick = nipplejs.create({
        zone: joystickContainer.value,
        mode: 'static',
        position: { left: '50%', top: '50%' },
        size: 150,
      });

      joystick.on('move', (evt, data) => {
        if (websocket.readyState === WebSocket.OPEN) {
          const left_right = data.distance * Math.cos(data.angle.radian);
          const up_down = data.distance * Math.sin(data.angle.radian);
          websocket.send(JSON.stringify({
            msg_type: "POSITION",
            left_right,
            up_down
          }));
        }
      });
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
      joystickContainer,
      showPreemptButton,
      requestControl,
      requestPreempt,
    };
  },
};
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