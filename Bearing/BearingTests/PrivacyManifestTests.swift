import XCTest

final class PrivacyManifestTests: XCTestCase {
    func testBundledManifestDeclaresElapsedTimeAndNoTracking() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"))
        let data = try Data(contentsOf: url)
        let manifest = try XCTUnwrap(PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any])
        XCTAssertEqual(manifest["NSPrivacyTracking"] as? Bool, false)
        XCTAssertEqual((manifest["NSPrivacyTrackingDomains"] as? [String])?.count, 0)
        XCTAssertEqual((manifest["NSPrivacyCollectedDataTypes"] as? [[String: Any]])?.count, 0)
        let reasons = try XCTUnwrap(manifest["NSPrivacyAccessedAPITypes"] as? [[String: Any]])
        let timer = try XCTUnwrap(reasons.first { $0["NSPrivacyAccessedAPIType"] as? String == "NSPrivacyAccessedAPICategorySystemBootTime" })
        XCTAssertTrue((timer["NSPrivacyAccessedAPITypeReasons"] as? [String])?.contains("35F9.1") == true)
    }
}
