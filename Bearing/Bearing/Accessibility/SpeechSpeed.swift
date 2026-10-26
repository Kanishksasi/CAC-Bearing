import AVFoundation

enum SpeechSpeed: String, CaseIterable, Identifiable {
    case slower, normal, faster
    var id: String { rawValue }
    var title: String {
        switch self {
        case .slower: return Loc.t("Slower")
        case .normal: return Loc.t("Standard")
        case .faster: return Loc.t("Faster")
        }
    }
    var rate: Float {
        let multiplier: Float = self == .slower ? 0.7 : self == .faster ? 1.1 : 0.9
        return min(AVSpeechUtteranceMaximumSpeechRate, max(AVSpeechUtteranceMinimumSpeechRate,
                   AVSpeechUtteranceDefaultSpeechRate * multiplier))
    }
}
