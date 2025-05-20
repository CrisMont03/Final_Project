//
//  VideoCallRoomDoctorView.swift
//  HealMe-Telemedicine-App
//
//  Created by Cristian Montiel García on 19/05/25.
//

import SwiftUI
import AgoraRtcKit
import FirebaseFirestore

struct VideoCallRoomDoctorView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var agoraManager = AgoraManager()
    let channelName: String
    let appointment: AppointmentDoctor
    @State private var isLocalMuted: Bool = false
    @State private var isLocalCameraOn: Bool = true
    @State private var errorMessage: String = ""
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack {
                // Remote video (patient's video)
                if (agoraManager.remoteCanvas?.view) != nil {
                    ZStack {
                        AgoraVideoCanvasView(canvas: agoraManager.remoteCanvas)
                            .aspectRatio(1.0, contentMode: .fit)
                            .background(Color.black)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                        
                        if agoraManager.remoteUid == 0 {
                            Text("Esperando a \(appointment.patientName)...")
                                .foregroundColor(.white)
                                .font(.title2)
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Text("Esperando a \(appointment.patientName)...")
                        .foregroundColor(.primary)
                        .font(.title2)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                
                // Local video (doctor's video)
                if (agoraManager.localCanvas?.view) != nil {
                    AgoraVideoCanvasView(canvas: agoraManager.localCanvas)
                        .aspectRatio(1.0, contentMode: .fit)
                        .background(Color.black)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .frame(width: 120, height: 160)
                        .padding(.bottom, 20)
                }
                
                // Controls
                HStack(spacing: 30) {
                    Button(action: {
                        isLocalMuted.toggle()
                        agoraManager.muteLocalAudio(muted: isLocalMuted)
                    }) {
                        Image(systemName: isLocalMuted ? "mic.slash.fill" : "mic.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .background(isLocalMuted ? Color.red : Color.gray)
                            .clipShape(Circle())
                    }
                    
                    Button(action: {
                        isLocalCameraOn.toggle()
                        agoraManager.enableLocalVideo(enabled: isLocalCameraOn)
                    }) {
                        Image(systemName: isLocalCameraOn ? "video.fill" : "video.slash.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .background(isLocalCameraOn ? Color.gray : Color.red)
                            .clipShape(Circle())
                    }
                    
                    Button(action: {
                        agoraManager.leaveChannel()
                        
                        // Eliminar el channelName de Firestore
                        let db = Firestore.firestore()
                        db.collection("active_calls")
                            .whereField("channelName", isEqualTo: channelName)
                            .getDocuments { snapshot, error in
                                if let error = error {
                                    print("Error finding document to delete: \(error.localizedDescription)")
                                    return
                                }
                                guard let document = snapshot?.documents.first else {
                                    print("No document found for channelName: \(channelName)")
                                    return
                                }
                                document.reference.delete { error in
                                    if let error = error {
                                        print("Error deleting channelName from Firestore: \(error.localizedDescription)")
                                    } else {
                                        print("channelName deleted successfully for channelName: \(channelName)")
                                    }
                                }
                            }
                        
                        dismiss()
                    }) {
                        Image(systemName: "phone.down.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom, 20)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .padding()
        }
        .onAppear {
            agoraManager.joinChannel(channelName: channelName)
        }
        .onDisappear {
            agoraManager.leaveChannel()
        }
    }
}

class AgoraManager: NSObject, ObservableObject, AgoraRtcEngineDelegate {
    private var agoraKit: AgoraRtcEngineKit!
    @Published var localCanvas: AgoraRtcVideoCanvas?
    @Published var remoteCanvas: AgoraRtcVideoCanvas?
    @Published var remoteUid: UInt = 0
    
    override init() {
        super.init()
        initializeAgoraEngine()
    }
    
    private func initializeAgoraEngine() {
        let config = AgoraRtcEngineConfig()
        config.appId = "3617dfcb05d34ca8b60f3a22be314fcd"
        agoraKit = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
        
        // Enable video
        agoraKit.enableVideo()
        
        // Set channel profile to communication
        agoraKit.setChannelProfile(.communication)
        
        // Set client role to broadcaster
        agoraKit.setClientRole(.broadcaster)
        
        // Configure local video
        localCanvas = AgoraRtcVideoCanvas()
        localCanvas?.uid = 0
        localCanvas?.view = UIView()
        localCanvas?.renderMode = .hidden
        agoraKit.setupLocalVideo(localCanvas)
        
        // Start local video preview
        agoraKit.startPreview()
        
        print("Agora engine initialized")
    }
    
    func joinChannel(channelName: String) {
        // Ensure permissions for camera and microphone
        agoraKit.enableVideo()
        agoraKit.enableAudio()
        
        // Join channel
        let result = agoraKit.joinChannel(
            byToken: nil,
            channelId: channelName,
            info: nil,
            uid: 0
        ) { [weak self] (channel, uid, elapsed) in
            print("Joined channel \(channel) with uid \(uid), elapsed: \(elapsed)ms")
            self?.remoteCanvas = AgoraRtcVideoCanvas()
            self?.remoteCanvas?.uid = 0
            self?.remoteCanvas?.view = UIView()
            self?.remoteCanvas?.renderMode = .hidden
        }
        
        if result != 0 {
            print("Failed to join channel: \(result)")
        }
    }
    
    func leaveChannel() {
        agoraKit.stopPreview()
        agoraKit.leaveChannel { stats in
            print("Left channel, stats: \(stats)")
        }
        AgoraRtcEngineKit.destroy()
        print("Agora engine destroyed")
    }
    
    func muteLocalAudio(muted: Bool) {
        agoraKit.muteLocalAudioStream(muted)
        print("Local audio \(muted ? "muted" : "unmuted")")
    }
    
    func enableLocalVideo(enabled: Bool) {
        agoraKit.enableLocalVideo(enabled)
        print("Local video \(enabled ? "enabled" : "disabled")")
    }
    
    // MARK: - AgoraRtcEngineDelegate
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        print("Remote user joined with uid: \(uid), elapsed: \(elapsed)ms")
        remoteCanvas?.uid = uid
        agoraKit.setupRemoteVideo(remoteCanvas!)
        DispatchQueue.main.async { [weak self] in
            self?.remoteUid = uid
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        print("Remote user offline with uid: \(uid), reason: \(reason.rawValue)")
        remoteCanvas?.uid = 0
        DispatchQueue.main.async { [weak self] in
            self?.remoteUid = 0
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        print("Agora error: \(errorCode.rawValue)")
        DispatchQueue.main.async { [weak self] in
            self?.objectWillChange.send()
        }
    }
}

struct AgoraVideoCanvasView: UIViewRepresentable {
    let canvas: AgoraRtcVideoCanvas?
    
    func makeUIView(context: Context) -> UIView {
        canvas?.view ?? UIView()
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}


