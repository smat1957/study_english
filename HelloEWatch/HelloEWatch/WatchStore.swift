import SwiftUI
import WatchConnectivity
import UniformTypeIdentifiers

enum ImportFormat: String, CaseIterable, Identifiable {
    case json = "JSON", csv = "CSV"
    var id: String { rawValue }
    var contentTypes: [UTType] {
        self == .json ? [.json, .plainText] : [.commaSeparatedText, .plainText]
    }
}

enum SearchScope: String, CaseIterable, Identifiable {
    case all = "全て", book = "本で", stage = "章で", page = "頁で"
    var id: String { rawValue }
}

/// Published state and WCSession operations are handled on the main queue.
/// File parsing and all SQLite access use one serial worker queue.
final class WatchStore: NSObject, ObservableObject, WCSessionDelegate {
    @Published private(set) var records: [Words] = []
    @Published private(set) var matches: [Words] = []
    @Published private(set) var books: [String] = []
    @Published private(set) var stages: [String] = []
    @Published private(set) var pages: [Int] = []
    @Published private(set) var busy = true
    @Published private(set) var loaded = false
    @Published private(set) var current = 0
    @Published private(set) var connectionStatus = "Watch接続を準備しています"
    @Published private(set) var importStatus = ""
    @Published private(set) var pendingRecords: [Words] = []
    @Published var selectedBooks: Set<String> = []
    @Published var showImportReview = false
    @Published var errorMessage: String?
    @Published var selectedBook = ""
    @Published var selectedStage = ""
    @Published var selectedPage = 0
    @Published var scope: SearchScope = .all

    private let dao = DAO()
    private let worker = DispatchQueue(label: "jp.matoike.HelloEWatch.database", qos: .userInitiated)
    private var revision = UUID().uuidString
    private let timestampKey = "WatchEWord.lastSnapshotTimestamp.v1"
    private var lastTimestamp = 0.0
    private var latestSnapshot: Data?
    private var pushID: UUID?
    private let requestSerialsKey = "WatchEWord.clientRequestSerials.v1"
    private var lastRequestSerials: [String: Int] = [:]
    private var wcSession: WCSession? {
        WCSession.isSupported() ? WCSession.default : nil
    }

    override init() {
        super.init()
        let savedTimestamp = UserDefaults.standard.double(forKey: timestampKey)
        lastTimestamp = savedTimestamp.isFinite ? savedTimestamp : 0
        lastRequestSerials = (UserDefaults.standard.dictionary(forKey: requestSerialsKey) ?? [:])
            .compactMapValues { $0 as? Int }
        if let session = wcSession {
            session.delegate = self
            session.activate()
        } else {
            connectionStatus = "この端末はWatch通信に対応していません"
        }
        load()
    }

