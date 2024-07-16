package main

import (
    "encoding/json"
    "log"
    "errors"
    "io"
    "fmt"
    //"os"
    "net/http"
    "os/exec"
    "time"
    "sync"

    "github.com/pion/webrtc/v3"
    "github.com/gorilla/websocket"
    "github.com/pion/webrtc/v3/pkg/media"
    "github.com/pion/webrtc/v3/pkg/media/h264reader"
)

var upgrader = websocket.Upgrader{
    CheckOrigin: func(r *http.Request) bool {
        return true
    },
}

var videoTrack *webrtc.TrackLocalStaticSample

const h264FrameDuration = time.Second / 30

func handleWebSocket(w http.ResponseWriter, r *http.Request) {
    log.Println("New WebSocket connection established")

    conn, err := upgrader.Upgrade(w, r, nil)
    if err != nil {
        log.Println("Failed to upgrade WebSocket:", err)
        return
    }
    defer conn.Close()

    var writeMutex sync.Mutex

    peerConnection, err := webrtc.NewPeerConnection(webrtc.Configuration{})
    if err != nil {
        log.Println("Failed to create peer connection:", err)
        return
    }

    var iceCandidatesQueue []webrtc.ICECandidateInit
    remoteDescriptionSet := false

    peerConnection.OnICECandidate(func(c *webrtc.ICECandidate) {
        if c == nil {
            return
        }
        log.Println("Sending ICE candidate:", c.ToJSON().Candidate)
        writeMutex.Lock()
        err := conn.WriteJSON(map[string]interface{}{
            "candidate": map[string]interface{}{
                "candidate":     c.ToJSON().Candidate,
                "sdpMid":        c.ToJSON().SDPMid,
                "sdpMLineIndex": c.ToJSON().SDPMLineIndex,
            },
        })
        writeMutex.Unlock()
        if err != nil {
            log.Println("Failed to send ICE candidate:", err)
        }
    })

    peerConnection.OnConnectionStateChange(func(state webrtc.PeerConnectionState) {
        log.Println("Peer connection state changed to:", state)
        if state == webrtc.PeerConnectionStateFailed ||
           state == webrtc.PeerConnectionStateDisconnected {
            log.Println("Reconnecting due to connection state:", state)
            conn.Close()
            // Implement reconnection logic here if necessary
        }
    })

    log.Println("Adding track")
    _, err = peerConnection.AddTrack(videoTrack)
    if err != nil {
        log.Println("Failed to add video track:", err)
        return
    }

    for {
        _, message, err := conn.ReadMessage()
        if err != nil {
            log.Println("Read error:", err)
            break
        }

        var msg map[string]interface{}
        if err := json.Unmarshal(message, &msg); err != nil {
            log.Println("JSON unmarshal error:", err)
            continue
        }

        //log.Printf("Received message: %v", msg)

        if sdpMap, ok := msg["sdp"].(map[string]interface{}); ok {
            sdpTypeStr, typeOk := sdpMap["type"].(string)
            sdpStr, sdpOk := sdpMap["sdp"].(string)
            if typeOk && sdpOk {
                var sdpType webrtc.SDPType
                if sdpTypeStr == "offer" {
                    sdpType = webrtc.SDPTypeOffer
                } else if sdpTypeStr == "answer" {
                    sdpType = webrtc.SDPTypeAnswer
                } else {
                    log.Println("Unknown SDP type:", sdpTypeStr)
                    continue
                }

                log.Println("Setting remote description with SDP:", sdpStr)
                if err := peerConnection.SetRemoteDescription(webrtc.SessionDescription{
                    Type: sdpType,
                    SDP:  sdpStr,
                }); err != nil {
                    log.Println("Failed to set remote description:", err)
                    continue
                }

                remoteDescriptionSet = true

                // Add any queued ICE candidates
                for _, candidate := range iceCandidatesQueue {
                    log.Println("Adding queued ICE candidate:", candidate.Candidate)
                    if err := peerConnection.AddICECandidate(candidate); err != nil {
                        log.Println("Failed to add queued ICE candidate:", err)
                    }
                }
                iceCandidatesQueue = nil

                if sdpType == webrtc.SDPTypeOffer {
                    log.Println("Creating SDP answer")
                    answer, err := peerConnection.CreateAnswer(nil)
                    if err != nil {
                        log.Println("Failed to create answer:", err)
                        continue
                    }
                    if err := peerConnection.SetLocalDescription(answer); err != nil {
                        log.Println("Failed to set local description:", err)
                        continue
                    }
                    log.Println("Sending SDP answer:") //, peerConnection.LocalDescription().SDP)
                    writeMutex.Lock()
                    err = conn.WriteJSON(map[string]interface{}{
                        "sdp": map[string]string{
                            "type": peerConnection.LocalDescription().Type.String(),
                            "sdp":  peerConnection.LocalDescription().SDP,
                        },
                    })
                    writeMutex.Unlock()
                    if err != nil {
                        log.Println("Failed to send answer:", err)
                    }
                }
            } else {
                log.Println("SDP is not correctly structured")
            }
        } else if candidate, ok := msg["candidate"].(map[string]interface{}); ok {
            candidateStr, candidateOk := candidate["candidate"].(string)
            if candidateOk {
                iceCandidate := webrtc.ICECandidateInit{
                    Candidate: candidateStr,
                }
                if remoteDescriptionSet {
                    log.Println("Adding ICE candidate:", candidateStr)
                    if err := peerConnection.AddICECandidate(iceCandidate); err != nil {
                        log.Println("Failed to add ICE candidate:", err)
                    }
                } else {
                    log.Println("Queuing ICE candidate:", candidateStr)
                    iceCandidatesQueue = append(iceCandidatesQueue, iceCandidate)
                }
            } else {
                log.Println("ICE candidate is not a string")
            }
        } else {
            log.Println("Received unknown message format")
        }
    }

    log.Println("Done with main websocket thread")
}


