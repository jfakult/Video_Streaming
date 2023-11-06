<template>
    <div id="camera-stream-container">
      <video ref="videoElement" id="video" autoplay playsinline></video>
    </div>
</template>
  
<script>
  export default {
    name: 'CameraStream',
    data() {
      return {
        restartPause: 2000,
        pc: null,
        restartTimeout: null,
        eTag: '',
        queuedCandidates: [],
        offerData: null
      };
    },
    methods: {
      unquoteCredential(v) {
        return JSON.parse(`"${v}"`);
      },
      linkToIceServers(links) {
        return (links !== null) ? links.split(', ').map((link) => {
          const m = link.match(/^<(.+?)>; rel="ice-server"(; username="(.*?)"; credential="(.*?)"; credential-type="password")?/i);
          const ret = {
            urls: [m[1]],
          };
  
          if (m[3] !== undefined) {
            ret.username = this.unquoteCredential(m[3]);
            ret.credential = this.unquoteCredential(m[4]);
            ret.credentialType = "password";
          }
  
          return ret;
        }) : [];
      },
      parseOffer(offer) {
        const ret = {
          iceUfrag: '',
          icePwd: '',
          medias: [],
        };
  
        for (const line of offer.split('\r\n')) {
          if (line.startsWith('m=')) {
            ret.medias.push(line.slice('m='.length));
          } else if (ret.iceUfrag === '' && line.startsWith('a=ice-ufrag:')) {
            ret.iceUfrag = line.slice('a=ice-ufrag:'.length);
          } else if (ret.icePwd === '' && line.startsWith('a=ice-pwd:')) {
            ret.icePwd = line.slice('a=ice-pwd:'.length);
          }
        }
  
        return ret;
      },
      enableStereoOpus(section) {
        let opusPayloadFormat = '';
        let lines = section.split('\r\n');
  
        for (let i = 0; i < lines.length; i++) {
          if (lines[i].startsWith('a=rtpmap:') && lines[i].toLowerCase().includes('opus/')) {
            opusPayloadFormat = lines[i].slice('a=rtpmap:'.length).split(' ')[0];
            break;
          }
        }
  
        if (opusPayloadFormat === '') {
          return section;
        }
  
        for (let i = 0; i < lines.length; i++) {
          if (lines[i].startsWith('a=fmtp:' + opusPayloadFormat + ' ')) {
            if (!lines[i].includes('stereo')) {
              lines[i] += ';stereo=1';
            }
            if (!lines[i].includes('sprop-stereo')) {
              lines[i] += ';sprop-stereo=1';
            }
          }
        }
  
        return lines.join('\r\n');
      },
      editOffer(offer) {
        const sections = offer.sdp.split('m=');
  
        for (let i = 0; i < sections.length; i++) {
          const section = sections[i];
          if (section.startsWith('audio')) {
            sections[i] = this.enableStereoOpus(section);
          }
        }
  
        offer.sdp = sections.join('m=');
      },
      generateSdpFragment(offerData, candidates) {
        const candidatesByMedia = {};
        for (const candidate of candidates) {
          const mid = candidate.sdpMLineIndex;
          if (candidatesByMedia[mid] === undefined) {
            candidatesByMedia[mid] = [];
          }
          candidatesByMedia[mid].push(candidate);
        }
  
        let frag = 'a=ice-ufrag:' + offerData.iceUfrag + '\r\n' + 'a=ice-pwd:' + offerData.icePwd + '\r\n';
        let mid = 0;
  
        for (const media of offerData.medias) {
          if (candidatesByMedia[mid] !== undefined) {
            frag += 'm=' + media + '\r\n' + 'a=mid:' + mid + '\r\n';
  
            for (const candidate of candidatesByMedia[mid]) {
              frag += 'a=' + candidate.candidate + '\r\n';
            }
          }
          mid++;
        }
  
        return frag;
      },
      
      start() {
        console.log("Requesting ICE servers");
        const url = new URL('whep', window.location.href + "cam/") + window.location.search;

        fetch(url, { method: 'OPTIONS' })
          .then(res => this.onIceServers(res))
          .catch(err => {
            console.log('Error:', err);
            this.scheduleRestart();
          });
      },

      onIceServers(res) {
        this.pc = new RTCPeerConnection({
          iceServers: this.linkToIceServers(res.headers.get('Link')),
        });

        const direction = "sendrecv";
        this.pc.addTransceiver("video", { direction });
        this.pc.addTransceiver("audio", { direction });

        this.pc.onicecandidate = (evt) => this.onLocalCandidate(evt);
        this.pc.oniceconnectionstatechange = () => this.onConnectionState();

        this.pc.ontrack = (evt) => {
          console.log("New track:", evt.track.kind);
          this.$refs.videoElement.srcObject = evt.streams[0];
        };

        this.pc.createOffer()
          .then((offer) => this.onLocalOffer(offer))
          .catch(err => console.error(err));
      },

      onLocalOffer(offer) {
        this.editOffer(offer);

        this.offerData = this.parseOffer(offer.sdp);
        this.pc.setLocalDescription(offer);

        console.log("Sending offer");
        const url = new URL('whep', window.location.href + "cam/") + window.location.search;

        fetch(url, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/sdp',
          },
          body: offer.sdp,
        })
        .then(res => {
          if (res.status !== 201) {
            throw new Error('Bad status code');
          }
          this.eTag = res.headers.get('ETag');
          return res.text();
        })
        .then(sdp => this.onRemoteAnswer(new RTCSessionDescription({
          type: 'answer',
          sdp,
        })))
        .catch(err => {
          console.log('Error:', err);
          this.scheduleRestart();
        });
      },

      onConnectionState() {
        if (this.restartTimeout !== null) {
          return;
        }

        console.log("Peer connection state:", this.pc.iceConnectionState);

        if (this.pc.iceConnectionState === "disconnected") {
          this.scheduleRestart();
        }
      },

      onRemoteAnswer(answer) {
        if (this.restartTimeout !== null) {
          return;
        }

        this.pc.setRemoteDescription(answer);

        if (this.queuedCandidates.length > 0) {
          this.sendLocalCandidates(this.queuedCandidates);
          this.queuedCandidates = [];
        }
      },

      onLocalCandidate(evt) {
        if (this.restartTimeout !== null) {
          return;
        }

        if (evt.candidate) {
          if (this.eTag === '') {
            this.queuedCandidates.push(evt.candidate);
          } else {
            this.sendLocalCandidates([evt.candidate]);
          }
        }
      },

      sendLocalCandidates(candidates) {
        const url = new URL('whep', window.location.href + "cam/") + window.location.search;

        fetch(url, {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/trickle-ice-sdpfrag',
            'If-Match': this.eTag,
          },
          body: this.generateSdpFragment(this.offerData, candidates),
        })
        .then(res => {
          if (res.status !== 204) {
            throw new Error('Bad status code');
          }
        })
        .catch(err => {
          console.log('Error:', err);
          this.scheduleRestart();
        });
      },

      scheduleRestart() {
        if (this.restartTimeout !== null) {
          return;
        }

        if (this.pc) {
          this.pc.close();
          this.pc = null;
        }

        this.restartTimeout = setTimeout(() => {
          this.restartTimeout = null;
          this.start();
        }, this.restartPause);

        this.eTag = '';
        this.queuedCandidates = [];
      }
    },

    beforeUnmount() {
      if (this.pc) {
        this.pc.close();
      }
      if (this.restartTimeout) {
        clearTimeout(this.restartTimeout);
      }
    },

    mounted() {
      this.start();
    },
    beforeUnmount() {
      if (this.pc !== null) {
        this.pc.close();
        this.pc = null;
      }
      clearTimeout(this.restartTimeout);
    }
  };
</script>
  
<style scoped>
  #camera-stream-container {
    /* Add styles for your video container here */
  }
  #video {
    /* Add styles for your video element here */
    width: 100%;
    height: auto;
  }
</style>
  