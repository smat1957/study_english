import Foundation
import SQLite3

/// Access only from WatchStore's serial database queue.
final class DAO: SQLite3 {
    func initial() throws {
        let directory = try FileManager.default.url(for: .documentDirectory,
            in: .userDomainMask, appropriateFor: nil, create: true)
        // Keep the original database and table so existing installations retain their words.
        try open(path: directory.appendingPathComponent("eword_watch_sqlite3").path)
        try exec("""
        CREATE TABLE IF NOT EXISTS watchEword (
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, seq INTEGER, word TEXT NOT NULL,
        type TEXT, mean TEXT, expr TEXT, simlr TEXT, invrt TEXT, relat TEXT,
        eibun TEXT, wabun TEXT, descr TEXT, book TEXT, stage TEXT, page INTEGER, numb INTEGER)
        """)
    }

    private func insert(_ record: Words) throws {
        defer { finalizeStatement() }
        try prepare("INSERT INTO watchEword (seq,word,type,mean,expr,simlr,invrt,relat,eibun,wabun,descr,book,stage,page,numb) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)")
        let fields = record.csvFields
        for index in 1..<16 {
            switch index {
            case 1: try bindInt(index: index, value: record.seq)
            case 14: try bindInt(index: index, value: record.page)
            case 15: try bindInt(index: index, value: record.numb)
            default: try bindText(index: index, value: fields[index])
            }
        }
        guard try step() == SQLITE_DONE else {
            throw DataError.database("保存が完了しませんでした。")
        }
    }

    func importRecords(_ records: [Words], replacing: Bool) throws -> [Words] {
        guard !records.isEmpty else { throw DataError.invalid("取り込むデータがありません。") }
        for record in records { try record.validate() }
        try initial()
        return try transaction {
            if replacing { try exec("DELETE FROM watchEword") }
            for record in records { try insert(record) }
            return try selectAll()
        }
    }

    func selectAll() throws -> [Words] {
        defer { finalizeStatement() }
        try prepare("SELECT id,seq,word,type,mean,expr,simlr,invrt,relat,eibun,wabun,descr,book,stage,page,numb FROM watchEword ORDER BY book,stage,page,numb,word,seq,id")
        var result: [Words] = []
        while try step() == SQLITE_ROW {
            var record = Words()
            record.id = columnInt(index: 0); record.seq = columnInt(index: 1)
            record.word = columnText(index: 2); record.type = columnText(index: 3)
            record.mean = columnText(index: 4); record.expr = columnText(index: 5)
            record.simlr = columnText(index: 6); record.invrt = columnText(index: 7)
            record.relat = columnText(index: 8); record.eibun = columnText(index: 9)
            record.wabun = columnText(index: 10); record.descr = columnText(index: 11)
            record.book = columnText(index: 12); record.stage = columnText(index: 13)
            record.page = columnInt(index: 14); record.numb = columnInt(index: 15)
            result.append(record)
        }
        return result
    }
}