func startCamera(videoTrack *webrtc.TrackLocalStaticSample) {
    log.Println("Starting camera stream")
    cmd := exec.Command("./rpicam_vid_stream.sh")
    stdout, err := cmd.StdoutPipe()
    if err != nil {
        log.Fatal(err)
    }

    if err := cmd.Start(); err != nil {
        log.Fatal(err)
    }

    // Read frames from rpicam-vid and send via WebRTC
    reader, h264Err := h264reader.NewReader(stdout)
    if h264Err != nil {
        panic(h264Err)
    }

    ticker := time.NewTicker(h264FrameDuration)
    for ; true; <-ticker.C {
        nal, h264Err := reader.NextNAL()
        if errors.Is(h264Err, io.EOF) {
            fmt.Printf("All video frames parsed and sent")
            log.Println("Error?", h264Err)
            //os.Exit(0)
        }
        if h264Err != nil {
            panic(h264Err)
        }

        if h264Err = videoTrack.WriteSample(media.Sample{Data: nal.Data, Duration: h264FrameDuration}); h264Err != nil {
            panic(h264Err)
        }
    }

    if err := cmd.Wait(); err != nil {
        log.Println("Camera command finished with error:", err)
    }
}

func corsMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Access-Control-Allow-Origin", "*")
        w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

        if r.Method == "OPTIONS" {
            w.WriteHeader(http.StatusOK)
            return
        }

        next.ServeHTTP(w, r)
    })
}

func main() {
    var err error
    videoTrack, err = webrtc.NewTrackLocalStaticSample(webrtc.RTPCodecCapability{MimeType: webrtc.MimeTypeH264}, "video", "pion")
    if err != nil {
        log.Fatal("Failed to create video track:", err)
    }

    go startCamera(videoTrack)

    mux := http.NewServeMux()
    mux.HandleFunc("/ws", handleWebSocket)

    log.Println("WebSocket server started at :8080")
    if err := http.ListenAndServe(":8080", corsMiddleware(mux)); err != nil {
        log.Fatal("Failed to start server:", err)
    }
}
