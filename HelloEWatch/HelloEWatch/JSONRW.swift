import Foundation

final class JSONRW {
    struct Question: Encodable {
        let book: String
        let stage: String
        let page: Int
        let numb: Int
        let word: String
        let mean: String
        let eibun: String
        let wabun: String
        init(_ record: Words) {
            book = record.book; stage = record.stage; page = record.page; numb = record.numb
            word = record.word; mean = record.mean; eibun = record.eibun; wabun = record.wabun
        }
    }

    func generate(records: [Words], questionsOnly: Bool = false) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = questionsOnly ? try encoder.encode(records.map(Question.init)) : try encoder.encode(records)
        guard let text = String(data: data, encoding: .utf8) else { throw DataError.invalid("JSONを生成できません。") }
        return text
    }

    func read(url: URL) throws -> [Words] {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        return try parse(Data(contentsOf: url))
    }

    func parse(_ data: Data) throws -> [Words] {
        let records = try JSONDecoder().decode([Words].self, from: data)
        guard !records.isEmpty else { throw DataError.invalid("JSONに取り込めるデータがありません。") }
        for record in records { try record.validate() }
        return records
    }
}
