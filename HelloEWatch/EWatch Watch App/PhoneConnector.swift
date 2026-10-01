import SwiftUI
import WatchConnectivity

/// UI updates and request bookkeeping are confined to the main queue.
final class PhoneConnector: NSObject, ObservableObject, WCSessionDelegate {
    @Published private(set) var snapshot: WatchSnapshot?
    @Published private(set) var isConnected = false
    @Published private(set) var waiting = false
    @Published private(set) var status = "iPhone接続を準備しています"

    private let cacheKey = "WatchEWord.currentSnapshot.v1"
    private let clientKey = "WatchEWord.clientID.v1"
    private let serialKey = "WatchEWord.requestSerial.v1"
    private var clientID = ""
    private var requestSerial = 0
    private var pendingID: UUID?
    private var wcSession: WCSession? {
        WCSession.isSupported() ? WCSession.default : nil
    }

    override init() {
        super.init()
        clientID = UserDefaults.standard.string(forKey: clientKey) ?? UUID().uuidString
        UserDefaults.standard.set(clientID, forKey: clientKey)
        requestSerial = max(0, UserDefaults.standard.integer(forKey: serialKey))
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let saved = try? JSONDecoder().decode(WatchSnapshot.self, from: data), saved.isValid {
            snapshot = saved
        }
        if let session = wcSession {
            session.delegate = self
            session.activate()
        } else {
            status = "この端末はiPhone通信に対応していません"
        }
    }

    @discardableResult
    private func apply(_ data: Data) -> Bool {
        guard let incoming = try? JSONDecoder().decode(WatchSnapshot.self, from: data),
              incoming.isValid else { return false }
        // Context delivery and replies can arrive in either order.
        if let snapshot = snapshot, incoming.updatedAt < snapshot.updatedAt { return true }
        snapshot = incoming
        UserDefaults.standard.set(data, forKey: cacheKey)
        return true
    }

    func refresh() { request(command: "refresh") }

    func move(_ offset: Int) {
        guard let snapshot = snapshot, offset == -1 || offset == 1 else { return }
        let target = snapshot.current + offset
        guard target >= 0, target < snapshot.count else { return }
        request(command: "move", target: target, revision: snapshot.revision)
    }

    private func request(command: String, target: Int? = nil, revision: String? = nil) {
        guard !waiting else { return }
        guard let session = wcSession, session.activationState == .activated, session.isReachable else {
            isConnected = false
            status = snapshot == nil ? "iPhoneのWatchEWordを開いてください" : "iPhoneに接続できません。直前の単語を表示しています"
            return
        }
        let identifier = UUID()
        guard requestSerial < Int.max else {
            status = "通信番号を更新できません。Watchアプリを再インストールしてください"
            return
        }
        requestSerial += 1
        UserDefaults.standard.set(requestSerial, forKey: serialKey)
        isConnected = true
        pendingID = identifier
        waiting = true
        status = "iPhoneと通信しています…"
        var message: [String: Any] = ["protocolVersion": 1, "command": command,
                                     "clientID": clientID, "requestSerial": requestSerial]
        if let target = target { message["target"] = target }
        if let revision = revision { message["revision"] = revision }
        session.sendMessage(message, replyHandler: { reply in
            DispatchQueue.main.async {
                guard self.pendingID == identifier else { return }
                self.finishRequest()
                if let error = reply["error"] as? String {
                    self.status = error
                } else if let data = reply["snapshot"] as? Data, self.apply(data) {
                    self.status = self.snapshot?.count == 0 ? "iPhoneでデータを取り込むか検索条件を変更してください" : ""
                } else {
                    self.status = "受信データが不正です。両方のアプリを更新してください"
                }
            }
        }, errorHandler: { error in
            DispatchQueue.main.async {
                guard self.pendingID == identifier else { return }
                self.finishRequest()
                self.status = "通信に失敗しました。更新ボタンで再試行してください。\n\(error.localizedDescription)"
            }
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            guard self.pendingID == identifier else { return }
            self.finishRequest()
            self.status = "iPhoneの応答がありません。更新ボタンで再試行してください"
        }
    }

    private func finishRequest() {
        pendingID = nil
        waiting = false
    }

    private func updateConnection() {
        guard let session = wcSession else { return }
        isConnected = session.activationState == .activated && session.isReachable
        if !isConnected {
            finishRequest()
            status = snapshot == nil ? "iPhoneのWatchEWordを開いてください" : "未接続：直前の単語を表示しています"
        } else if !waiting {
            status = ""
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.updateConnection()
            if let data = session.receivedApplicationContext["snapshot"] as? Data {
                if !self.apply(data) { self.status = "受信データが不正です" }
            }
            if let error = error { self.status = error.localizedDescription }
            else if self.isConnected { self.refresh() }
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.updateConnection()
            if self.isConnected { self.refresh() }
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async {
            guard let data = applicationContext["snapshot"] as? Data, self.apply(data) else {
                self.status = "受信データが不正です。両方のアプリを更新してください"
                return
            }
            self.updateConnection()
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any],
                 replyHandler: @escaping ([String: Any]) -> Void) {
        DispatchQueue.main.async {
            guard let data = message["snapshot"] as? Data else {
                replyHandler(["accepted": false])
                return
            }
            let accepted = self.apply(data)
            if accepted { self.updateConnection() }
            else { self.status = "受信データが不正です" }
            replyHandler(["accepted": accepted])
        }
    }
}
