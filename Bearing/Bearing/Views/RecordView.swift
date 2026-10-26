import SwiftUI
import SwiftData
import AVFoundation

struct RecordView: View {
    @ObservedObject var coordinator: SessionCoordinator
    let side: Side
    let voiceEnabled: Bool
    @Query private var plans: [CarePlan]
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @State private var saved: Session?
    @State private var showResult = false
    @State private var saveError = false

    var body: some View {
        BearingPage {
            VStack(alignment: .leading, spacing: 12) {
                SectionCaption(title: "2. Record")
                HStack(spacing: 8) {
                    ForEach(0..<coordinator.exercise.attempts, id: \.self) { index in
                        Capsule().fill(index < coordinator.results.count ? Color.accentColor : BearingStyle.line)
                            .frame(height: 5)
                    }
                }.accessibilityHidden(true)
                Text(Loc.f("Attempt %lld of %lld", min(coordinator.results.count + (coordinator.phase == .review ? 0 : 1), coordinator.exercise.attempts), coordinator.exercise.attempts))
                    .font(.subheadline).foregroundStyle(BearingStyle.muted)
                Text(coordinator.instruction).font(.title3.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
            }
            if coordinator.phase == .setup {
                Text(coordinator.waitingForPosition
                     ? Loc.t("Hold steady in view. The countdown starts when the setup is ready.")
                     : Loc.t("Tap now, then step into view. You do not need to touch the phone again."))
                    .font(.callout).foregroundStyle(BearingStyle.muted)
            }
            if coordinator.phase != .review {
                ZStack {
                    Color.black
                    CameraPreview(session: coordinator.camera.session, mirrored: coordinator.camera.isFront)
                    SkeletonOverlay(frame: coordinator.overlayFrame, mirrored: coordinator.camera.isFront)
                    if case .countdown(let count) = coordinator.phase {
                        Text("\(count)").font(.largeTitle.bold()).padding(24)
                            .foregroundStyle(.white).background(.black.opacity(0.8), in: Circle())
                    }
                }
                .aspectRatio(9.0 / 16.0, contentMode: .fit)
                .frame(maxWidth: 208)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .frame(maxWidth: .infinity)
                .accessibilityLabel(Loc.t("Live camera. Pictures are not saved."))
            }
            if coordinator.phase == .setup || isCountingDown { checklist }
            if coordinator.phase == .recording || isCountingDown {
                if coordinator.phase == .recording { Text(Loc.f("%lld seconds remaining", coordinator.secondsRemaining)).font(.headline).monospacedDigit() }
                Button("Stop without saving", role: .destructive) { coordinator.cancelRecording() }
                    .frame(minHeight: 48).tint(BearingStyle.danger)
            }
            if !coordinator.results.isEmpty {
                VStack(alignment: .leading, spacing: 18) {
                    SectionCaption(title: "Your attempts")
                    ForEach(Array(coordinator.results.enumerated()), id: \.offset) { index, result in
                        VStack(alignment: .leading, spacing: 8) {
                            Label(Loc.f("Attempt %lld: %@", index + 1,
                                        result.counted ? Strings.counted : Strings.notCounted),
                                  systemImage: result.counted ? "checkmark.circle" : "exclamationmark.circle")
                                .font(.headline)
                            if result.counted, let peak = result.peakAngle {
                                Text(Loc.f("Projected angle: %.0f degrees", peak))
                                Text(coordinator.exercise.resultMeaning).font(.callout).foregroundStyle(BearingStyle.muted)
                            }
                            if let repetitions = result.repetitions { Text(Loc.f("%lld repetitions", repetitions)) }
                            if let hold = result.holdSeconds { Text(Loc.f("%.1f seconds", hold)) }
                            if let reason = result.reason { Text(reason.message).foregroundStyle(BearingStyle.muted) }
                        }.frame(maxWidth: .infinity, alignment: .leading)
                        if index < coordinator.results.count - 1 { Divider().overlay(BearingStyle.line) }
                    }
                }.padding(20).background(BearingStyle.surface, in: RoundedRectangle(cornerRadius: 20))
            }
            if coordinator.phase == .setup && !coordinator.waitingForPosition { startButton }
            Button { coordinator.repeatInstructions() } label: {
                Label("Repeat instructions", systemImage: "speaker.wave.2")
            }.buttonStyle(BearingSecondaryButton())
            #if DEBUG
            if coordinator.measuredFPS > 0 {
                Text(Loc.f("Processing about %.0f frames per second", coordinator.measuredFPS))
                    .font(.footnote).foregroundStyle(BearingStyle.muted)
            }
            #endif
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Group {
                if coordinator.phase == .setup {
                    VStack(spacing: 10) {
                        if coordinator.waitingForPosition {
                            Label("Waiting for your position", systemImage: "person.crop.rectangle")
                                .font(.headline).foregroundStyle(Color.accentColor)
                            Button("Stop without saving", role: .destructive) { coordinator.cancelRecording() }
                                .frame(minHeight: 48).tint(BearingStyle.danger)
                        } else {
                            Button("Start when ready") { coordinator.armHandsFree() }
                                .buttonStyle(BearingPrimaryButton()).accessibilityIdentifier("HandsFreeStart")
                        }
                    }
                } else if coordinator.phase == .review {
                    if coordinator.attemptsLeft > 0 {
                        Button("Set up next attempt") { coordinator.prepareNextAttempt() }
                            .buttonStyle(BearingPrimaryButton())
                    } else {
                        Button("Save and see results") { save() }.buttonStyle(BearingPrimaryButton())
                    }
                }
            }.frame(maxWidth: .infinity).padding(.horizontal, 24).padding(.vertical, 12).background(BearingStyle.paper)
        }
        .navigationTitle(coordinator.exercise.isAngle ? coordinator.exercise.sideTitle(side) : coordinator.exercise.title)
        .task { coordinator.chooseSide(side); coordinator.planAtStart = plans.first?.currentRevision; await coordinator.begin(voiceEnabled: voiceEnabled) }
        .onDisappear { coordinator.end() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { coordinator.end() }
            else { Task { await coordinator.begin(voiceEnabled: voiceEnabled) } }
        }
        .navigationDestination(isPresented: $showResult) {
            if let saved { ResultView(session: saved) }
        }
        .alert(Loc.t(coordinator.cameraProblem == .permissionDenied ? "Camera access is off" : "The camera could not start"),
               isPresented: Binding(get: { coordinator.cameraProblem != nil }, set: { if !$0 { coordinator.cameraProblem = nil } })) {
            if coordinator.cameraProblem == .permissionDenied {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                }
            }
            Button("OK", role: .cancel) { coordinator.cameraProblem = nil }
        } message: {
            Text(Loc.t(coordinator.cameraProblem == .permissionDenied
                 ? "Turn on the camera for Bearing in Settings to measure your movement."
                 : "Close other apps that use the camera, then open Bearing again."))
        }
        .alert("Session could not be saved", isPresented: $saveError) {
            Button("OK", role: .cancel) {}
        } message: { Text("Your results are still here. Try saving again.") }
    }

