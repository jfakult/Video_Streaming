// src/lib/MediaMTXWebRTCReader.js
export class MediaMTXWebRTCReader {
  constructor(conf) {
    this.conf = conf;
    this.retryPause = 2000;
    this.pc = null;
    this.sessionUrl = null;
    this.offerData = null;
    this.queuedCandidates = [];
    this.restartTimeout = null;

    this.#start();
  }

  close() {
    if (this.pc) {
      this.pc.close();
      this.pc = null;
    }
    if (this.restartTimeout) {
      clearTimeout(this.restartTimeout);
      this.restartTimeout = null;
    }
    if (this.sessionUrl) {
      fetch(this.sessionUrl, { method: "DELETE" }).catch(() => {});
      this.sessionUrl = null;
    }
  }

  async #start() {
    try {
      const iceServers = await this.#requestICEServers();
      const offer = await this.#setupPeerConnection(iceServers);
      const answer = await this.#sendOffer(offer);
      await this.#setAnswer(answer);
    } catch (err) {
      this.#handleError(err.toString());
    }
  }

  async #requestICEServers() {
    const res = await fetch(this.conf.url, { method: "OPTIONS" });
    return this.#linkToIceServers(res.headers.get("Link"));
  }

  async #setupPeerConnection(iceServers) {
    this.pc = new RTCPeerConnection({
      iceServers,
      sdpSemantics: "unified-plan",
    });

    // receive-only
    this.pc.addTransceiver("video", { direction: "recvonly" });
    this.pc.addTransceiver("audio", { direction: "recvonly" });

    this.pc.onicecandidate = (evt) => this.#onLocalCandidate(evt);
    this.pc.onconnectionstatechange = () => this.#onConnectionState();
    this.pc.ontrack = (evt) => {
      if (this.conf.onTrack) this.conf.onTrack(evt);
    };

    const offer = await this.pc.createOffer();
    this.offerData = this.#parseOffer(offer.sdp);

    await this.pc.setLocalDescription(offer);
    return offer.sdp;
  }

  async #sendOffer(offer) {
    const res = await fetch(this.conf.url, {
      method: "POST",
      headers: { "Content-Type": "application/sdp" },
      body: offer,
    });

    if (res.status !== 201) {
      throw new Error(`Bad status ${res.status}`);
    }

    this.sessionUrl = new URL(res.headers.get("location"), this.conf.url).toString();
    return await res.text();
  }

  async #setAnswer(answer) {
    await this.pc.setRemoteDescription({
      type: "answer",
      sdp: answer,
    });

    if (this.queuedCandidates.length > 0) {
      this.#sendLocalCandidates(this.queuedCandidates);
      this.queuedCandidates = [];
    }
  }

  #onLocalCandidate(evt) {
    if (!evt.candidate) return;
    if (this.sessionUrl === null) {
      this.queuedCandidates.push(evt.candidate);
    } else {
      this.#sendLocalCandidates([evt.candidate]);
    }
  }

  async #sendLocalCandidates(candidates) {
    try {
      await fetch(this.sessionUrl, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/trickle-ice-sdpfrag",
          "If-Match": "*",
        },
        body: this.#generateSdpFragment(this.offerData, candidates),
      });
    } catch (err) {
      this.#handleError(err);
    }
  }

  #onConnectionState() {
    if (!this.pc) return;
    if (["failed", "closed", "disconnected"].includes(this.pc.connectionState)) {
      this.#handleError("Peer connection lost");
    }
  }

  #handleError(err) {
    console.error("MediaMTXWebRTCReader error:", err);
    this.close();

    this.restartTimeout = setTimeout(() => {
      this.restartTimeout = null;
      this.#start();
    }, this.retryPause);

    if (this.conf.onError) {
      this.conf.onError(err);
    }
  }

  #linkToIceServers(links) {
    return links
      ? links.split(", ").map((link) => {
          const m = link.match(
            /^<(.+?)>; rel="ice-server"(; username="(.*?)"; credential="(.*?)"; credential-type="password")?/i
          );
          const ret = { urls: [m[1]] };
          if (m[3]) {
            ret.username = JSON.parse(`"${m[3]}"`);
            ret.credential = JSON.parse(`"${m[4]}"`);
            ret.credentialType = "password";
          }
          return ret;
        })
      : [];
  }

  #parseOffer(sdp) {
    const ret = { iceUfrag: "", icePwd: "", medias: [] };
    for (const line of sdp.split("\r\n")) {
      if (line.startsWith("m=")) ret.medias.push(line.slice(2));
      else if (line.startsWith("a=ice-ufrag:")) ret.iceUfrag = line.slice(12);
      else if (line.startsWith("a=ice-pwd:")) ret.icePwd = line.slice(10);
    }
    return ret;
  }

  #generateSdpFragment(od, candidates) {
    const candidatesByMedia = {};
    for (const candidate of candidates) {
      const mid = candidate.sdpMLineIndex;
      if (!candidatesByMedia[mid]) candidatesByMedia[mid] = [];
      candidatesByMedia[mid].push(candidate);
    }

    let frag = `a=ice-ufrag:${od.iceUfrag}\r\n` + `a=ice-pwd:${od.icePwd}\r\n`;
    let mid = 0;
    for (const media of od.medias) {
      if (candidatesByMedia[mid]) {
        frag += `m=${media}\r\n` + `a=mid:${mid}\r\n`;
        for (const candidate of candidatesByMedia[mid]) {
          frag += `a=${candidate.candidate}\r\n`;
        }
      }
      mid++;
    }
    return frag;
  }
}
