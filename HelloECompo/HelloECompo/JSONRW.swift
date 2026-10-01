import Foundation

final class JSONRW {
    /// Includes all CSV/database fields. Optional fields accept the previous eight-field JSON.
    private struct Entry: Codable {
        let id: Int?
        let book: String
        let field: String
        let topic: String
        let title: String
        let page: Int
        let line: Int
        let wabun: String
        let eibun: String
        let hint: String?
        let chap: Int?
        let description: String?

        init(record: Record) {
            id = record.id; book = record.book; field = record.field
            topic = record.topic; title = record.title
            page = record.page; line = record.line
            wabun = record.wabun; eibun = record.eibun
            hint = record.hint; chap = record.chap; description = record.description
        }

        func validatedRecord() throws -> Record {
            try Record(data: [String(id ?? 0), eibun, wabun, hint ?? "",
                              String(line), String(page), String(chap ?? 0),
                              title, topic, field, book, description ?? ""])
        }
    }

    func generate(records: [Record]) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(records.map { Entry(record: $0) })
        return String(decoding: data, as: UTF8.self)
    }

    func read(url: URL) throws -> [Record] {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        let entries = try JSONDecoder().decode([Entry].self, from: Data(contentsOf: url))
        guard !entries.isEmpty else { throw DataError.invalid("JSONに取り込めるデータがありません。") }
        return try entries.enumerated().map { index, entry in
            do { return try entry.validatedRecord() }
            catch { throw DataError.invalid("JSONレコード \(index + 1): \(error.localizedDescription)") }
        }
    }
}
