import Foundation

struct ReportExport: Codable, Identifiable {
    var id = UUID()
    var preparedAt = Date()
    var includesHistory: Bool
    var includesPlan: Bool
    var includesInstructions: Bool
    var handedToAnotherAppAt: Date?
}

extension Session {
    var recentExports: [ReportExport] {
        get { (try? JSONDecoder().decode([ReportExport].self, from: recentExportsData)) ?? [] }
        set { recentExportsData = (try? JSONEncoder().encode(Array(newValue.suffix(50)))) ?? Data() }
    }
}
