import AVFoundation
import CoreMedia

// Camera state and Vision run on the serial queue. Preview only reads the session.
final class CameraService: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    enum Event: Sendable { case frame(PoseFrame), fps(Double), unavailable }
    let session = AVCaptureSession()
    let position: AVCaptureDevice.Position
    var isFront: Bool { position == .front }
    init(position: AVCaptureDevice.Position = .front) { self.position = position; super.init() }
    private let channel = BoundedEventChannel<Event>()
    var events: AsyncStream<Event> { channel.subscribe() }
    private let output = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "bearing.camera", qos: .userInitiated)
    private let pose = PoseService()
    private var configured = false
    private var lastProcessed = -Double.infinity
    private var windowStart: TimeInterval?
    private var windowCount = 0

    static func requestAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return true
        case .notDetermined: return await AVCaptureDevice.requestAccess(for: .video)
        default: return false
        }
    }

    func start() {
        queue.async {
            do {
                if !self.configured { try self.configure(); self.configured = true }
                self.lastProcessed = -.infinity
                self.windowStart = nil
                self.windowCount = 0
                if !self.session.isRunning { self.session.startRunning() }
                if !self.session.isRunning { self.channel.send(.unavailable) }
            } catch { self.channel.send(.unavailable) }
        }
    }

    func stop() {
        queue.async { if self.session.isRunning { self.session.stopRunning() } }
    }

    private func configure() throws {
        enum SetupError: Error { case unavailable }
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        session.sessionPreset = .hd1280x720
        // Clear partial inputs before retrying setup.
        for input in session.inputs { session.removeInput(input) }
        for item in session.outputs { session.removeOutput(item) }
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
            throw SetupError.unavailable
        }
        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else { throw SetupError.unavailable }
        session.addInput(input)
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.setSampleBufferDelegate(self, queue: queue)
        guard session.canAddOutput(output) else { throw SetupError.unavailable }
        session.addOutput(output)
        if let connection = output.connection(with: .video) {
            if connection.isVideoRotationAngleSupported(90) { connection.videoRotationAngle = 90 }
            connection.automaticallyAdjustsVideoMirroring = false
            if connection.isVideoMirroringSupported { connection.isVideoMirrored = false }
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
        guard time.isFinite, time - lastProcessed >= Parameters.minFrameInterval,
              let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        lastProcessed = time
        let frame = pose.process(buffer, timestamp: time)
        // Keep only the latest frame so camera work cannot queue up on the main actor.
        channel.send(.frame(frame))
        if let start = windowStart, time - start >= 1 {
            channel.send(.fps(Double(windowCount) / (time - start)))
            windowStart = time
            windowCount = 0
        } else if windowStart == nil { windowStart = time }
        windowCount += 1
    }

    static var now: TimeInterval { CMClockGetTime(CMClockGetHostTimeClock()).seconds }
}
