import AVFoundation
import Combine
import Foundation

@MainActor
final class SessionCoordinator: ObservableObject {
    enum Phase: Equatable { case setup, countdown(Int), recording, review }
    enum CameraProblem { case permissionDenied, unavailable }
    @Published private(set) var waitingForPosition = false
    private var handsFree = HandsFreeStart()
    @Published private(set) var phase: Phase = .setup
    @Published private(set) var alignment = AlignmentStatus.empty
    @Published private(set) var overlayFrame: PoseFrame?
    @Published private(set) var results: [AttemptResult] = []
    @Published private(set) var side: Side = .right
    @Published var cameraProblem: CameraProblem?
    @Published private(set) var measuredFPS = 0.0
    @Published private(set) var instruction = Strings.fixJoints
    let camera: CameraService
    let exercise: Exercise
    var planAtStart: PlanRevision?
    let template: CustomCheckIn?
    @Published private(set) var secondsRemaining = 0

    init(exercise: Exercise = .armRaise, template: CustomCheckIn? = nil, helperMode: Bool = false) {
        self.exercise = exercise; self.template = template
        camera = CameraService(position: helperMode ? .back : .front)
    }
    let tilt = TiltMonitor()
    let speech = SpeechCoach()
    private var filter = SignalFilter()
    private var checker = AlignmentChecker()
    private var engine: (any MovementEngine)?
    private var attemptTask: Task<Void, Never>?
    private var frameTask: Task<Void, Never>?
    private var watchdog: Task<Void, Never>?
    private var active = false
    private var generation = UUID()
    private var lastFrameTime: TimeInterval?

    var attemptsLeft: Int { exercise.attempts - results.count }

    func begin(voiceEnabled: Bool) async {
        guard !active else { return }
        active = true
        let token = generation
        speech.isEnabled = voiceEnabled
        #if targetEnvironment(simulator)
        if ProcessInfo.processInfo.arguments.contains("-UITestNoCamera") { return }
        #endif
        let allowed = await CameraService.requestAccess()
        guard active, generation == token, !Task.isCancelled else { return }
        guard allowed else { cameraProblem = .permissionDenied; return }
        cameraProblem = nil
        frameTask = Task { [weak self, events = camera.events] in
            for await event in events {
                guard let self, self.active, !Task.isCancelled else { break }
                switch event {
                case .frame(let frame): self.handle(frame)
                case .fps(let fps): self.measuredFPS = fps
                case .unavailable:
                    self.cameraProblem = .unavailable
                    self.invalidateSetup()
                }
            }
        }
        tilt.onReading = { [weak self] value in
            guard let self, self.phase == .recording else { return }
            self.engine?.observeTilt(value)
        }
        tilt.start()
        camera.start()
        watchdog = Task { [weak self] in
            while !Task.isCancelled {
                do { try await Task.sleep(for: .milliseconds(100)) } catch { return }
                self?.refreshReadiness()
            }
        }
    }

    func end() {
        active = false
        cancelHandsFree()
        generation = UUID()
        attemptTask?.cancel(); attemptTask = nil
        frameTask?.cancel(); frameTask = nil
        watchdog?.cancel(); watchdog = nil
        engine = nil
        camera.stop(); tilt.stop(); speech.stop()
        overlayFrame = nil
        invalidateSetup()
        if phase != .review { phase = .setup }
    }

    func chooseSide(_ value: Side) {
        end()
        side = value
        results = []
        phase = .setup
    }

    func repeatInstructions() { speech.repeatOnce(instruction) }

    private func say(_ text: String, force: Bool = false) {
        instruction = text
        speech.speak(text, force: force)
    }

    private func invalidateSetup() {
        filter.reset(); checker.reset()
        alignment = .empty
        overlayFrame = nil
        lastFrameTime = nil
    }

    func refreshReadiness(now: TimeInterval = CameraService.now) {
        if phase == .recording { engine?.observeTilt(tilt.freshTilt); return }
        guard phase == .setup || isCountingDown else { return }
        defer {
            if phase == .setup, handsFree.update(ready: alignment.isReady, now: now) {
                waitingForPosition = false
                startAttempt()
            }
        }
        if lastFrameTime.map({ now - $0 > Parameters.maxGapSeconds }) ?? true {
            invalidateSetup()
            say(Strings.fixJoints)
        } else if tilt.freshTilt == nil {
            alignment.tiltOK = false
            alignment.stable = false
            checker.reset()
            say(Strings.reasonMotionUnavailable)
        } else if let value = tilt.freshTilt, value > Parameters.tiltLimitDegrees {
            alignment.tiltOK = false
            alignment.stable = false
            checker.reset()
            say(Strings.fixTilt)
        }
    }

