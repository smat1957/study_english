//
//  ContentView.swift
//  HelloECompo
//
//  Created by 的池秋成 on 2024/10/15.
//
import Foundation
import SwiftUI
import UniformTypeIdentifiers

extension String {
    var length: Int {
        return count
    }

    subscript (i: Int) -> String {
        return self[i ..< i + 1]
    }

    func substring(fromIndex: Int) -> String {
        return self[min(fromIndex, length) ..< length]
    }

    func substring(toIndex: Int) -> String {
        return self[0 ..< max(0, toIndex)]
    }

    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }

}

extension UIApplication {
    func closeKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct ContentView: View {
    @State private var dao = DAO()
    @State private var records: [Record] = []
    @State private var initialized = false
    @State private var editorSession: RecordEditorSession?
    @State private var screenError: String?
    @State private var swipeForward = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let csv = CSV(fname: "ECompoData")
    let myjson = JSONRW()
    
    enum Field: Hashable {
        // https://dev.classmethod.jp/articles/focusstate-keyboard/
        case line
        case page
        case wabun
        case eibun
        case hint
    }
    @FocusState private var focusedField: Field?
    
    @State private var id : Int = 0
    @State private var line: String = "0"
    @State private var page: String = "0"
    @State private var chap: String = "0"
    @State private var field: String = ""
    @State private var topic: String = ""
    @State private var title: String = ""
    @State private var wabun: String = ""
    @State private var eibun: String = ""
    @State private var hint: String = ""
    @State private var description: String = ""
    @State private var isWabun: Bool = true
    @State private var isEibun: Bool = false
    @State private var isHint: Bool = false
    @State private var book: String = ""
    @State private var selectedBook: String = "準1級：完全制覇"
    @State private var selectedField: String = ""
    @State private var selectedTopic: String = ""
    @State private var selectedTitle: String = ""
    @State private var selectedSearch: String = "全"
    @State private var current = 0
    @State private var sizeofRecords = 0
    @State private var new_save: String = "New"
    @State private var isSave: Bool = false
    @State private var edit_update: String = "Edit"
    @State private var isUpdate: Bool = false
    @State private var isDelete: Bool = false
    @State private var exportFile: Bool = false
    @State private var importFile: Bool = false
    @State private var transferSession: DataTransferSession?
    @State private var importBookSession: ImportBookSession?
    @State private var pendingImportConfirmation = false
    @State private var transferFormat: DataTransferFormat = .json
    @State private var pendingTransfer: DataTransferDirection?
    @State private var isDisableBook: Bool = false
    @State private var isDisableField: Bool = false
    @State private var isDisableTopic: Bool = false
    @State private var isDisableTitle: Bool = false
    @State private var altHint: Bool = false
    @State private var altEibun: Bool = false
    @State private var altWabun: Bool = false
    @State private var altTitle: Bool = false
    @State private var altTopic: Bool = false
    @State private var altField: Bool = false
    @State private var altBook: Bool = false

    @State private var text: String = ""
    @State private var stringData: String = ""
    @State private var csvData: [[String]] = []
    //@State private var Books = ["1級完全制覇", "1級文単", "準1級完全制覇", "準1級文単", "入試問題精講"]
    @State private var Books = [""]
    @State private var Titles = [""]
    @State private var Topics = [""]
    @State private var Fields = [""]

    /// Errors leave the draft intact; successful writes end editing before refreshing.
    func report(_ error: Error) {
        print("処理エラー: \(error.localizedDescription)")
        screenError = error.localizedDescription
    }

    func perform(_ operation: () throws -> Void) {
        do { try operation() }
        catch { report(error) }
    }

    private var browsingStateKey: String { "HelloECompo.browsingState.v1" }

    func saveBrowsingState() {
        guard initialized else { return }
        let state = SavedBrowsingState(scope: selectedSearch, book: selectedBook,
            field: selectedField, topic: selectedTopic, title: selectedTitle,
            page: page, recordID: id, index: current)
        do {
            UserDefaults.standard.set(try JSONEncoder().encode(state), forKey: browsingStateKey)
        } catch {
            print("閲覧状態の保存エラー: \(error.localizedDescription)")
        }
    }

    func initialize() {
        guard !initialized else { return }
        perform {
            try dao.initial()
            let saved = UserDefaults.standard.data(forKey: browsingStateKey)
                .flatMap { try? JSONDecoder().decode(SavedBrowsingState.self, from: $0) }
            if let saved = saved, ["全", "本", "分野", "話題", "題目", "頁"].contains(saved.scope) {
                selectedSearch = saved.scope
                selectedBook = saved.book
                selectedField = saved.field
                selectedTopic = saved.topic
                selectedTitle = saved.title
                page = saved.page
                let restored = try searchResults()
                if restored.isEmpty {
                    // A removed book/filter cannot be restored; return to available records.
                    selectedSearch = "全"
                    try display(dao.select_all())
                } else {
                    try display(restored, preferredID: saved.recordID, index: saved.index)
                }
            } else {
                try display(dao.select_all())
            }
            initialized = true
            saveBrowsingState()
        }
    }

    func clear_fields() {
        id = 0
        line = "0"; page = "0"; chap = "0"
        field = ""; topic = ""; title = ""
        wabun = ""; eibun = ""; hint = ""; description = ""
        book = selectedBook
    }

    /// Gather everything first, so a failed query cannot leave a partially refreshed screen.
    func display(_ result: [Record], preferredID: Int? = nil, index: Int = 0) throws {
        let position = result.isEmpty ? 0 : min(max(index, 0), result.count - 1)
        let selectedIndex = preferredID.flatMap { wanted in result.firstIndex { $0.id == wanted } } ?? position
        let record = result.isEmpty ? nil : result[selectedIndex]
        let books = try dao.distinct(field_name: "book")
        let nextBook = record?.book ?? (books.contains(selectedBook) ? selectedBook : books.first ?? "")
        let fields = try dao.distinct(field_name: "field", book: nextBook)
        let nextField = record?.field ?? (fields.contains(selectedField) ? selectedField : fields.first ?? "")
        let topics = try dao.distinct(field_name: "topic", book: nextBook, field: nextField)
        let nextTopic = record?.topic ?? (topics.contains(selectedTopic) ? selectedTopic : topics.first ?? "")
        let titles = try dao.distinct(field_name: "title", book: nextBook, field: nextField, topic: nextTopic)
        // Persist only after all queries succeeded, and after every displayed value is updated.
        defer { saveBrowsingState() }
        records = result
        current = selectedIndex
        sizeofRecords = result.count
        Books = books.isEmpty ? [""] : books
        Titles = titles.isEmpty ? [""] : titles
        Topics = topics.isEmpty ? [""] : topics
        Fields = fields.isEmpty ? [""] : fields
        selectedBook = nextBook
        guard let record = record else {
            clear_fields()
            selectedField = nextField
            selectedTopic = nextTopic
            selectedTitle = titles.first ?? ""
            return
        }
        id = record.id
        eibun = record.eibun; wabun = record.wabun; hint = record.hint
        line = String(record.line); page = String(record.page); chap = String(record.chap)
        title = record.title; topic = record.topic; field = record.field
        book = record.book; selectedBook = record.book
        selectedField = field; selectedTopic = topic; selectedTitle = title
        description = record.description
    }

    func show_current(current: Int) {
        perform { try display(records, index: current) }
    }

    func swipeArticle(forward: Bool) {
        let nextIndex = current + (forward ? 1 : -1)
        guard records.indices.contains(nextIndex) else { return }
        swipeForward = forward
        withAnimation(.easeInOut(duration: reduceMotion ? 0.15 : 0.25)) {
            // display validates and loads all data before updating the current article.
            do { try display(records, index: nextIndex) }
            catch { report(error) }
        }
    }

    func setData() throws -> Record {
        try Record(data: [String(id), eibun, wabun, hint, line, page, chap,
                          title, topic, field, book, description])
    }

    func beginEditor(isNew: Bool) {
        perform {
            let record: Record
            if isNew {
                record = try Record(data: ["0", "", "", "", "0", page, chap,
                                           selectedTitle, selectedTopic, selectedField, selectedBook, ""])
            } else {
                guard records.indices.contains(current) else {
                    throw DataError.invalid("編集するデータがありません。")
                }
                record = records[current]
            }
            focusedField = nil
            UIApplication.shared.closeKeyboard()
            editorSession = RecordEditorSession(record: record, isNew: isNew)
        }
    }

    func saveEditor(_ record: Record, isNew: Bool) throws {
        let savedID: Int
        if isNew {
            savedID = try dao.insert(record)
        } else {
            try dao.update(record, id: record.id)
            savedID = record.id
        }
        finishEditing()
        // The write has completed. A refresh failure must not cause a second insert on retry.
        do { try display(searchResults(), preferredID: savedID, index: current) }
        catch {
            screenError = "保存は完了しましたが、画面の再読込に失敗しました。本または分類を選び直してください。\n" + error.localizedDescription
        }
    }

    func finishEditing() {
        edit_update = "Edit"
        new_save = "New"
        isUpdate = false
        isSave = false
        isDelete = false
        focusedField = nil
    }

    func okActionUpdate() {
        perform {
            let savedID = id
            let previousIndex = current
            try dao.update(setData(), id: savedID)
            finishEditing()
            try display(searchResults(), preferredID: savedID, index: previousIndex)
        }
    }

    func okActionSave() {
        perform {
            let previousIndex = current
            let savedID = try dao.insert(setData())
            finishEditing()
            try display(searchResults(), preferredID: savedID, index: previousIndex)
        }
    }

    func okActionDelete() {
        perform {
            let previousIndex = current
            try dao.delete(id: id)
            finishEditing()
            try display(searchResults(), index: previousIndex)
        }
    }

    func searchResults() throws -> [Record] {
        switch selectedSearch {
        case "全": return try dao.select_all()
        case "本": return try dao.select_book(book: selectedBook)
        case "分野": return try dao.select_book_field(book: selectedBook, field: selectedField)
        case "話題": return try dao.select_hierarchy(book: selectedBook, field: selectedField, topic: selectedTopic)
        case "題目": return try dao.select_hierarchy(book: selectedBook, field: selectedField, topic: selectedTopic, title: selectedTitle)
        case "頁":
            return try dao.select_book_page(book: selectedBook, page: Record.number(page, name: "頁"))
        default: throw DataError.invalid("検索条件が不正です。")
        }
    }

    func search() {
        perform {
            try display(searchResults())
            finishEditing()
        }
    }

    /// Only picker writes trigger a search. Updating display state does not use this binding.
    func searchSelection(_ selection: Binding<String>, scope: String? = nil) -> Binding<String> {
        Binding(
            get: { selection.wrappedValue },
            set: { value in
                let target = scope ?? value
                guard selection.wrappedValue != value || selectedSearch != target else { return }
                selection.wrappedValue = value
                selectedSearch = target
                search()
            }
        )
    }

    enum MenuConfirmation {
        case delete, importRecords, reset
    }
    @State private var menuConfirmation: MenuConfirmation = .delete
    @State private var showMenuConfirmation = false
    @State private var importedData: [Record] = []

    func processImport(replacing: Bool) {
        // Keep the imported book names before clearing the temporary input.
        let importedBooks = Set(importedData.map { $0.book })
        guard let firstBook = importedData.first?.book else {
            report(DataError.invalid("取り込むデータがありません。"))
            return
        }
        let targetBook = importedBooks.contains(selectedBook) ? selectedBook : firstBook
        do {
            try dao.importRecords(importedData, replacing: replacing)
        } catch {
            report(error)
            return
        }
        importedData = []
        finishEditing()
        do {
            // Reload choices from the committed database; replacement leaves only imported books.
            selectedSearch = "本"
            try display(dao.select_book(book: targetBook))
        } catch {
            // The import already committed; do not suggest retrying it and duplicating records.
            report(DataError.database("取り込みは完了しましたが、本の一覧の再読込に失敗しました。アプリを開き直してください。\n" + error.localizedDescription))
        }
    }

    @State var noEdit: Bool = false

    func sentenceRow(_ label: String, text: String, revealed: Binding<Bool>) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 4) {
                Text(label)
                Toggle(label, isOn: revealed)
                    .labelsHidden()
                    .scaleEffect(0.7)
            }
            .frame(width: 60)
            Text(text.isEmpty ? " " : text)
                .font(.system(size: 15))
                .foregroundColor(.primary)
                .opacity(revealed.wrappedValue ? 1 : 0)
                .accessibilityHidden(!revealed.wrappedValue)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(8)
                .background(Color(UIColor.systemGray6))
                .border(Color.gray)
        }
    }

    func requestConfirmation(_ action: MenuConfirmation) {
        menuConfirmation = action
        showMenuConfirmation = true
    }

    var confirmationTitle: String {
        switch menuConfirmation {
        case .delete: return "Delete?"
        case .importRecords: return "インポート"
        case .reset: return "アプリ内のデータを初期化しますか？"
        }
    }

    var confirmationMessage: String {
        switch menuConfirmation {
        case .delete: return "id=\(id), sentence=\(eibun)"
        case .importRecords:
            return "選択した本の\(importedData.count)件を取り込みます。追記、またはDB全体の置き換えを選んでください。「置き換え」は既存のすべての本・記事を削除し、選択した本のデータだけを保存します。"
        case .reset:
            return "すべての本・記事を削除します。この操作は取り消せません。初期化後はNewから手入力で登録できます。書き出したJSON・CSVファイルは削除しません。"
        }
    }

    func resetAppData() {
        do { try dao.clearAllRecords() }
        catch {
            report(error)
            return
        }
        // Clear the screen after the transaction commits, even if a later reload would fail.
        records = []
        current = 0
        sizeofRecords = 0
        selectedSearch = "全"
        selectedBook = ""
        selectedField = ""; selectedTopic = ""; selectedTitle = ""
        Books = [""]; Fields = [""]; Topics = [""]; Titles = [""]
        clear_fields()
        isWabun = true; isEibun = false; isHint = false
        importedData = []
        stringData = ""
        pendingTransfer = nil
        pendingImportConfirmation = false
        finishEditing()
        saveBrowsingState()
    }

    func beginTransfer(_ direction: DataTransferDirection) {
        if direction == .import {
            importedData = []
            pendingImportConfirmation = false
        }
        transferSession = DataTransferSession(direction: direction,
            context: ExportContext(scope: selectedSearch, book: selectedBook,
                                   field: selectedField, topic: selectedTopic,
                                   title: selectedTitle, page: page))
    }

    func prepareTransfer(_ direction: DataTransferDirection, format: DataTransferFormat,
                         scope: String, context: ExportContext) throws {
        if direction == .export {
            let output: [Record]
            switch scope {
            case "全": output = try dao.select_all()
            case "本": output = try dao.select_book(book: context.book)
            case "分野": output = try dao.select_book_field(book: context.book, field: context.field)
            case "話題": output = try dao.select_hierarchy(book: context.book, field: context.field, topic: context.topic)
            case "題目": output = try dao.select_hierarchy(book: context.book, field: context.field, topic: context.topic, title: context.title)
            case "頁": output = try dao.select_book_page(book: context.book,
                page: Record.number(context.page, name: "頁"))
            default: throw DataError.invalid("エクスポートの検索対象が不正です。")
            }
            // Export queries never replace the browsing records or change the current article.
            if format == .json {
                stringData = try myjson.generate(records: output)
            } else {
                stringData = csv.CSVDataGen(records: output)
            }
        }
        transferFormat = format
        pendingTransfer = direction
    }

    func presentPendingTransfer() {
        guard let direction = pendingTransfer else { return }
        pendingTransfer = nil
        // Wait until the options dialog has closed before presenting a file picker.
        if direction == .export { exportFile = true }
        else { importFile = true }
    }

    var actionMenu: some View {
        Menu {
            Section {
                Button("New", systemImage: "plus") { beginEditor(isNew: true) }
                Button("Edit", systemImage: "square.and.pencil") { beginEditor(isNew: false) }
                    .disabled(!records.indices.contains(current))
                Button(role: .destructive) {
                    requestConfirmation(.delete)
                } label: {
                    Label("Del", systemImage: "trash")
                }
                .disabled(!records.indices.contains(current))
            }
            Section {
                Button("エクスポート", systemImage: "square.and.arrow.up") {
                    beginTransfer(.export)
                }
                Button("インポート", systemImage: "square.and.arrow.down") {
                    beginTransfer(.import)
                }
            }
            Section {
                Button(role: .destructive) {
                    requestConfirmation(.reset)
                } label: {
                    Label("初期化", systemImage: "arrow.counterclockwise")
                }
            }
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 23, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(Color.accentColor, in: Circle())
                .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
        }
        .accessibilityLabel("操作メニュー")
        .fileImporter(isPresented: $importFile, allowedContentTypes: transferFormat == .json ? [.json] : [.commaSeparatedText, .plainText],
                      allowsMultipleSelection: false) { result in
            switch result {
            case .success(let files):
                guard let file = files.first else { return }
                perform {
                    let loaded: [Record]
                    if transferFormat == .json {
                        loaded = try myjson.read(url: file)
                    } else {
                        loaded = try csv.reshape(url: file)
                    }
                    importBookSession = ImportBookSession(records: loaded)
                }
            case .failure(let error): report(error)
            }
        }
        .fileExporter(isPresented: $exportFile,
                      document: SmpFileDocument(text: stringData),
                      contentTypes: [transferFormat.contentType], defaultFilename: "ECompoData." + transferFormat.rawValue.lowercased()) { result in
            if case .failure(let error) = result { report(error) }
        } onCancellation: {
            // Cancellation does not change data.
        }
        .confirmationDialog(confirmationTitle, isPresented: $showMenuConfirmation,
                            titleVisibility: .visible) {
            switch menuConfirmation {
            case .delete:
                Button("Ok", role: .destructive) { okActionDelete() }
            case .importRecords:
                Button("置き換え", role: .destructive) { processImport(replacing: true) }
                Button("追記") { processImport(replacing: false) }
            case .reset:
                Button("すべて削除して初期化", role: .destructive) { resetAppData() }
            }
            Button("Cancel", role: .cancel) { importedData = [] }
        } message: {
            Text(confirmationMessage)
        }
    }

    var browsingHeader: some View {
        HStack(spacing: 8) {
            Text("\(records.isEmpty ? 0 : current + 1)/\(records.count)")
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Color.accentColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 7)
                .background(Color.accentColor.opacity(0.09), in: Capsule())
                .fixedSize()
                .accessibilityLabel("現在レコードと総件数")
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            Text("P.\(page)/L.\(line)")
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Color.accentColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 7)
                .background(Color.accentColor.opacity(0.09), in: Capsule())
                .fixedSize()
                .accessibilityLabel("ページと行")
            Menu {
                Picker("本", selection: searchSelection($selectedBook, scope: "本")) {
                    ForEach(Books, id: \.self) { Text($0) }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selectedBook.isEmpty ? "本を選択" : selectedBook)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            // Recreate the native menu when the available book names change.
            .id(Books)
            .accessibilityLabel("本")
            .accessibilityValue(selectedBook)
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 10)
        .padding(.vertical, 2)
        .background(Color(UIColor.secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.04), lineWidth: 1)
                .allowsHitTesting(false)
        }
        .padding(.bottom, 8)
    }

    var body: some View {
        VStack(alignment: .center){
            VStack(alignment: .center){
                browsingHeader
                VStack {
                    HStack {
                        Text("分野")
                        Picker("分野", selection: searchSelection($selectedField, scope: "分野")) {
                            ForEach(Fields, id: \.self) { Text($0).font(.subheadline) }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .clipped()
                        .contentShape(Rectangle())
                    }
                    HStack {
                        Text("話題")
                        Picker("話題", selection: searchSelection($selectedTopic, scope: "話題")) {
                            ForEach(Topics, id: \.self) { Text($0).font(.subheadline) }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .clipped()
                        .contentShape(Rectangle())
                    }
                    HStack {
                        Text("題目")
                        Picker("題目", selection: searchSelection($selectedTitle, scope: "題目")) {
                            ForEach(Titles, id: \.self) { Text($0).font(.subheadline) }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .clipped()
                        .contentShape(Rectangle())
                    }
                }
                //Spacer()
            }//.padding()
            .onTapGesture { UIApplication.shared.closeKeyboard() }
            //.onTapGesture {
            //    focusedField = nil
            //}
            //Spacer()
            Divider()
            ZStack {
                ScrollView {
                    VStack(spacing: 16) {
                        sentenceRow("和文", text: wabun, revealed: $isWabun)
                        sentenceRow("英文", text: eibun, revealed: $isEibun)
                        sentenceRow("備考", text: hint, revealed: $isHint)
                    }
                    .padding(.vertical, 8)
                    .padding(.bottom, 72)
                }
                // A new identity makes article changes animate and resets vertical scrolling.
                .id(id)
                .transition(reduceMotion ? .opacity : .push(from: swipeForward ? .trailing : .leading))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { gesture in
                        let horizontal = gesture.translation.width
                        let vertical = gesture.translation.height
                        // Keep vertical scrolling and small diagonal gestures from changing articles.
                        guard abs(horizontal) >= 40,
                              abs(horizontal) > abs(vertical) * 1.3 else { return }
                        swipeArticle(forward: horizontal < 0)
                    }
            )
            //Divider()
            //Spacer()
        }.padding()
            .overlay(alignment: .bottomTrailing) {
                actionMenu
                    .padding(.trailing, 20)
                    .padding(.bottom, 16)
            }
            .onAppear { initialize() }
            .sheet(item: $transferSession, onDismiss: presentPendingTransfer) { session in
                DataTransferOptionsView(direction: session.direction, context: session.context) { format, scope in
                    try prepareTransfer(session.direction, format: format,
                                        scope: scope, context: session.context)
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $importBookSession, onDismiss: {
                if pendingImportConfirmation {
                    pendingImportConfirmation = false
                    requestConfirmation(.importRecords)
                }
            }) { session in
                ImportBookSelectionView(records: session.records) { selected in
                    importedData = selected
                    pendingImportConfirmation = true
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .fullScreenCover(item: $editorSession) { session in
                RecordEditorView(record: session.record, isNew: session.isNew) { record in
                    try saveEditor(record, isNew: session.isNew)
                }
            }
            .alert("処理エラー", isPresented: Binding(
                get: { screenError != nil },
                set: { if !$0 { screenError = nil } }
            )) {
                Button("OK", role: .cancel) { screenError = nil }
            } message: {
                Text(screenError ?? "")
            }

    }
}

struct EditView :View {
    // https://d1v1b.com/swiftui/share_data_over_view
    @Binding var ttl: String
    @Binding var str: String
    @Environment(\.dismiss) var dismiss
    var body: some View {
        VStack{
            Label(ttl, systemImage: "square.and.pencil")
                .font(.largeTitle)
                .foregroundColor(.green)
            TextEditor(text: $str)
                .font(.system(size: 24))
                .autocapitalization(.none)
                //.frame(width: UIScreen.main.bounds.width,height: UIScreen.main.bounds.height)
                .frame(width: UIScreen.main.bounds.width)
                //.frame(width: 300, height: 300)
                .padding()
                .border(Color.green, width: CGFloat(2))
            Button("閉じる"){dismiss()}
        }.padding()
            .navigationBarTitle(ttl)
    }
}

/// A copy of the record keeps cancelled edits separate from the browsing screen.
struct RecordEditorSession: Identifiable {
    let id = UUID()
    let record: Record
    let isNew: Bool
}

struct RecordEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Record
    @State private var line: String
    @State private var page: String
    @State private var chap: String
    @State private var saveError: String?
    @State private var saving = false
    let isNew: Bool
    let onSave: (Record) throws -> Void

    init(record: Record, isNew: Bool, onSave: @escaping (Record) throws -> Void) {
        _draft = State(initialValue: record)
        _line = State(initialValue: String(record.line))
        _page = State(initialValue: String(record.page))
        _chap = State(initialValue: String(record.chap))
        self.isNew = isNew
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("掲載位置") {
                    LabeledContent("本") { TextField("本", text: $draft.book) }
                    LabeledContent("行") { TextField("0", text: $line).keyboardType(.numberPad) }
                    LabeledContent("頁") { TextField("0", text: $page).keyboardType(.numberPad) }
                    LabeledContent("章") { TextField("0", text: $chap).keyboardType(.numberPad) }
                }
                Section("分類") {
                    LabeledContent("分野") { TextField("分野", text: $draft.field) }
                    LabeledContent("話題") { TextField("話題", text: $draft.topic) }
                    LabeledContent("題目") { TextField("題目", text: $draft.title) }
                }
                Section("和文") {
                    TextEditor(text: $draft.wabun).frame(minHeight: 160)
                }
                Section("英文") {
                    TextEditor(text: $draft.eibun).frame(minHeight: 160)
                }
                Section("備考（ヒント）") {
                    TextEditor(text: $draft.hint).frame(minHeight: 120)
                }
                Section("その他の備考") {
                    TextEditor(text: $draft.description).frame(minHeight: 120)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(isNew ? "新規登録" : "編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }.disabled(saving)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("キーボードを閉じる") { UIApplication.shared.closeKeyboard() }
                }
            }
            .alert("保存できません", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: {
                Text(saveError ?? "")
            }
        }
        .interactiveDismissDisabled()
    }

    private func save() {
        guard !saving else { return }
        saving = true
        do {
            // Revalidate every field through the same path as CSV imports.
            var fields = draft.csvFields
            fields[4] = line; fields[5] = page; fields[6] = chap
            let validated = try Record(data: fields)
            try onSave(validated)
            dismiss()
        } catch {
            saving = false
            saveError = error.localizedDescription
        }
    }
}

enum DataTransferFormat: String, CaseIterable, Identifiable {
    case json = "JSON"
    case csv = "CSV"
    var id: String { rawValue }
    var contentType: UTType { self == .json ? .json : .commaSeparatedText }
}

enum DataTransferDirection {
    case `export`, `import`
    var title: String { self == .export ? "エクスポート" : "インポート" }
}

struct ExportContext {
    let scope: String
    let book: String
    let field: String
    let topic: String
    let title: String
    let page: String
}

struct DataTransferSession: Identifiable {
    let id = UUID()
    let direction: DataTransferDirection
    let context: ExportContext
}

struct DataTransferOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var format: DataTransferFormat = .json
    @State private var scope: String
    @State private var errorMessage: String?
    @State private var submitted = false
    let direction: DataTransferDirection
    let context: ExportContext
    let onSubmit: (DataTransferFormat, String) throws -> Void
    private let scopes = ["全", "本", "分野", "話題", "題目", "頁"]

    init(direction: DataTransferDirection, context: ExportContext,
         onSubmit: @escaping (DataTransferFormat, String) throws -> Void) {
        self.direction = direction
        self.context = context
        self.onSubmit = onSubmit
        _scope = State(initialValue: context.scope)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("ファイル形式") {
                    HStack(spacing: 16) {
                        ForEach(DataTransferFormat.allCases) { choice in
                            Button {
                                format = choice
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: format == choice ? "largecircle.fill.circle" : "circle")
                                        .foregroundStyle(Color.accentColor)
                                    Text(choice.rawValue).foregroundStyle(.primary)
                                    Spacer(minLength: 0)
                                }
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(choice.rawValue)
                            .accessibilityValue(format == choice ? "選択中" : "未選択")
                        }
                    }
                }
                if direction == .export {
                    Section {
                        Picker("検索対象", selection: $scope) {
                            ForEach(scopes, id: \.self) { Text($0) }
                        }
                        .pickerStyle(.menu)
                        if scope != "全" { LabeledContent("本", value: context.book) }
                        if ["分野", "話題", "題目"].contains(scope) { LabeledContent("分野", value: context.field) }
                        if ["話題", "題目"].contains(scope) { LabeledContent("話題", value: context.topic) }
                        if scope == "題目" { LabeledContent("題目", value: context.title) }
                        if scope == "頁" { LabeledContent("頁", value: context.page) }
                    } header: {
                        Text("検索対象")
                    } footer: {
                        Text("選択中の本・分類・頁を条件に出力します。「全」はすべての本が対象です。")
                    }
                } else {
                    Section {
                        Text("次の画面でファイルを選択します。読み込み後に取り込む本を選び、追記またはDB全体の置き換えを選べます。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(direction.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("次へ") { submit() }.disabled(submitted)
                }
            }
            .alert("処理できません", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
        }
    }

    private func submit() {
        guard !submitted else { return }
        do {
            try onSubmit(format, scope)
            submitted = true
            dismiss()
        } catch { errorMessage = error.localizedDescription }
    }
}

struct ImportBookSession: Identifiable {
    let id = UUID()
    let records: [Record]
}

struct ImportBookSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedBooks: Set<String> = []
    @State private var submitted = false
    let records: [Record]
    let onSelect: ([Record]) -> Void

    private var books: [String] {
        Array(Set(records.map { $0.book })).sorted {
            $0.localizedStandardCompare($1) == .orderedAscending
        }
    }

    private var selectedRecords: [Record] {
        records.filter { selectedBooks.contains($0.book) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(books, id: \.self) { book in
                        Button {
                            if selectedBooks.contains(book) { selectedBooks.remove(book) }
                            else { selectedBooks.insert(book) }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: selectedBooks.contains(book)
                                      ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(Color.accentColor)
                                Text(book.isEmpty ? "（本の名前なし）" : book)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text("\(records.filter { $0.book == book }.count)件")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityValue(selectedBooks.contains(book) ? "選択中" : "未選択")
                    }
                } header: {
                    Text("ファイル内の本（複数選択可）")
                } footer: {
                    Text("選択した本のデータだけを取り込みます。選択中：\(selectedBooks.count)冊・\(selectedRecords.count)件")
                }
            }
            .navigationTitle("取り込む本を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("次へ") {
                        guard !submitted, !selectedBooks.isEmpty else { return }
                        submitted = true
                        onSelect(selectedRecords)
                        dismiss()
                    }
                    .disabled(selectedBooks.isEmpty || submitted)
                }
            }
        }
    }
}

/// Save filters and stable record identity, rather than a copy of the database contents.
struct SavedBrowsingState: Codable {
    let scope: String
    let book: String
    let field: String
    let topic: String
    let title: String
    let page: String
    let recordID: Int
    let index: Int
}

#Preview {
    ContentView()
}
