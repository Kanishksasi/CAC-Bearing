import XCTest
import PDFKit
@testable import Bearing

final class LocalizationTests: XCTestCase {
    func testEveryActiveStringHasSpanishText() {
        for key in ActiveAppText.keys where key != "Bearing" && key != "OK" {
            let value = Loc.t(key, language: "es")
            XCTAssertNotEqual(value, key, "Missing Spanish: \(key)")
        }
    }
    func testRequiredDisclaimerIsExactInBothLanguages() {
        let key = "For personal tracking only. Not medical advice or a diagnosis. Share with your clinician."
        XCTAssertEqual(Loc.t(key, language: "en"), key)
        XCTAssertEqual(Loc.t(key, language: "es"), "Solo para seguimiento personal. No es consejo médico ni un diagnóstico. Comparta esto con su profesional de la salud.")
    }
    func testActiveCopyAvoidsBannedWordsOutsideRequiredDisclaimer() throws {
        let english = ["diagnose", "diagnosis", "detect", "assess", "evaluate", "treat", "clinical", "screening", "patient", "normal", "abnormal", "good", "poor", "pass", "fail", "improvement"]
        let spanish = ["diagnosticar", "diagnóstico", "detectar", "evaluar", "tratar", "tratamiento", "clínico", "tamizaje", "paciente", "normal", "anormal", "bueno", "buena", "malo", "mala", "aprobar", "reprobar", "fallar"]
        for language in ["en", "es"] {
            for key in ActiveAppText.keys {
                let text = Loc.t(key, language: language)
                XCTAssertFalse(text.contains("\u{2014}"), text)
                if key.hasPrefix("For personal tracking only.") { continue }
                let words = Set(text.lowercased().components(separatedBy: CharacterSet.letters.inverted))
                for banned in language == "en" ? english : spanish { XCTAssertFalse(words.contains(banned), text) }
            }
        }
    }
    func testSentencesUseAtMostEighteenWords() {
        for language in ["en", "es"] {
            for key in ActiveAppText.keys {
                let text = Loc.t(key, language: language)
                for sentence in text.components(separatedBy: CharacterSet(charactersIn: ".!?")) {
                    let words = sentence.split(whereSeparator: { $0.isWhitespace })
                    XCTAssertLessThanOrEqual(words.count, 18, "\(language): \(sentence)")
                }
            }
        }
    }
    @MainActor
    func testSpanishPDFHasSpanishDisclaimerAndResult() {
        Loc.preference = .spanish
        defer { Loc.preference = .system }
        let session = Session(side: .right, attemptCount: 3, countedPeaks: [100, 110], notCountedReasons: ["tilt"])
        let bytes = ReportBuilder.data(for: session, in: [session])
        let document = PDFDocument(data: bytes)
        XCTAssertTrue(document?.string?.contains("Brazo derecho") == true)
        XCTAssertTrue(document?.string?.contains("2 de 3 intentos contados") == true)
        let text = (document?.string ?? "").split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
        XCTAssertTrue(text.contains(Strings.disclaimer), text)
        if let document {
            for index in 0..<document.pageCount {
                if let page = document.page(at: index) {
                    let attachment = XCTAttachment(image: page.thumbnail(of: CGSize(width: 918, height: 1188), for: .mediaBox))
                    attachment.name = "Spanish-PDF-page-\(index + 1)"
                    attachment.lifetime = .keepAlways
                    add(attachment)
                }
            }
        }
    }
}
