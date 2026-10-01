import Foundation
import SQLite3

enum DataError: LocalizedError {
    case invalid(String)
    case database(String)

    var errorDescription: String? {
        switch self {
        case .invalid(let message), .database(let message): return message
        }
    }
}

/// One connection and at most one active statement. Call from the owning UI thread.
class SQLite3 {
    private var db: OpaquePointer?
    private var statement: OpaquePointer?

    deinit {
        finalizeStatement()
        if let db = db { sqlite3_close_v2(db) }
    }

    private func failure(_ operation: String) -> DataError {
        let message = db.map { String(cString: sqlite3_errmsg($0)) } ?? "DBが開かれていません。"
        return .database("\(operation): \(message)")
    }

    func open(path: String) throws {
        if db != nil { return }
        let result = sqlite3_open_v2(path, &db,
            SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX, nil)
        guard result == SQLITE_OK else {
            let error = failure("DBを開けません")
            if let db = db { sqlite3_close_v2(db) }
            db = nil
            throw error
        }
        sqlite3_busy_timeout(db, 5000)
    }

    func exec(_ sql: String) throws {
        guard db != nil else { throw failure("SQL実行") }
        guard sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK else {
            throw failure("SQL実行")
        }
    }

    func prepare(_ sql: String) throws {
        finalizeStatement()
        guard db != nil else { throw failure("SQL準備") }
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw failure("SQL準備")
        }
    }

    func bindInt(index: Int, value: Int) throws {
        guard sqlite3_bind_int64(statement, Int32(index), Int64(value)) == SQLITE_OK else {
            throw failure("数値の設定")
        }
    }

    func bindText(index: Int, value: String) throws {
        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        let result = value.withCString {
            sqlite3_bind_text(statement, Int32(index), $0, -1, transient)
        }
        guard result == SQLITE_OK else { throw failure("文字列の設定") }
    }

    func step() throws -> Int32 {
        let result = sqlite3_step(statement)
        guard result == SQLITE_ROW || result == SQLITE_DONE else {
            throw failure("SQL実行")
        }
        return result
    }

    func finalizeStatement() {
        if let statement = statement { sqlite3_finalize(statement) }
        statement = nil
    }

    func columnInt(index: Int) -> Int {
        Int(sqlite3_column_int64(statement, Int32(index)))
    }

    func columnText(index: Int) -> String {
        guard let text = sqlite3_column_text(statement, Int32(index)) else { return "" }
        let count = Int(sqlite3_column_bytes(statement, Int32(index)))
        return String(decoding: UnsafeBufferPointer(start: text, count: count), as: UTF8.self)
    }

    func lastInsertedID() -> Int { Int(sqlite3_last_insert_rowid(db)) }
    func changedRows() -> Int { Int(sqlite3_changes(db)) }

    func transaction<T>(_ operation: () throws -> T) throws -> T {
        try exec("BEGIN IMMEDIATE TRANSACTION")
        do {
            let result = try operation()
            try exec("COMMIT")
            return result
        } catch {
            finalizeStatement()
            do { try exec("ROLLBACK") }
            catch { throw DataError.database("取り込みの取消に失敗しました: \(error.localizedDescription)") }
            throw error
        }
    }
}
