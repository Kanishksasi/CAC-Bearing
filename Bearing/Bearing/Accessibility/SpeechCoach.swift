import AVFoundation
import UIKit

@MainActor

final class SpeechCoach {
    private let synthesizer = AVSpeechSynthesizer()
    var isEnabled = true
    var speed: SpeechSpeed = .normal
    private var lastSpoken = ""
    private var lastSpokenAt = Date.distantPast

    func speak(_ text: String, force: Bool = false) {
        #if DEBUG && targetEnvironment(simulator)
        if ProcessInfo.processInfo.arguments.contains("-UITestSilent") { return }
        #endif
        guard isEnabled else { return }
        if !force && Date().timeIntervalSince(lastSpokenAt) < Parameters.speechMinIntervalSeconds { return }
        if !force && text == lastSpoken && Date().timeIntervalSince(lastSpokenAt) < Parameters.speechRepeatSeconds { return }
        lastSpoken = text
        lastSpokenAt = Date()
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = speed.rate
        utterance.voice = Loc.speechTags.compactMap { AVSpeechSynthesisVoice(language: $0) }.first
        synthesizer.speak(utterance)
    }

    func repeatOnce(_ text: String) {
        let previous = isEnabled
        isEnabled = true
        defer { isEnabled = previous }
        speak(text, force: true)
    }

    func stop() { synthesizer.stopSpeaking(at: .immediate) }
}

@MainActor
enum Haptics {
    static func cue() { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
}