    private var isCountingDown: Bool { if case .countdown = coordinator.phase { return true }; return false }

    private var checklist: some View {
        let state = coordinator.alignment
        return VStack(alignment: .leading, spacing: 4) {
            SectionCaption(title: "Before each attempt")
            GateRow(title: Loc.t("One person in view"), ok: state.singlePerson)
            GateRow(title: Loc.t("Required joints in view"), ok: state.jointsVisible)
            GateRow(title: Loc.t("Distance and framing"), ok: state.framing == .ok)
            GateRow(title: Loc.t("Phone upright"), ok: state.tiltOK)
            GateRow(title: Loc.t("Holding still"), ok: state.stable)
        }.accessibilityElement(children: .combine)
    }

    private var startButton: some View {
        let ready = coordinator.alignment.isReady
        return Text(ready ? Loc.t("Hold to start now") : Loc.t("Start attempt"))
            .font(.headline).multilineTextAlignment(.center).padding(12)
            .frame(maxWidth: .infinity, minHeight: 64)
            .foregroundStyle(ready ? BearingStyle.onAccent : BearingStyle.muted)
            .background(ready ? Color.accentColor : BearingStyle.wash, in: RoundedRectangle(cornerRadius: 18))
            .onLongPressGesture(minimumDuration: Parameters.holdToStartSeconds) { coordinator.startAttempt() }
            .accessibilityIdentifier("StartAttempt")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { coordinator.startAttempt() }
            .accessibilityHint(Loc.f("Starts a countdown, then records for %lld seconds.", Int(coordinator.exercise.seconds)))
            .disabled(!ready)
    }

