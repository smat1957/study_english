import Foundation

// Keep this wire format identical in the iPhone and Watch targets.
struct WatchWord: Codable {
    let word: String
    let mean: String
    let type: String
    let book: String
    let stage: String
    let page: Int
}

struct WatchSnapshot: Codable {
    let protocolVersion: Int
    let revision: String
    let updatedAt: Double
    let current: Int
    let count: Int
    let entry: WatchWord?

    var isValid: Bool {
        protocolVersion == 1 && !revision.isEmpty && updatedAt.isFinite
            && count >= 0 && current >= 0
            && (count == 0 ? current == 0 && entry == nil : current < count && entry != nil)
    }
}