    private var isCountingDown: Bool { if case .countdown = phase { return true }; return false }

    private func handle(_ raw: PoseFrame) {
        guard active, CameraService.now - raw.timestamp <= Parameters.maxGapSeconds else { return }
        lastFrameTime = raw.timestamp
        let frame = filter.apply(raw)
        overlayFrame = frame
        switch phase {
        case .recording: engine?.ingest(frame, tiltDegrees: tilt.freshTilt)
        case .setup, .countdown:
            alignment = checker.evaluate(frame: frame, tiltDegrees: tilt.freshTilt, exercise: exercise, side: side)
            if phase == .setup { say(alignment.firstFix ?? Strings.ready) }
        case .review: break
        }
    }

    func armHandsFree() {
        guard active, phase == .setup, attemptsLeft > 0, cameraProblem == nil else { return }
        handsFree.arm()
        waitingForPosition = true
        say(Loc.t("Step into view. Recording starts after you hold steady and the countdown ends."), force: true)
    }

    func cancelHandsFree() {
        handsFree.cancel()
        waitingForPosition = false
    }

    func startAttempt() {
        refreshReadiness()
        guard active, attemptTask == nil, phase == .setup, alignment.isReady, attemptsLeft > 0 else { return }
        cancelHandsFree()
        let token = generation
        attemptTask = Task { [weak self] in await self?.runAttempt(token: token) }
    }

    private func runAttempt(token: UUID) async {
        defer { if generation == token { attemptTask = nil } }
        do {
            say(Strings.getReady, force: true)
            for count in (1...Parameters.countdownSeconds).reversed() {
                phase = .countdown(count)
                instruction = Loc.f("Starting in %lld", count)
                speech.speak(String(count), force: true)
                try await Task.sleep(for: .seconds(1))
                refreshReadiness()
                guard alignment.isReady else {
                    phase = .setup
                    handsFree.arm(); waitingForPosition = true
                    say(Loc.t("Countdown paused. Hold steady in view to try again."), force: true)
                    return
                }
            }
            try Task.checkCancellation()
            refreshReadiness()
            guard active, generation == token, alignment.isReady else {
                if generation == token { phase = .setup; say(alignment.firstFix ?? Strings.fixStill, force: true) }
                return
            }
            let started = CameraService.now
            switch exercise {
            case .sitToStand: engine = SitToStandEngine(startTime: started)
            case .balance: engine = BalanceEngine(startTime: started)
            default: engine = JointAngleEngine(exercise: exercise, side: side, startTime: started)
            }
            phase = .recording
            Haptics.cue()
            say(exercise.movementCue, force: true)
            while CameraService.now - started < exercise.seconds {
                secondsRemaining = max(0, Int(ceil(exercise.seconds - (CameraService.now - started))))
                if engine?.isComplete == true { break }
                try await Task.sleep(for: .milliseconds(100))
            }
            secondsRemaining = 0
            try Task.checkCancellation()
            guard active, generation == token, let engine else { return }
            var result = engine.finish(endTime: CameraService.now)
            result.durationSeconds = CameraService.now - started
            results.append(result)
            self.engine = nil
            Haptics.cue()
            result.counted ? Haptics.success() : Haptics.warning()
            phase = .review
            say(Strings.attemptDone + " " + (result.counted ? Strings.counted : Strings.notCounted)
                + ". " + (result.reason?.message ?? ""), force: true)
        } catch {
            guard generation == token else { return }
            engine = nil
            phase = .setup
        }
    }

    // Finish speaking the result before giving the next setup cue.
    func prepareNextAttempt() {
        guard phase == .review, attemptsLeft > 0 else { return }
        invalidateSetup()
        phase = .setup
    }

    func cancelRecording() {
        guard phase == .recording || isCountingDown || waitingForPosition else { return }
        cancelHandsFree()
        generation = UUID()
        attemptTask?.cancel(); attemptTask = nil
        engine = nil
        speech.stop()
        invalidateSetup()
        phase = .setup
    }

    func makeSession() -> Session {
        let session = Session.recorded(exercise: exercise, side: side, results: results, template: template, cameraSource: camera.isFront ? "front" : "rear")
        session.planAtRecording = planAtStart
        return session
    }
}