    private func save() {
        if saved != nil { showResult = true; return }
        let session = coordinator.makeSession()
        do {
            try SessionStore(context: context).save(session)
            refreshReminders()
            saved = session
            showResult = true
        } catch { saveError = true }
    }
    private func refreshReminders() {
        Task { @MainActor in
            let plan = (try? context.fetch(FetchDescriptor<CarePlan>()))?.first
            let sessions = (try? context.fetch(FetchDescriptor<Session>())) ?? []
            await ReminderScheduler(center: SystemNotificationCenter()).sync(plan: plan, body: ReminderText.body, sessions: sessions)
        }
    }

}

struct GateRow: View {
    let title: String
    let ok: Bool
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title).font(.body)
                    status
                }.padding(.vertical, 10).frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack {
                    Text(title).font(.body)
                    Spacer()
                    status
                }.frame(minHeight: 36)
            }
        }.accessibilityElement(children: .combine)
    }

    private var status: some View {
        HStack(spacing: 6) {
            Image(systemName: ok ? "checkmark.circle.fill" : "minus.circle")
                .font(.system(size: 18)).accessibilityHidden(true)
            Text(ok ? Loc.t("Ready") : Loc.t("Fix")).font(.subheadline.weight(.semibold))
        }.foregroundStyle(ok ? Color.accentColor : BearingStyle.muted)
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    var mirrored = true

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var mirrored = true
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
        override func layoutSubviews() {
            super.layoutSubviews()
            previewLayer.videoGravity = .resizeAspectFill
            if let c = previewLayer.connection {
                c.automaticallyAdjustsVideoMirroring = false
                if c.isVideoMirroringSupported { c.isVideoMirrored = mirrored }
                if c.isVideoRotationAngleSupported(90) { c.videoRotationAngle = 90 }
            }
        }
    }

    func makeUIView(context: Context) -> PreviewView {
        let v = PreviewView(); v.mirrored = mirrored; v.previewLayer.session = session; return v
    }
    func updateUIView(_ uiView: PreviewView, context: Context) { uiView.mirrored = mirrored; uiView.setNeedsLayout() }
}

struct SkeletonOverlay: View {
    let frame: PoseFrame?
    var mirrored = true
    var body: some View {
        Canvas { context, size in
            guard let frame else { return }
            // Mirror the display once here. Never mirror the measurement data.
            func point(_ name: JointName) -> (CGPoint, JointPoint)? {
                guard let j = frame.joints[name] else { return nil }
                return (Geometry.displayPoint(j.position, image: frame.size, view: size, mirrored: mirrored), j)
            }
            let bones: [(JointName, JointName)] = [
                (.leftShoulder, .rightShoulder), (.leftHip, .rightHip), (.leftShoulder, .leftHip),
                (.rightShoulder, .rightHip), (.leftShoulder, .leftElbow), (.rightShoulder, .rightElbow),
                (.leftHip, .leftKnee), (.rightHip, .rightKnee), (.leftKnee, .leftAnkle), (.rightKnee, .rightAnkle),
                (.leftElbow, .leftWrist), (.rightElbow, .rightWrist)]
            for (a, b) in bones {
                if let pa = point(a), let pb = point(b) {
                    var path = Path(); path.move(to: pa.0); path.addLine(to: pb.0)
                    context.stroke(path, with: .color(.white), lineWidth: 4)
                }
            }
            for name in JointName.allCases {
                if let (p, j) = point(name) {
                    let rect = CGRect(x: p.x - 8, y: p.y - 8, width: 16, height: 16)
                    if j.isImputed { context.stroke(Path(ellipseIn: rect), with: .color(.yellow), lineWidth: 3) }
                    else { context.fill(Path(ellipseIn: rect), with: .color(.green)) }
                }
            }
        }
        .accessibilityHidden(true)
    }
}
