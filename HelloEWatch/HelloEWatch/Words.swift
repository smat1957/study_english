import Foundation
import SQLite3

struct Words: Codable, Identifiable {
    var id = 0
    var seq = 0
    var word = ""
    var type = "noun"
    var mean = ""
    var expr = ""
    var simlr = ""
    var invrt = ""
    var relat = ""
    var eibun = ""
    var wabun = ""
    var descr = ""
    var book = ""
    var stage = "1"
    var page = 0
    var numb = 0

    init(book: String = "") { self.book = book }

    init(data: [String]) throws {
        guard data.count == 16 else { throw DataError.invalid("16列必要です（現在 \(data.count)列）。") }
        id = Int(data[0]) ?? 0 // Import always assigns a new local primary key.
        seq = try Self.number(data[1], name: "連番")
        word = data[2]; type = data[3]; mean = data[4]; expr = data[5]
        simlr = data[6]; invrt = data[7]; relat = data[8]; eibun = data[9]
        wabun = data[10]; descr = data[11]; book = data[12]; stage = data[13]
        page = try Self.number(data[14], name: "頁")
        numb = try Self.number(data[15], name: "通番")
        try validate()
    }

    static func number(_ value: String, name: String) throws -> Int {
        guard let number = Int(value.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw DataError.invalid("「\(name)」には整数を入力してください。")
        }
        return number
    }

    func validate() throws {
        guard !word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DataError.invalid("単語を入力してください。")
        }
        guard !csvFields.contains(where: { $0.contains("\0") }) else {
            throw DataError.invalid("NUL文字を含むデータは保存できません。")
        }
    }

    var csvFields: [String] {
        [String(id), String(seq), word, type, mean, expr, simlr, invrt, relat,
         eibun, wabun, descr, book, stage, String(page), String(numb)]
    }

    enum CodingKeys: String, CodingKey {
        case id, seq, word, type, mean, expr, simlr, invrt, relat, eibun, wabun, descr, book, stage, page, numb
    }

    // The original eight-field JSON remains readable. Missing fields use explicit defaults.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(Int.self, forKey: .id) ?? 0
        seq = try c.decodeIfPresent(Int.self, forKey: .seq) ?? 0
        word = try c.decode(String.self, forKey: .word)
        type = try c.decodeIfPresent(String.self, forKey: .type) ?? ""
        mean = try c.decode(String.self, forKey: .mean)
        expr = try c.decodeIfPresent(String.self, forKey: .expr) ?? ""
        simlr = try c.decodeIfPresent(String.self, forKey: .simlr) ?? ""
        invrt = try c.decodeIfPresent(String.self, forKey: .invrt) ?? ""
        relat = try c.decodeIfPresent(String.self, forKey: .relat) ?? ""
        eibun = try c.decode(String.self, forKey: .eibun)
        wabun = try c.decode(String.self, forKey: .wabun)
        descr = try c.decodeIfPresent(String.self, forKey: .descr) ?? ""
        book = try c.decode(String.self, forKey: .book)
        stage = try c.decode(String.self, forKey: .stage)
        page = try c.decode(Int.self, forKey: .page)
        numb = try c.decode(Int.self, forKey: .numb)
        try validate()
    }
}
