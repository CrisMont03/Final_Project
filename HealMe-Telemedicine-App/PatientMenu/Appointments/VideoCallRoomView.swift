import SwiftUI
import FirebaseCore
import AgoraRtcKit
import AVFoundation
import FirebaseFirestore

struct VideoCallRoomView: View {
    let appointment: Appointment
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var isDoctorConnected = false
    
    private let colors = (
        red: Color(hex: "D40035"),
        green: Color(hex: "28A745"),
        blue: Color(hex: "007AFE"),
        background: Color(hex: "F5F6F9")
    )
    
    var body: some View {
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Text("Videollamada con Dr. \(appointment.doctorName)")
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.top, 16)
                
                AgoraVideoCallView(
                    appointment: appointment,
                    authViewModel: authViewModel,
                    isDoctorConnected: $isDoctorConnected
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(colors.green, lineWidth: 2)
                )
                .padding(.horizontal, 16)
                
                Button(action: {
                    // Eliminar el channelName de Firestore
                    let db = Firestore.firestore()
                    db.collection("active_calls").document(appointment.id.uuidString).delete { error in
                        if let error = error {
                            print("Error deleting channelName from Firestore: \(error.localizedDescription)")
                        } else {
                            print("channelName deleted successfully for appointment: \(appointment.id.uuidString)")
                        }
                    }
                    dismiss()
                }) {
                    Text("Finalizar Videollamada")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(colors.red)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            
            if !isDoctorConnected {
                ZStack {
                    Color.black
                        .ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: colors.blue))
                            .scaleEffect(1.5)
                        Text("Esperando al Dr. \(appointment.doctorName)")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                        
                        // Botón "Volver"
                        Button(action: {
                            // Eliminar el channelName de Firestore
                            let db = Firestore.firestore()
                            db.collection("active_calls").document(appointment.id.uuidString).delete { error in
                                if let error = error {
                                    print("Error deleting channelName from Firestore: \(error.localizedDescription)")
                                } else {
                                    print("channelName deleted successfully for appointment: \(appointment.id.uuidString)")
                                }
                            }
                            dismiss()
                        }) {
                            Text("Volver")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(colors.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            print("VideoCallRoomView appeared for appointment: \(appointment)")
            let channelName = "healme_\(appointment.id.uuidString)"
            print("Channel name for this call: \(channelName)")
            
            // Guardar el channelName en Firestore
            let db = Firestore.firestore()
            let callData: [String: Any] = [
                "doctorId": appointment.doctorId,
                "date": appointment.date,
                "hour": appointment.hour,
                "patientName": authViewModel.patientName,
                "channelName": channelName,
                "createdAt": Timestamp()
            ]
            
            db.collection("active_calls").document(appointment.id.uuidString).setData(callData) { error in
                if let error = error {
                    print("Error saving channelName to Firestore: \(error.localizedDescription)")
                } else {
                    print("channelName saved successfully for appointment: \(appointment.id.uuidString)")
                }
            }
        }
    }
}

struct AgoraVideoCallView: UIViewControllerRepresentable {
    let appointment: Appointment
    let authViewModel: AuthViewModel
    @Binding var isDoctorConnected: Bool
    
    func makeUIViewController(context: Context) -> AgoraVideoCallViewController {
        let channelName = "healme_\(appointment.id.uuidString)"
        let viewController = AgoraVideoCallViewController(
            appId: "3617dfcb05d34ca8b60f3a22be314fcd",
            token: nil,
            channelName: channelName,
            userId: authViewModel.currentUserId ?? "patient_\(UUID().uuidString)",
            isDoctorConnected: $isDoctorConnected
        )
        viewController.coordinator = context.coordinator
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: AgoraVideoCallViewController, context: Context) {
        // No se necesita actualizar
    }
    
    func makeCoordinator() -> AgoraVideoCallCoordinator {
        AgoraVideoCallCoordinator(self, viewController: nil)
    }
}

class AgoraVideoCallCoordinator: NSObject, AgoraRtcEngineDelegate {
    var parent: AgoraVideoCallView
    weak var viewController: AgoraVideoCallViewController?
    
