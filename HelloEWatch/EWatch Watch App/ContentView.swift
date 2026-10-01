import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var connector: PhoneConnector
    @Environment(\.scenePhase) private var scenePhase
    @State private var showMeaning = false

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if let snapshot = connector.snapshot, let entry = snapshot.entry {
                    Text(entry.book.isEmpty ? "（本の名前なし）" : entry.book)
                        .font(.caption).foregroundStyle(.secondary)
                    Text("\(snapshot.current + 1) / \(snapshot.count)　章\(entry.stage)　頁\(entry.page)")
                        .font(.caption2).foregroundStyle(.secondary)
                    Button { showMeaning.toggle() } label: {
                        VStack(spacing: 4) {
                            Text(entry.word).font(.title3.bold()).multilineTextAlignment(.center)
                            if !entry.type.isEmpty {
                                Text(entry.type).font(.caption2).foregroundStyle(.secondary)
                            }
                        }.frame(maxWidth: .infinity)
                    }.buttonStyle(.plain)
                    if showMeaning {
                        Text(entry.mean).multilineTextAlignment(.center)
                    } else {
                        Text("単語をタップして意味を表示").font(.caption2).foregroundStyle(.secondary)
                    }
                } else {
                    Text("単語がありません").font(.headline)
                    Text("iPhoneのWatchEWordで単語データを取り込んでください。")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if connector.waiting { ProgressView() }
                if !connector.status.isEmpty {
                    Text(connector.status).font(.caption2).foregroundStyle(.secondary)
                }
                Button { connector.refresh() } label: {
                    Label("更新", systemImage: "arrow.clockwise")
                }.disabled(connector.waiting)
            }.padding(.horizontal, 4)
        }
        .simultaneousGesture(DragGesture(minimumDistance: 30).onEnded { gesture in
            guard abs(gesture.translation.width) > abs(gesture.translation.height),
                  connector.isConnected, !connector.waiting else { return }
            connector.move(gesture.translation.width > 0 ? -1 : 1)
        })
        .onChange(of: connector.snapshot?.current) { showMeaning = false }
        .onChange(of: connector.snapshot?.revision) { showMeaning = false }
        .onChange(of: scenePhase) {
            if scenePhase == .active { connector.refresh() }
        }
        .onAppear { connector.refresh() }
    }
}

#Preview { ContentView().environmentObject(PhoneConnector()) }
