import Foundation

final class CSV {
    let fname: String
    private static let header = ["ID", "英文", "和文", "ヒント", "行", "頁", "章", "題目", "主題", "分野", "本", "備考"]

    init(fname: String = "ECompoData") { self.fname = fname }
    func getFName() -> String { fname + ".csv" }

    func CSVDataGen(records: [Record]) -> String {
        func quote(_ value: String) -> String {
            "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        let rows = records.map { $0.csvFields.map(quote).joined(separator: ",") }
        return ([Self.header.joined(separator: ",")] + rows).joined(separator: "\r\n") + "\r\n"
    }

    func reshape(url: URL) throws -> [Record] {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        // Local URLs may be readable without a security scope. Propagate actual read errors.
        return try parse(String(contentsOf: url, encoding: .utf8))
    }

    /// Parse quoted fields, escaped quotes and embedded newlines without changing field text.
    func parse(_ source: String) throws -> [Record] {
        var text = source
        if text.first == "\u{FEFF}" { text.removeFirst() }
        let characters = Array(text.unicodeScalars)
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var quoted = false
        var closedQuote = false
        var index = 0
        func endField() {
            row.append(field)
            field = ""
            closedQuote = false
        }
        func endRow() {
            endField()
            if row != [""] { rows.append(row) }
            row = []
        }
        while index < characters.count {
            let character = characters[index]
            if quoted {
                if character == "\"" {
                    if index + 1 < characters.count, characters[index + 1] == "\"" {
                        field.append("\"")
                        index += 1
                    } else {
                        quoted = false
                        closedQuote = true
                    }
                } else { field.unicodeScalars.append(character) }
            } else {
                switch character {
                case ",": endField()
                case "\r", "\n":
                    endRow()
                    if character == "\r", index + 1 < characters.count,
                       characters[index + 1] == "\n" { index += 1 }
                case "\"":
                    guard field.isEmpty, !closedQuote else {
                        throw DataError.invalid("CSVの引用符が不正です（レコード \(rows.count + 1)）。")
                    }
                    quoted = true
                default:
                    guard !closedQuote else {
                        throw DataError.invalid("CSVの引用符の後に区切り以外の文字があります。")
                    }
                    field.unicodeScalars.append(character)
                }
            }
            index += 1
        }
        guard !quoted else { throw DataError.invalid("CSVの引用符が閉じられていません。") }
        if !row.isEmpty || !field.isEmpty || closedQuote { endRow() }
        if let first = rows.first, first.first == "ID" {
            // Accept the trailing space in the legacy export's final heading.
            guard first.map({ $0.trimmingCharacters(in: .whitespaces) }) == Self.header else {
                throw DataError.invalid("CSVの見出しまたは列の順序が異なります。")
            }
            rows.removeFirst()
        }
        guard !rows.isEmpty else { throw DataError.invalid("CSVに取り込めるデータがありません。") }
        return try rows.enumerated().map { offset, values in
            do { return try Record(data: values) }
            catch { throw DataError.invalid("CSVレコード \(offset + 1): \(error.localizedDescription)") }
        }
    }
}