    init(_ parent: AgoraVideoCallView, viewController: AgoraVideoCallViewController?) {
        self.parent = parent
        self.viewController = viewController
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        print("Remote user joined with uid: \(uid)")
        guard let viewController = viewController else {
            print("ViewController is nil, cannot setup remote video")
            return
        }
        viewController.remoteVideoView.subviews.forEach { $0.removeFromSuperview() }
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = uid
        videoCanvas.renderMode = .hidden
        videoCanvas.view = viewController.remoteVideoView
        engine.setupRemoteVideo(videoCanvas)
        parent.isDoctorConnected = true
        print("Remote video setup for uid: \(uid)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        print("Remote user \(uid) left with reason: \(reason.rawValue)")
        viewController?.remoteVideoView.subviews.forEach { $0.removeFromSuperview() }
        parent.isDoctorConnected = false
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        print("Agora error: \(errorCode.rawValue), channel: \(parent.appointment.id.uuidString), userId: \(parent.authViewModel.currentUserId ?? "unknown")")
        if errorCode == .noPermission {
            print("No camera or microphone permissions. Check Info.plist and device settings.")
        } else if errorCode == .invalidToken {
            print("Invalid token. Regenerate token in Agora Console for channel: healme_\(parent.appointment.id.uuidString)")
        }
    }
}

class AgoraVideoCallViewController: UIViewController {
    private let agoraKit: AgoraRtcEngineKit
    let remoteVideoView = UIView()
    let localVideoView = UIView()
    private let appId: String
    private let token: String?
    private let channelName: String
    private let userId: String
    weak var coordinator: AgoraVideoCallCoordinator?
    private var isConnected = false
    @Binding private var isDoctorConnected: Bool
    
    private let colors = (
        red: UIColor(hex: "D40035"),
        green: UIColor(hex: "28A745"),
        blue: UIColor(hex: "007AFE"),
        background: UIColor(hex: "F5F6F9"),
        gray: UIColor(hex: "808080")
    )
    
    private lazy var muteMicButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = colors.blue
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(toggleMic), for: .touchUpInside)
        return button
    }()
    
