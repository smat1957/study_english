import Foundation
import SQLite3

struct Record {
    var id: Int
    var eibun: String
    var wabun: String
    var hint: String
    var line: Int
    var page: Int
    var chap: Int
    var title: String
    var topic: String
    var field: String
    var book: String
    var description: String

    /// Validate before any write, including all rows of an import.
    init(data: [String]) throws {
        guard data.count == 12 else {
            throw DataError.invalid("12列必要です（現在 \(data.count)列）。")
        }
        id = Int(data[0]) ?? 0 // Imported IDs are not reused when appending.
        eibun = data[1]; wabun = data[2]; hint = data[3]
        line = try Self.number(data[4], name: "行")
        page = try Self.number(data[5], name: "頁")
        chap = try Self.number(data[6], name: "章")
        title = data[7]; topic = data[8]; field = data[9]
        book = data[10]; description = data[11]
        guard !data.contains(where: { $0.contains("\0") }) else {
            throw DataError.invalid("NUL文字を含むデータは保存できません。")
        }
    }

    static func number(_ value: String, name: String) throws -> Int {
        guard let result = Int(value.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw DataError.invalid("「\(name)」には整数を入力してください。")
        }
        return result
    }

    var csvFields: [String] {
        [String(id), eibun, wabun, hint, String(line), String(page), String(chap),
         title, topic, field, book, description]
    }
}

final class DAO: SQLite3 {
    private let columns = "id,eibun,wabun,hint,line,page,chap,title,topic,field,book,description"
    private let order = " ORDER BY book,chap,page,line,id"

    func initial() throws {
        let directory = try FileManager.default.url(for: .documentDirectory,
            in: .userDomainMask, appropriateFor: nil, create: true)
        try open(path: directory.appendingPathComponent("ecompo_sqlite3").path)
        try exec("CREATE TABLE IF NOT EXISTS ecompo (id INTEGER PRIMARY KEY AUTOINCREMENT,eibun TEXT,wabun TEXT,hint TEXT,line INTEGER,page INTEGER,chap INTEGER,title TEXT,topic TEXT,field TEXT,book TEXT,description TEXT)")
    }

    private func bind(_ record: Record) throws {
        let fields = record.csvFields
        for index in 1..<12 {
            switch index {
            case 4: try bindInt(index: index, value: record.line)
            case 5: try bindInt(index: index, value: record.page)
            case 6: try bindInt(index: index, value: record.chap)
            default: try bindText(index: index, value: fields[index])
            }
        }
    }

    @discardableResult
    func insert(_ record: Record) throws -> Int {
        defer { finalizeStatement() }
        try prepare("INSERT INTO ecompo (eibun,wabun,hint,line,page,chap,title,topic,field,book,description) VALUES (?,?,?,?,?,?,?,?,?,?,?)")
        try bind(record)
        guard try step() == SQLITE_DONE else { throw DataError.database("保存が完了しませんでした。") }
        return lastInsertedID()
    }

    func update(_ record: Record, id: Int) throws {
        guard id > 0 else { throw DataError.invalid("更新するデータがありません。") }
        defer { finalizeStatement() }
        try prepare("UPDATE ecompo SET eibun=?,wabun=?,hint=?,line=?,page=?,chap=?,title=?,topic=?,field=?,book=?,description=? WHERE id=?")
        try bind(record)
        try bindInt(index: 12, value: id)
        guard try step() == SQLITE_DONE, changedRows() == 1 else {
            throw DataError.database("更新対象が見つかりません。")
        }
    }

    func delete(id: Int) throws {
        guard id > 0 else { throw DataError.invalid("削除するデータがありません。") }
        defer { finalizeStatement() }
        try prepare("DELETE FROM ecompo WHERE id=?")
        try bindInt(index: 1, value: id)
        guard try step() == SQLITE_DONE, changedRows() == 1 else {
            throw DataError.database("削除対象が見つかりません。")
        }
    }

    func clearAllRecords() throws {
        try transaction {
            try exec("DELETE FROM ecompo")
        }
    }

    func importRecords(_ records: [Record], replacing: Bool) throws {
        guard !records.isEmpty else { throw DataError.invalid("取り込むデータがありません。") }
        try transaction {
            // Replacement applies to the entire database, using only the selected input records.
            // The transaction restores the previous data if any insert or commit fails.
            if replacing { try exec("DELETE FROM ecompo") }
            for record in records { try insert(record) }
        }
    }

    func distinct(field_name: String, book: String? = nil) throws -> [String] {
        guard ["book", "field", "topic", "title"].contains(field_name) else {
            throw DataError.invalid("検索項目が不正です。")
        }
        defer { finalizeStatement() }
        let filter = book == nil ? "" : " WHERE book=?"
        try prepare("SELECT DISTINCT COALESCE(\(field_name),'') FROM ecompo\(filter) ORDER BY 1")
        if let book = book { try bindText(index: 1, value: book) }
        var values: [String] = []
        while try step() == SQLITE_ROW { values.append(columnText(index: 0)) }
        return values
    }

    func select_all() throws -> [Record] { try select() }
    func select_book(book: String) throws -> [Record] { try select(book: book) }
    func select_book_page(book: String, page: Int) throws -> [Record] {
        try select(book: book, field: "page", number: page)
    }
    func select_book_field(book: String, field: String) throws -> [Record] {
        try select(book: book, field: "field", text: field)
    }
    func select_book_topic(book: String, topic: String) throws -> [Record] {
        try select(book: book, field: "topic", text: topic)
    }
    func select_book_title(book: String, title: String) throws -> [Record] {
        try select(book: book, field: "title", text: title)
    }

    private func select(book: String? = nil, field: String? = nil,
                        text: String? = nil, number: Int? = nil) throws -> [Record] {
        defer { finalizeStatement() }
        var sql = "SELECT \(columns) FROM ecompo"
        if book != nil { sql += " WHERE book=?" }
        if let field = field { sql += " AND \(field)=?" }
        try prepare(sql + order)
        if let book = book { try bindText(index: 1, value: book) }
        if let text = text { try bindText(index: 2, value: text) }
        if let number = number { try bindInt(index: 2, value: number) }
        var result: [Record] = []
        while try step() == SQLITE_ROW {
            var fields = [String(columnInt(index: 0))]
            for index in 1..<12 {
                fields.append((4...6).contains(index)
                    ? String(columnInt(index: index)) : columnText(index: index))
            }
            result.append(try Record(data: fields))
        }
        return result
    }
}
