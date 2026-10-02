import SwiftUI

enum TransferMode: String, CaseIterable {
    case normal, repeating, randomOnce, random

    var title: String {
        switch self {
        case .normal: return "検索結果順で転送・1回"
        case .repeating: return "検索結果順で転送・反復"
        case .randomOnce: return "ランダム順で転送・1回"
        case .random: return "ランダム順で転送・反復"
        }
    }

    var symbol: String { isRandom ? "shuffle" : "repeat" }
    var color: Color { isRandom ? .blue : .red }
    var isRandom: Bool { self == .random || self == .randomOnce }
    var isOnce: Bool { self == .normal || self == .randomOnce }
}