    func load() {
        guard !loaded else { return }
        busy = true
        worker.async {
            do {
                try self.dao.initial()
                let records = try self.dao.selectAll()
                DispatchQueue.main.async {
                    self.records = records
                    self.loaded = true
                    self.busy = false
                    self.refreshChoices()
                    self.search()
                }
            } catch {
                DispatchQueue.main.async {
                    self.busy = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func refreshChoices() {
        books = Array(Set(records.map(\.book))).sorted()
        if !books.contains(selectedBook) { selectedBook = books.first ?? "" }
        stages = Array(Set(records.filter { $0.book == selectedBook }.map(\.stage))).sorted()
        if !stages.contains(selectedStage) { selectedStage = stages.first ?? "" }
        // Page search retains the original book + page scope, independent of stage.
        pages = Array(Set(records.filter { $0.book == selectedBook }.map(\.page))).sorted()
        if !pages.contains(selectedPage) { selectedPage = pages.first ?? 0 }
    }

    func chooseBook(_ book: String) {
        selectedBook = book
        refreshChoices()
        scope = .book
        search()
    }

    func search() {
        guard !busy, loaded else { return }
        matches = records.filter { record in
            switch scope {
            case .all: return true
            case .book: return record.book == selectedBook
            case .stage: return record.book == selectedBook && record.stage == selectedStage
            case .page: return record.book == selectedBook && record.page == selectedPage
            }
        }
        current = 0
        revision = UUID().uuidString
        publishSnapshot()
    }

    func readImport(_ url: URL, format: ImportFormat) {
        guard !busy else { return }
        busy = true
        // Acquire scope before the file-importer callback returns.
        let accessed = url.startAccessingSecurityScopedResource()
        worker.async {
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }
            do {
                let records: [Words]
                if format == .json {
                    records = try JSONRW().parse(Data(contentsOf: url))
                } else {
                    records = try myCSV().parse(String(contentsOf: url, encoding: .utf8))
                }
                DispatchQueue.main.async {
                    self.pendingRecords = records
                    self.selectedBooks = Set(records.map(\.book))
                    self.busy = false
                    self.showImportReview = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.busy = false
                    self.errorMessage = "取り込めませんでした。既存データは変更していません。\n" + error.localizedDescription
                }
            }
        }
    }

    var pendingBooks: [String] { Array(Set(pendingRecords.map(\.book))).sorted() }
    var selectedImportCount: Int { pendingRecords.filter { selectedBooks.contains($0.book) }.count }

    func cancelImport() {
        guard !busy else { return }
        pendingRecords = []
        selectedBooks = []
        showImportReview = false
    }

    func commitImport(replacing: Bool) {
        guard !busy else { return }
        let selected = pendingRecords.filter { selectedBooks.contains($0.book) }
        guard !selected.isEmpty else { return }
        busy = true
        worker.async {
            do {
                let records = try self.dao.importRecords(selected, replacing: replacing)
                DispatchQueue.main.async {
                    self.records = records
                    self.loaded = true
                    self.busy = false
                    self.scope = .all
                    self.refreshChoices()
                    self.search()
                    self.importStatus = "\(selected.count)件を\(replacing ? "置き換えて" : "追記して")取り込みました"
                    self.cancelImport()
                }
            } catch {
                DispatchQueue.main.async {
                    self.busy = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func makeSnapshot() -> Data? {
        let record = matches.indices.contains(current) ? matches[current] : nil
        let entry = record.map {
            WatchWord(word: $0.word, mean: $0.mean, type: $0.type,
                      book: $0.book, stage: $0.stage, page: $0.page)
        }
        lastTimestamp = max(Date().timeIntervalSince1970, lastTimestamp + 0.001)
        UserDefaults.standard.set(lastTimestamp, forKey: timestampKey)
        return try? JSONEncoder().encode(WatchSnapshot(protocolVersion: 1, revision: revision,
            updatedAt: lastTimestamp, current: current, count: matches.count, entry: entry))
    }

    private func publishSnapshot() {
        guard loaded, let data = makeSnapshot() else { return }
        // A newer search/navigation invalidates an older send's status callback.
        pushID = nil
        latestSnapshot = data
        guard let session = wcSession, session.activationState == .activated else { return }
        do {
            // Retain the latest display for background delivery/reconnection.
            try session.updateApplicationContext(["snapshot": data])
            updateConnectionStatus()
        } catch {
            connectionStatus = "Watchへの同期に失敗しました: \(error.localizedDescription)"
        }
    }

    func sendToWatch() {
        guard !busy, loaded else { return }
        current = 0
        revision = UUID().uuidString
        publishSnapshot()
        guard let session = wcSession, session.activationState == .activated,
              session.isReachable, let data = latestSnapshot else {
            connectionStatus = "Watch接続待ちです。最新の表示は再接続時に同期します"
            return
        }
        let identifier = UUID()
        pushID = identifier
        connectionStatus = "Watchに送信しています"
        session.sendMessage(["snapshot": data], replyHandler: { reply in
            let accepted = reply["accepted"] as? Bool == true
            DispatchQueue.main.async {
                guard self.pushID == identifier else { return }
                self.pushID = nil
                self.connectionStatus = accepted ? "Watchに送信しました" : "Watchがデータを受け取れませんでした"
            }
        }, errorHandler: { error in
            DispatchQueue.main.async {
                guard self.pushID == identifier else { return }
                self.pushID = nil
                self.connectionStatus = "Watchへの送信に失敗しました: \(error.localizedDescription)"
            }
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            guard self.pushID == identifier else { return }
            self.pushID = nil
            self.connectionStatus = "Watchの応答がありません。送信ボタンで再試行してください"
        }
    }

    private func updateConnectionStatus() {
        guard let session = wcSession else { return }
        if session.activationState != .activated {
            connectionStatus = "Watch接続を準備しています"
        } else if !session.isPaired {
            connectionStatus = "Apple Watchがペアリングされていません"
        } else if !session.isWatchAppInstalled {
            connectionStatus = "Watchにアプリをインストールしてください"
        } else {
            connectionStatus = session.isReachable ? "Watchと通信できます" : "Watch接続待ちです"
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            if let error = error { self.connectionStatus = error.localizedDescription }
            else { self.updateConnectionStatus(); self.publishSnapshot() }
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { self.updateConnectionStatus(); self.publishSnapshot() }
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        DispatchQueue.main.async { self.updateConnectionStatus(); self.publishSnapshot() }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async { self.updateConnectionStatus() }
    }

    func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async { session.activate() }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any],
                 replyHandler: @escaping ([String: Any]) -> Void) {
        DispatchQueue.main.async {
            guard self.loaded, !self.busy else {
                replyHandler(["error": "iPhoneでデータを準備中です。もう一度お試しください。"])
                return
            }
            guard let version = message["protocolVersion"] as? Int, version == 1,
                  let command = message["command"] as? String,
                  let clientID = message["clientID"] as? String, UUID(uuidString: clientID) != nil,
                  let serial = message["requestSerial"] as? Int, serial > 0,
                  command == "refresh" || command == "move" else {
                replyHandler(["error": "通信形式が異なります。両方のアプリを更新してください。"])
                return
            }
            let isNewRequest = serial > (self.lastRequestSerials[clientID] ?? 0)
            if command == "move" {
                guard let target = message["target"] as? Int,
                      let revision = message["revision"] as? String else {
                    replyHandler(["error": "移動先のデータが不正です。"])
                    return
                }
                // A request from an old search gets the new search's current display.
                if isNewRequest, revision == self.revision, self.matches.indices.contains(target) {
                    self.current = target
                }
            }
            // Do not let a delayed/repeated command undo a newer navigation request.
            if isNewRequest {
                self.lastRequestSerials[clientID] = serial
                UserDefaults.standard.set(self.lastRequestSerials, forKey: self.requestSerialsKey)
            }
            self.publishSnapshot()
            if let data = self.latestSnapshot { replyHandler(["snapshot": data]) }
            else { replyHandler(["error": "送信データを作成できませんでした。"] ) }
        }
    }
}
