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

enum WordSearch: String, CaseIterable, Identifiable {
    case all = "全", book = "本", stage = "章", page = "頁", numb = "番", word = "単"
    var id: String { rawValue }
}

final class DAO: SQLite3 {
    func initial() throws {
        let directory = try FileManager.default.url(for: .documentDirectory,
            in: .userDomainMask, appropriateFor: nil, create: true)
        try open(path: directory.appendingPathComponent("eword_sqlite3").path)
        try exec("""
        CREATE TABLE IF NOT EXISTS eword (
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, seq INTEGER, word TEXT NOT NULL,
        type TEXT, mean TEXT, expr TEXT, simlr TEXT, invrt TEXT, relat TEXT,
        eibun TEXT, wabun TEXT, descr TEXT, book TEXT, stage TEXT, page INTEGER, numb INTEGER)
        """)
    }

    private func bind(_ record: Words) throws {
        for i in 1..<16 {
            switch i {
            case 1: try bindInt(index: i, value: record.seq)
            case 14: try bindInt(index: i, value: record.page)
            case 15: try bindInt(index: i, value: record.numb)
            default: try bindText(index: i, value: record.csvFields[i])
            }
        }
    }

    @discardableResult
    func insert(_ record: Words) throws -> Int {
        try record.validate()
        defer { finalizeStatement() }
        try prepare("INSERT INTO eword (seq,word,type,mean,expr,simlr,invrt,relat,eibun,wabun,descr,book,stage,page,numb) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)")
        try bind(record)
        guard try step() == SQLITE_DONE else { throw DataError.database("保存が完了しませんでした。") }
        return lastInsertedID()
    }

    func update(_ record: Words) throws {
        try record.validate()
        guard record.id > 0 else { throw DataError.invalid("更新対象がありません。") }
        defer { finalizeStatement() }
        try prepare("UPDATE eword SET seq=?,word=?,type=?,mean=?,expr=?,simlr=?,invrt=?,relat=?,eibun=?,wabun=?,descr=?,book=?,stage=?,page=?,numb=? WHERE id=?")
        try bind(record)
        try bindInt(index: 16, value: record.id)
        guard try step() == SQLITE_DONE, changedRows() == 1 else { throw DataError.database("更新対象が見つかりません。") }
    }

    func delete(id: Int) throws {
        guard id > 0 else { throw DataError.invalid("削除対象がありません。") }
        defer { finalizeStatement() }
        try prepare("DELETE FROM eword WHERE id=?")
        try bindInt(index: 1, value: id)
        guard try step() == SQLITE_DONE, changedRows() == 1 else { throw DataError.database("削除対象が見つかりません。") }
    }

    func clearAllRecords() throws { try transaction { try exec("DELETE FROM eword") } }

    func importRecords(_ records: [Words], replacing: Bool) throws {
        guard !records.isEmpty else { throw DataError.invalid("取り込むデータがありません。") }
        for record in records { try record.validate() }
        try transaction {
            if replacing { try exec("DELETE FROM eword") }
            for record in records { try insert(record) }
        }
    }

    func books() throws -> [String] {
        defer { finalizeStatement() }
        try prepare("SELECT DISTINCT COALESCE(book,'') FROM eword ORDER BY book")
        var result: [String] = []
        while try step() == SQLITE_ROW { result.append(columnText(index: 0)) }
        return result
    }

    func select(_ scope: WordSearch = .all, book: String = "", value: String = "",
                throughPage: Int? = nil) throws -> [Words] {
        defer { finalizeStatement() }
        var condition = ""
        switch scope {
        case .all: break
        case .book: condition = " WHERE book=?"
        case .stage: condition = " WHERE book=? AND stage=?"
        case .page: condition = throughPage == nil ? " WHERE book=? AND page=?" : " WHERE book=? AND page BETWEEN ? AND ?"
        case .numb: condition = " WHERE book=? AND numb=?"
        case .word: condition = " WHERE book=? AND word=?"
        }
        try prepare("SELECT id,seq,word,type,mean,expr,simlr,invrt,relat,eibun,wabun,descr,book,stage,page,numb FROM eword" + condition + " ORDER BY book,stage,page,numb,word,seq,id")
        if scope != .all { try bindText(index: 1, value: book) }
        if scope == .page || scope == .numb {
            try bindInt(index: 2, value: Words.number(value, name: scope.rawValue))
            if let throughPage = throughPage, scope == .page { try bindInt(index: 3, value: throughPage) }
        } else if scope == .stage || scope == .word { try bindText(index: 2, value: value) }
        return try readRecords()
    }

    func selectFiltered(book: String, stage: String?, page: Int?, number: Int?) throws -> [Words] {
        defer { finalizeStatement() }
        let condition = filterCondition(stage: stage, page: page, number: number)
        try prepare("SELECT id,seq,word,type,mean,expr,simlr,invrt,relat,eibun,wabun,descr,book,stage,page,numb FROM eword" + condition + " ORDER BY book,stage,page,numb,word,seq,id")
        try bindFilter(book: book, stage: stage, page: page, number: number)
        return try readRecords()
    }

    func filterChoices(field: String, book: String, stage: String? = nil, page: Int? = nil) throws -> [String] {
        guard ["stage", "page", "numb"].contains(field) else { throw DataError.invalid("選択項目が不正です。") }
        defer { finalizeStatement() }
        try prepare("SELECT DISTINCT COALESCE(\(field),\(field == "stage" ? "''" : "0")) FROM eword" + filterCondition(stage: stage, page: page, number: nil))
        try bindFilter(book: book, stage: stage, page: page, number: nil)
        var values: [String] = []
        while try step() == SQLITE_ROW {
            values.append(field == "stage" ? columnText(index: 0) : String(columnInt(index: 0)))
        }
        return values.sorted { lhs, rhs in
            if field != "stage", let a = Int(lhs), let b = Int(rhs) { return a < b }
            let comparison = lhs.localizedStandardCompare(rhs)
            return comparison == .orderedSame ? lhs < rhs : comparison == .orderedAscending
        }
    }

    private func filterCondition(stage: String?, page: Int?, number: Int?) -> String {
        " WHERE COALESCE(book,'')=?" + (stage == nil ? "" : " AND COALESCE(stage,'')=?")
            + (page == nil ? "" : " AND COALESCE(page,0)=?") + (number == nil ? "" : " AND COALESCE(numb,0)=?")
    }

    private func bindFilter(book: String, stage: String?, page: Int?, number: Int?) throws {
        try bindText(index: 1, value: book)
        var index = 2
        if let stage { try bindText(index: index, value: stage); index += 1 }
        if let page { try bindInt(index: index, value: page); index += 1 }
        if let number { try bindInt(index: index, value: number) }
    }

    private func readRecords() throws -> [Words] {
        var result: [Words] = []
        while try step() == SQLITE_ROW {
            var r = Words()
            r.id = columnInt(index: 0); r.seq = columnInt(index: 1)
            r.word = columnText(index: 2); r.type = columnText(index: 3)
            r.mean = columnText(index: 4); r.expr = columnText(index: 5)
            r.simlr = columnText(index: 6); r.invrt = columnText(index: 7)
            r.relat = columnText(index: 8); r.eibun = columnText(index: 9)
            r.wabun = columnText(index: 10); r.descr = columnText(index: 11)
            r.book = columnText(index: 12); r.stage = columnText(index: 13)
            r.page = columnInt(index: 14); r.numb = columnInt(index: 15)
            result.append(r)
        }
        return result
    }
}
