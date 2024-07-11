package main

import (
    "encoding/json"
    "github.com/pion/webrtc/v3"
    "github.com/gorilla/websocket"
    "net/http"
    "log"
    "os/exec"
    "bufio"
)

var upgrader = websocket.Upgrader{}

func handleWebSocket(w http.ResponseWriter, r *http.Request) {
    conn, err := upgrader.Upgrade(w, r, nil)
    if err != nil {
        log.Println("Failed to upgrade WebSocket:", err)
        return
    }
    defer conn.Close()

    peerConnection, err := webrtc.NewPeerConnection(webrtc.Configuration{})
    if err != nil {
        log.Println("Failed to create peer connection:", err)
        return
    }

    videoTrack, err := webrtc.NewTrackLocalStaticSample(webrtc.RTPCodecCapability{MimeType: webrtc.MimeTypeH264}, "video", "pion")
    if err != nil {
        log.Println("Failed to create video track:", err)
        return
    }

    _, err = peerConnection.AddTrack(videoTrack)
    if err != nil {
        log.Println("Failed to add video track:", err)
        return
    }

    go startCamera(videoTrack)

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

        if sdp, ok := msg["sdp"]; ok {
            if err := peerConnection.SetRemoteDescription(webrtc.SessionDescription{
                Type: webrtc.SDPType(msg["type"].(string)),
                SDP:  sdp.(string),
            }); err != nil {
                log.Println("Failed to set remote description:", err)
            }
            if msg["type"] == "offer" {
                answer, err := peerConnection.CreateAnswer(nil)
                if err != nil {
                    log.Println("Failed to create answer:", err)
                }
                if err := peerConnection.SetLocalDescription(answer); err != nil {
                    log.Println("Failed to set local description:", err)
                }
                if err := conn.WriteJSON(answer); err != nil {
                    log.Println("Failed to send answer:", err)
                }
            }
        } else if candidate, ok := msg["candidate"]; ok {
            if err := peerConnection.AddICECandidate(webrtc.ICECandidateInit{
                Candidate: candidate.(string),
            }); err != nil {
                log.Println("Failed to add ICE candidate:", err)
            }
        }
    }
}

func startCamera(videoTrack *webrtc.TrackLocalStaticSample) {
    cmd := exec.Command("./build/camera_capture")
    stdout, err := cmd.StdoutPipe()
    if err != nil {
        log.Fatal(err)
    }

    if err := cmd.Start(); err != nil {
        log.Fatal(err)
    }

    scanner := bufio.NewScanner(stdout)
    for scanner.Scan() {
        data := scanner.Bytes()
        sample := webrtc.Sample{
            Data:    data,
            Samples: 1,
        }
        if err := videoTrack.WriteSample(sample); err != nil {
            log.Println("Failed to write sample:", err)
        }
    }
}

func main() {
    http.HandleFunc("/ws", handleWebSocket)
    log.Println("WebSocket server started at :8080")
    if err := http.ListenAndServe(":8080", nil); err != nil {
        log.Fatal("Failed to start server:", err)
    }
}

