import Foundation
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: WatchStore
    @State private var format: ImportFormat = .json
    @State private var showFormat = false
    @State private var importing = false
    @State private var chooseFileAfterDismiss = false

    var body: some View {
        NavigationStack {
            Form {
                Section("単語データ") {
                    Text("保存済み \(store.records.count)件 ／ 検索結果 \(store.matches.count)件")
                    Button { showFormat = true } label: {
                        Label("HelloEWordのデータをインポート", systemImage: "square.and.arrow.down")
                    }.disabled(store.busy || !store.loaded)
                    if !store.importStatus.isEmpty {
                        Text(store.importStatus).font(.footnote).foregroundStyle(.secondary)
                    }
                    if store.busy { ProgressView("データを処理しています…") }
                    else if !store.loaded {
                        Button("データベースを再読み込み") { store.load() }
                    } else if store.records.isEmpty {
                        Text("HelloEWordでエクスポートしたJSONまたはCSVを取り込んでください。")
                            .foregroundStyle(.secondary)
                    }
                }
                if !store.records.isEmpty {
                    Section("検索") {
                        Picker("対象", selection: Binding(get: { store.scope }, set: {
                            store.scope = $0; store.search()
                        })) {
                            ForEach(SearchScope.allCases) { Text($0.rawValue).tag($0) }
                        }
                        Picker("本", selection: Binding(get: { store.selectedBook }, set: {
                            store.chooseBook($0)
                        })) {
                            ForEach(store.books, id: \.self) {
                                Text($0.isEmpty ? "（本の名前なし）" : $0).tag($0)
                            }
                        }
                        if !store.stages.isEmpty {
                            Picker("章", selection: Binding(get: { store.selectedStage }, set: {
                                store.selectedStage = $0; store.scope = .stage; store.search()
                            })) {
                                ForEach(store.stages, id: \.self) {
                                    Text($0.isEmpty ? "（章なし）" : $0).tag($0)
                                }
                            }
                        }
                        if !store.pages.isEmpty {
                            Picker("頁", selection: Binding(get: { store.selectedPage }, set: {
                                store.selectedPage = $0; store.scope = .page; store.search()
                            })) {
                                ForEach(store.pages, id: \.self) { Text(String($0)).tag($0) }
                            }
                        }
                        Button("検索") { store.search() }
                    }.disabled(store.busy)
                }
                Section("Apple Watch") {
                    Text(store.connectionStatus).font(.footnote)
                    Button { store.sendToWatch() } label: {
                        Label("検索結果をWatchに送る", systemImage: "applewatch.and.arrow.forward")
                    }.disabled(store.busy || !store.loaded)
                    if store.matches.indices.contains(store.current) {
                        Text("\(store.current + 1) / \(store.matches.count)").foregroundStyle(.secondary)
                        Text(store.matches[store.current].word).font(.title2.bold())
                        Text(store.matches[store.current].mean)
                    } else if store.loaded && !store.busy {
                        Text("表示する単語がありません。検索条件を変更するか、データを取り込んでください。")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("WatchEWord")
            .sheet(isPresented: $showFormat, onDismiss: {
                if chooseFileAfterDismiss { chooseFileAfterDismiss = false; importing = true }
            }) {
                NavigationStack {
                    Form {
                        Picker("ファイル形式", selection: $format) {
                            ForEach(ImportFormat.allCases) { Text($0.rawValue).tag($0) }
                        }
                        Text("HelloEWordの全項目JSON・従来JSON・出題用JSON、または16列CSVを読み込めます。")
                        Button("ファイルを選択") {
                            chooseFileAfterDismiss = true; showFormat = false
                        }
                    }
                    .navigationTitle("インポート")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("キャンセル") { showFormat = false }
                        }
                    }
                }.presentationDetents([.medium])
            }
            .fileImporter(isPresented: $importing, allowedContentTypes: format.contentTypes) { result in
                switch result {
                case .success(let url): store.readImport(url, format: format)
                case .failure(let error):
                    let nsError = error as NSError
                    if nsError.domain != NSCocoaErrorDomain || nsError.code != NSUserCancelledError {
                        store.errorMessage = error.localizedDescription
                    }
                }
            }
            .sheet(isPresented: $store.showImportReview, onDismiss: { store.cancelImport() }) {
                ImportReview().environmentObject(store)
            }
            .alert("処理できませんでした", isPresented: Binding(
                get: { store.errorMessage != nil && !store.showImportReview },
                set: { if !$0 && !store.showImportReview { store.errorMessage = nil } }
            )) {
                Button("閉じる", role: .cancel) { store.errorMessage = nil }
            } message: { Text(store.errorMessage ?? "") }
        }
        .tint(Color(red: 30.0 / 255, green: 150.0 / 255, blue: 234.0 / 255))
    }

}

private struct ImportReview: View {
    @EnvironmentObject private var store: WatchStore
    @State private var replacing = false
    @State private var confirmReplacement = false

    var body: some View {
        NavigationStack {
            Form {
                Section("取り込む本") {
                    ForEach(store.pendingBooks, id: \.self) { book in
                        Toggle(isOn: Binding(get: { store.selectedBooks.contains(book) }, set: { selected in
                            if selected { store.selectedBooks.insert(book) }
                            else { store.selectedBooks.remove(book) }
                        })) {
                            Text("\(book.isEmpty ? "（本の名前なし）" : book)（\(store.pendingRecords.filter { $0.book == book }.count)件）")
                        }
                    }
                }
                Section("保存方法") {
                    Picker("方法", selection: $replacing) {
                        Text("追記").tag(false)
                        Text("全データを置き換え").tag(true)
                    }
                    Text(replacing
                        ? "保存済みの全\(store.records.count)件を削除し、選択した本の\(store.selectedImportCount)件に置き換えます。"
                        : "選択した\(store.selectedImportCount)件を追加します。同じデータを再度取り込むと重複します。")
                    if store.busy { ProgressView("保存しています…") }
                }
            }
            .disabled(store.busy)
            .navigationTitle("取り込み内容の確認")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { store.cancelImport() }.disabled(store.busy)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("取り込む") {
                        if replacing { confirmReplacement = true }
                        else { store.commitImport(replacing: false) }
                    }.disabled(store.busy || store.selectedImportCount == 0)
                }
            }
            .confirmationDialog("保存済みの全\(store.records.count)件を置き換えますか？",
                                isPresented: $confirmReplacement, titleVisibility: .visible) {
                Button("全データを置き換える", role: .destructive) { store.commitImport(replacing: true) }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("選択していない本の既存データも削除されます。選択した\(store.selectedImportCount)件を保存します。")
            }
            .interactiveDismissDisabled(store.busy)
            .alert("取り込めませんでした", isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.errorMessage = nil } }
            )) {
                Button("閉じる", role: .cancel) { store.errorMessage = nil }
            } message: { Text(store.errorMessage ?? "") }
        }
    }
}

#Preview { ContentView().environmentObject(WatchStore()) }