    private lazy var muteCameraButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "video.fill"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = colors.blue
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(toggleCamera), for: .touchUpInside)
        return button
    }()
    
    private var isMicMuted = false
    private var isCameraMuted = false
    
    init(appId: String, token: String?, channelName: String, userId: String, isDoctorConnected: Binding<Bool>) {
        self.appId = appId
        self.token = token
        self.channelName = channelName
        self.userId = userId
        self._isDoctorConnected = isDoctorConnected
        AgoraRtcEngineKit.destroy()
        self.agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: appId, delegate: nil)
        super.init(nibName: nil, bundle: nil)
        print("Initializing AgoraVideoCallViewController with appId: \(appId.prefix(6))..., channel: \(channelName), userId: \(userId), token: \(token?.prefix(10) ?? "nil")")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkPermissions()
        setupUI()
        coordinator?.viewController = self
        agoraKit.delegate = coordinator
        initializeAgoraEngine()
        setupLocalVideo()
        joinChannel()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isConnected {
            leaveChannel()
        } else {
            print("Not leaving channel, not connected yet")
        }
    }
    
    private func checkPermissions() {
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        if cameraStatus != .authorized {
            print("Camera permission not granted: \(cameraStatus.rawValue)")
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if !granted {
                        print("Camera permission denied by user")
                    }
                }
            }
        }
        
        if micStatus != .authorized {
            print("Microphone permission not granted: \(micStatus.rawValue)")
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    if !granted {
                        print("Microphone permission denied by user")
                    }
                }
            }
        }
    }
    
    private func setupUI() {
        view.backgroundColor = colors.background
        
        remoteVideoView.backgroundColor = .black
        localVideoView.backgroundColor = .black
        
        remoteVideoView.translatesAutoresizingMaskIntoConstraints = false
        localVideoView.translatesAutoresizingMaskIntoConstraints = false
        muteMicButton.translatesAutoresizingMaskIntoConstraints = false
        muteCameraButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(remoteVideoView)
        view.addSubview(localVideoView)
        view.addSubview(muteMicButton)
        view.addSubview(muteCameraButton)
        
        NSLayoutConstraint.activate([
            remoteVideoView.topAnchor.constraint(equalTo: view.topAnchor),
            remoteVideoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            remoteVideoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            remoteVideoView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            localVideoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            localVideoView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            localVideoView.widthAnchor.constraint(equalToConstant: 120),
            localVideoView.heightAnchor.constraint(equalToConstant: 160),
            
            muteMicButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            muteMicButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            muteMicButton.widthAnchor.constraint(equalToConstant: 48),
            muteMicButton.heightAnchor.constraint(equalToConstant: 48),
            
            muteCameraButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            muteCameraButton.leadingAnchor.constraint(equalTo: muteMicButton.trailingAnchor, constant: 16),
            muteCameraButton.widthAnchor.constraint(equalToConstant: 48),
            muteCameraButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
    
    private func initializeAgoraEngine() {
        agoraKit.setChannelProfile(.communication)
        agoraKit.setAudioProfile(.default)
        agoraKit.enableVideo()
        agoraKit.enableAudio()
        agoraKit.setEnableSpeakerphone(true)
        agoraKit.setVideoEncoderConfiguration(
            AgoraVideoEncoderConfiguration(
                size: CGSize(width: 640, height: 360),
                frameRate: .fps15,
                bitrate: AgoraVideoBitrateStandard,
                orientationMode: .fixedPortrait,
                mirrorMode: .auto
            )
        )
        print("Agora engine initialized with video, audio, communication profile, and speakerphone")
    }
    
    private func setupLocalVideo() {
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = 0
        videoCanvas.renderMode = .hidden
        videoCanvas.view = localVideoView
        agoraKit.setupLocalVideo(videoCanvas)
        agoraKit.startPreview()
        print("Local video setup completed")
    }
    
    private func joinChannel() {
        let result = agoraKit.joinChannel(
            byToken: token,
            channelId: channelName,
            info: nil,
            uid: 0,
            joinSuccess: { [weak self] (channel, uid, elapsed) in
                print("Joined channel \(channel) with uid \(uid), elapsed: \(elapsed)ms")
                self?.isConnected = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self?.agoraKit.muteLocalAudioStream(false)
                    self?.agoraKit.muteLocalVideoStream(false)
                    print("Audio and video streams enabled after join")
                }
            }
        )
        print("Join channel result: \(result), channel: \(channelName), userId: \(userId), token: \(token?.prefix(10) ?? "nil")")
    }
    
    private func leaveChannel() {
        agoraKit.leaveChannel { stats in
            print("Left channel with stats: \(stats)")
        }
        agoraKit.stopPreview()
        AgoraRtcEngineKit.destroy()
        isConnected = false
    }
    
    @objc private func toggleMic() {
        guard isConnected else {
            print("Cannot toggle mic, not connected to channel")
            return
        }
        isMicMuted.toggle()
        let muteResult = agoraKit.muteLocalAudioStream(isMicMuted)
        let enableResult = agoraKit.enableLocalAudio(!isMicMuted)
        if isMicMuted {
            agoraKit.adjustRecordingSignalVolume(0)
        } else {
            agoraKit.adjustRecordingSignalVolume(100)
        }
        muteMicButton.setImage(
            UIImage(systemName: isMicMuted ? "mic.slash.fill" : "mic.fill"),
            for: .normal
        )
        muteMicButton.backgroundColor = isMicMuted ? colors.gray : colors.blue
        print("Microphone \(isMicMuted ? "muted" : "unmuted"), muteLocalAudioStream: \(isMicMuted), muteResult: \(muteResult), enableLocalAudio: \(!isMicMuted), enableResult: \(enableResult), volume: \(isMicMuted ? 0 : 100)")
    }
    
    @objc private func toggleCamera() {
        guard isConnected else {
            print("Cannot toggle camera, not connected to channel")
            return
        }
        isCameraMuted.toggle()
        let muteResult = agoraKit.muteLocalVideoStream(isCameraMuted)
        let enableResult = agoraKit.enableLocalVideo(!isCameraMuted)
        if isCameraMuted {
            agoraKit.stopPreview()
            let videoCanvas = AgoraRtcVideoCanvas()
            videoCanvas.uid = 0
            videoCanvas.view = nil
            agoraKit.setupLocalVideo(videoCanvas)
            print("Camera muted, preview stopped")
        } else {
            agoraKit.enableVideo()
            let videoCanvas = AgoraRtcVideoCanvas()
            videoCanvas.uid = 0
            videoCanvas.renderMode = .hidden
            videoCanvas.view = localVideoView
            DispatchQueue.main.async {
                self.agoraKit.setupLocalVideo(videoCanvas)
                let previewResult = self.agoraKit.startPreview()
                print("Camera unmuted, preview started, previewResult: \(previewResult), subviews: \(self.localVideoView.subviews.count)")
            }
        }
        muteCameraButton.setImage(
            UIImage(systemName: isCameraMuted ? "video.slash.fill" : "video.fill"),
            for: .normal
        )
        muteCameraButton.backgroundColor = isCameraMuted ? colors.gray : colors.blue
        print("Camera \(isCameraMuted ? "muted" : "unmuted"), muteLocalVideoStream: \(isCameraMuted), muteResult: \(muteResult), enableLocalVideo: \(!isCameraMuted), enableResult: \(enableResult)")
    }
}

struct VideoCallRoomView_Previews: PreviewProvider {
    static var previews: some View {
        VideoCallRoomView(appointment: Appointment(
            doctorId: "UCm7fDKKgYJwvZpIywCb",
            doctorName: "Juan Carlos Méndez Rodríguez",
            specialty: "Cardiología",
            date: "2025-05-21",
            hour: "13:20"
        ))
        .environmentObject(AuthViewModel())
    }
}

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}
