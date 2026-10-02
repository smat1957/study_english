import SwiftUI
import UniformTypeIdentifiers

private enum TransferFormat: String, CaseIterable, Identifiable {
    case json = "JSON", csv = "CSV"
    var id: String { rawValue }
    var contentType: UTType { self == .json ? .json : .commaSeparatedText }
    var fileExtension: String { self == .json ? "json" : "csv" }
}

private enum TransferKind: String, Identifiable {
    case importing, exporting, questions
    var id: String { rawValue }
}

private struct EditorSession: Identifiable {
    let id = UUID()
    let record: Words
    let isNew: Bool
}

private struct ImportSession: Identifiable {
    let id = UUID()
    let records: [Words]
}

struct ContentView: View {
    @State private var dao = DAO()
    @State private var records: [Words] = []
    @State private var books: [String] = []
    @State private var selectedBook = ""
    @State private var searchStage: String?
    @State private var searchPage: Int?
    @State private var searchNumber: Int?
    @State private var stageChoices: [String] = []
    @State private var pageChoices: [String] = []
    @State private var numberChoices: [String] = []
    @State private var showingAbout = false
    @State private var current = 0
    @State private var initialized = false
    @State private var editor: EditorSession?
    @State private var transfer: TransferKind?
    @State private var format = TransferFormat.json
    @State private var exportScope = WordSearch.all
    @State private var exportValue = ""
    @State private var transferBook = ""
    @State private var questionPage = "0"
    @State private var randomQuestions = true
    @State private var exportText = ""
    @State private var exportName = "EWordData.json"
    @State private var exportType: UTType = .json
    @State private var exporting = false
    @State private var importing = false
    @State private var transferError = ""
    @State private var deferredReadError = ""
    @State private var pendingTransfer: TransferKind?
    @State private var importSession: ImportSession?
    @State private var pendingRecords: [Words] = []
    @State private var confirmImport = false
    @State private var pendingImportConfirmation = false
    @State private var confirmReset = false
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var hiddenFields: Set<String> = ["語釈", "類似語", "反意語", "関連語", "備考"]
    @State private var movingForward = true
    @Environment(\.scenePhase) private var scenePhase
    private let browsingStateKey = "EWord.browsingState.v1"
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var active: Words? { records.indices.contains(current) ? records[current] : nil }
    private var transition: AnyTransition {
        reduceMotion ? .opacity : .asymmetric(insertion: .move(edge: movingForward ? .trailing : .leading).combined(with: .opacity), removal: .move(edge: movingForward ? .leading : .trailing).combined(with: .opacity))
    }

    private func saveBrowsingState() {
        guard initialized else { return }
        let state = SavedWordBrowsingState(book: selectedBook, stage: searchStage,
            page: searchPage, number: searchNumber, recordID: active?.id, hiddenFields: hiddenFields)
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: browsingStateKey)
        }
    }

    private func restoreBrowsingState() throws {
        let availableBooks = try dao.books()
        let saved = UserDefaults.standard.data(forKey: browsingStateKey)
            .flatMap { try? JSONDecoder().decode(SavedWordBrowsingState.self, from: $0) }
        clearSearchInputs()
        current = 0
        if let saved {
            let knownFields: Set<String> = ["意味", "語釈", "類似語", "反意語", "関連語", "英文", "和文", "備考"]
            hiddenFields = saved.hiddenFields.intersection(knownFields)
            if availableBooks.contains(saved.book) {
                selectedBook = saved.book
                searchStage = saved.stage; searchPage = saved.page; searchNumber = saved.number
                // refresh validates the hierarchy before restoring the stable record ID.
                try refresh(preferredID: saved.recordID)
                return
            }
        }
        selectedBook = availableBooks.first ?? ""
        try refresh()
    }

    private func resetBrowsingState() {
        UserDefaults.standard.removeObject(forKey: browsingStateKey)
        saveBrowsingState()
    }

    private func report(_ error: Error) {
        errorMessage = error.localizedDescription
        showingError = true
    }

    private func refresh(preferredID: Int? = nil) throws {
        let fetchedBooks = try dao.books()
        let stages = try dao.filterChoices(field: "stage", book: selectedBook)
        let validStage = searchStage.flatMap { stages.contains($0) ? $0 : nil }
        let pages = try dao.filterChoices(field: "page", book: selectedBook, stage: validStage)
        let validPage = searchPage.flatMap { pages.contains(String($0)) && validStage != nil ? $0 : nil }
        let numbers = try dao.filterChoices(field: "numb", book: selectedBook, stage: validStage, page: validPage)
        let validNumber = searchNumber.flatMap { numbers.contains(String($0)) && validPage != nil ? $0 : nil }
        let fetched = try dao.selectFiltered(book: selectedBook, stage: validStage, page: validPage, number: validNumber)
        searchStage = validStage; searchPage = validPage; searchNumber = validNumber
        stageChoices = stages; pageChoices = pages; numberChoices = numbers
        books = fetchedBooks
        records = fetched
        if let preferredID, let index = records.firstIndex(where: { $0.id == preferredID }) {
            current = index
        } else { current = min(max(current, 0), max(records.count - 1, 0)) }
        saveBrowsingState()
    }

    private func search() {
        do { try refresh(); current = 0; saveBrowsingState() } catch { report(error) }
    }

    private func clearSearchInputs() {
        searchStage = nil; searchPage = nil; searchNumber = nil
        stageChoices = []; pageChoices = []; numberChoices = []
    }

    private func chooseFilter(_ target: WordSearch, value: String?) {
        switch target {
        case .stage: searchStage = value; searchPage = nil; searchNumber = nil
        case .page: searchPage = value.flatMap(Int.init); searchNumber = nil
        case .numb: searchNumber = value.flatMap(Int.init)
        default: return
        }
        search()
    }

    private func searchField(_ title: String, target: WordSearch, choices: [String], selected: String?, enabled: Bool) -> some View {
        HStack(spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.blue)
            Menu {
                Button("すべて") { chooseFilter(target, value: nil) }
                ForEach(choices, id: \.self) { value in
                    Button(value.isEmpty ? "（章なし）" : value) { chooseFilter(target, value: value) }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selected.map { $0.isEmpty ? "（章なし）" : $0 } ?? "すべて").lineLimit(1)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.down").font(.caption2)
                }
                .font(.subheadline)
                .padding(.horizontal, 6).padding(.vertical, 8)
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
            }
            .disabled(!enabled || choices.isEmpty)
            .accessibilityLabel("\(title)で検索")
        }
    }

    private func chooseBook(_ book: String) {
        selectedBook = book
        clearSearchInputs()
        search()
    }

    private func move(_ forward: Bool) {
        let next = current + (forward ? 1 : -1)
        guard records.indices.contains(next) else { return }
        movingForward = forward
        withAnimation(.easeInOut(duration: 0.28)) { current = next }
        saveBrowsingState()
    }

    private func save(_ record: Words, isNew: Bool) throws {
        let savedID: Int
        if isNew { savedID = try dao.insert(record) }
        else { try dao.update(record); savedID = record.id }
        selectedBook = record.book
        clearSearchInputs()
        // A successful write must not be offered again if the subsequent read fails.
        do { try refresh(preferredID: savedID) }
        catch {
            records = []; current = 0
            deferredReadError = "保存は完了しましたが、表示の更新に失敗しました。\n" + error.localizedDescription
        }
    }

    private func deleteRecord(id: Int) throws {
        try dao.delete(id: id)
        records.removeAll { $0.id == id }
        current = min(current, max(records.count - 1, 0))
        do { try refresh() }
        catch {
            deferredReadError = "削除は完了しましたが、表示の更新に失敗しました。\n" + error.localizedDescription
        }
    }

    private func applyImport(replacing: Bool) {
        do {
            try dao.importRecords(pendingRecords, replacing: replacing)
            let book = pendingRecords.first?.book ?? ""
            pendingRecords = []
            clearSearchInputs()
            selectedBook = book; current = 0
            records = []; books = []
            do { try refresh() }
            catch { report(DataError.database("取り込みは完了しましたが、表示の更新に失敗しました。\n" + error.localizedDescription)) }
        } catch { report(error) }
    }

    private func openTransfer(_ kind: TransferKind) {
        transferBook = selectedBook
        exportScope = .all
        exportValue = ""
        questionPage = String(active?.page ?? 0)
        pendingRecords = []
        transferError = ""
        transfer = kind
    }

    private func prepareTransfer(_ kind: TransferKind) {
        transferError = ""
        do {
            if kind == .importing { pendingTransfer = kind; transfer = nil; return }
            var output: [Words]
            if kind == .questions {
                let page = try Words.number(questionPage, name: "開始頁")
                let (end, overflow) = page.addingReportingOverflow(2)
                guard !overflow else { throw DataError.invalid("開始頁が大きすぎます。") }
                output = try dao.select(.page, book: transferBook, value: String(page), throughPage: end)
                if randomQuestions { output.shuffle() }
                exportType = .json; exportName = "EWordQuestions.json"
                exportText = try JSONRW().generate(records: output, questionsOnly: true)
            } else {
                output = try dao.select(exportScope, book: transferBook, value: exportValue)
                exportType = format.contentType
                exportName = "EWordData." + format.fileExtension
                exportText = format == .json ? try JSONRW().generate(records: output) : myCSV().CSVDataGen(records: output)
            }
            guard !output.isEmpty else { throw DataError.invalid("出力対象のデータがありません。") }
            pendingTransfer = kind
            transfer = nil
        } catch { transferError = error.localizedDescription }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                HStack {
                    Text(records.isEmpty ? "0/0" : "\(current + 1)/\(records.count)")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 7)
                        .background(Color.accentColor.opacity(0.09), in: Capsule())
                        .fixedSize()
                        .accessibilityLabel("現在レコードと総件数")
                    Text("P.\(active?.page ?? 0)/No.\(active?.numb ?? 0)")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 7)
                        .background(Color.accentColor.opacity(0.09), in: Capsule())
                        .fixedSize()
                        .accessibilityLabel("ページと番号")
                    Menu {
                        ForEach(books, id: \.self) { book in
                            Button(book.isEmpty ? "（本の名前なし）" : book) { chooseBook(book) }
                        }
                    } label: {
                        Label(selectedBook.isEmpty ? "本を選択" : selectedBook, systemImage: "book")
                            .font(.caption.weight(.medium))
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .disabled(books.isEmpty)
                }.padding(.horizontal)
                HStack(spacing: 10) {
                    searchField("章", target: .stage, choices: stageChoices, selected: searchStage, enabled: !books.isEmpty)
                    searchField("頁", target: .page, choices: pageChoices, selected: searchPage.map(String.init), enabled: searchStage != nil)
                    searchField("番号", target: .numb, choices: numberChoices, selected: searchNumber.map(String.init), enabled: searchStage != nil && searchPage != nil)
                }.padding(.horizontal)
                Divider()
                if let record = active {
                    ZStack {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text(record.word).font(.title.bold()).textSelection(.enabled)
                                    Spacer()
                                    Text(record.type).foregroundStyle(.secondary)
                                    if record.seq != 0 {
                                        Text(sequenceLabel(record.seq)).foregroundStyle(.secondary)
                                    }
                                }
                                Text("\(record.book) ／ \(record.stage)章").font(.caption).foregroundStyle(.secondary)
                                ForEach(displayFields(record).filter { !hiddenFields.contains($0.title) }) { item in
                                    field(item.title, item.text)
                                }
                                let hidden = displayFields(record).filter { hiddenFields.contains($0.title) }
                                if !hidden.isEmpty {
                                    CompactFieldLayout() {
                                        ForEach(hidden) { item in fieldHeader(item.title) }
                                    }
                                }
                            }.padding()
                        }
                        .id(record.id)
                        .transition(transition)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .simultaneousGesture(DragGesture(minimumDistance: 35).onEnded { gesture in
                        if abs(gesture.translation.width) > abs(gesture.translation.height) {
                            move(gesture.translation.width < 0)
                        }
                    })
                } else {
                    ContentUnavailableView("単語がありません", systemImage: "book.closed", description: Text("検索条件を変更するか、歯車メニューから新規登録・インポートしてください。"))
                }
                HStack {
                    Button { current = 0; saveBrowsingState() } label: { Image(systemName: "backward.end") }
                        .disabled(records.isEmpty || current == 0).accessibilityLabel("最初の単語")
                    Spacer()
                    Button { move(false) } label: { Image(systemName: "chevron.left") }
                        .disabled(records.isEmpty || current == 0).accessibilityLabel("前の単語")
                    Spacer()
                    Button { move(true) } label: { Image(systemName: "chevron.right") }
                        .disabled(records.isEmpty || current >= records.count - 1).accessibilityLabel("次の単語")
                    Spacer()
                    Button { current = max(records.count - 1, 0); saveBrowsingState() } label: { Image(systemName: "forward.end") }
                        .disabled(records.isEmpty || current >= records.count - 1).accessibilityLabel("最後の単語")
                }.buttonStyle(.bordered).padding(.horizontal).padding(.bottom, 8).padding(.trailing, 70)
            }
            .navigationTitle("EWord")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .bottomTrailing) {
                Menu {
                    Button { editor = EditorSession(record: Words(book: selectedBook), isNew: true) } label: { Label("新規", systemImage: "plus") }
                    Button { if let active { editor = EditorSession(record: active, isNew: false) } } label: { Label("編集", systemImage: "pencil") }.disabled(active == nil)
                    Divider()
                    Button { openTransfer(.questions) } label: { Label("出題用JSON", systemImage: "shuffle") }.disabled(active == nil)
                    Button { openTransfer(.exporting) } label: { Label("エクスポート", systemImage: "square.and.arrow.up") }
                    Button { openTransfer(.importing) } label: { Label("インポート", systemImage: "square.and.arrow.down") }
                    Divider()
                    Button(role: .destructive) { confirmReset = true } label: { Label("初期化", systemImage: "exclamationmark.triangle") }
                    Divider()
                    Button { showingAbout = true } label: { Label("About", systemImage: "info.circle") }
                } label: {
                    Image(systemName: "gearshape.fill").font(.title2).padding(16)
                        .background(.regularMaterial, in: Circle()).shadow(radius: 3)
                }
                .menuOrder(.fixed)
                .accessibilityLabel("操作メニュー").padding()
            }
            .task {
                guard !initialized else { return }
                do {
                    try dao.initial()
                    try restoreBrowsingState()
                    initialized = true
                    saveBrowsingState()
                } catch { report(error) }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .inactive || phase == .background { saveBrowsingState() }
            }
            .fullScreenCover(item: $editor, onDismiss: {
                if !deferredReadError.isEmpty {
                    errorMessage = deferredReadError
                    deferredReadError = ""
                    showingError = true
                }
            }) { session in
                WordEditor(record: session.record, isNew: session.isNew,
                           onSave: { try save($0, isNew: session.isNew) },
                           onDelete: { try deleteRecord(id: session.record.id) })
            }
            .sheet(isPresented: $showingAbout) { AboutView() }
            .sheet(item: $transfer, onDismiss: {
                if let pendingTransfer {
                    self.pendingTransfer = nil
                    if pendingTransfer == .importing { importing = true } else { exporting = true }
                }
            }) { kind in
                transferView(kind)
            }
            .sheet(item: $importSession, onDismiss: {
                if pendingImportConfirmation { pendingImportConfirmation = false; confirmImport = true }
            }) { session in
                ImportBookSelection(records: session.records) { selected in
                    pendingRecords = selected
                    pendingImportConfirmation = true
                }
            }
            .fileExporter(isPresented: $exporting, document: SmpFileDocument(text: exportText), contentType: exportType, defaultFilename: exportName) { result in
                if case .failure(let error) = result { report(error) }
            }
            .fileImporter(isPresented: $importing, allowedContentTypes: format == .json ? [.json, .plainText] : [.commaSeparatedText, .plainText]) { result in
                do {
                    let url = try result.get()
                    let loaded = format == .json ? try JSONRW().read(url: url) : try myCSV().reshape(url: url)
                    importSession = ImportSession(records: loaded)
                } catch { report(error) }
            }
            .alert("取り込み方法", isPresented: $confirmImport) {
                Button("追記") { applyImport(replacing: false) }
                Button("全データを置き換え", role: .destructive) { applyImport(replacing: true) }
                Button("キャンセル", role: .cancel) { pendingRecords = [] }
            } message: { Text("選択した\(Set(pendingRecords.map(\.book)).count)冊・\(pendingRecords.count)件を取り込みます。置き換えは、選択していない本も含め既存の全単語を削除します。追記では同じデータも追加されます。") }
            .alert("すべての単語を削除しますか？", isPresented: $confirmReset) {
                Button("すべて削除して初期化", role: .destructive) {
                    do {
                        try dao.clearAllRecords()
                        clearSearchInputs()
                        records = []; books = []; selectedBook = ""; current = 0
                        resetBrowsingState()
                    } catch { report(error) }
                }
                Button("キャンセル", role: .cancel) { }
            } message: { Text("すべての本と単語を削除します。取り消せません。必要なデータは先に「全」をエクスポートしてください。") }
            .alert("エラー", isPresented: $showingError) { Button("閉じる", role: .cancel) { } } message: { Text(errorMessage) }
        }
    }

    private func sequenceLabel(_ value: Int) -> String {
        let labels = ["ー", "①", "②", "③", "④", "⑤"]
        return labels.indices.contains(value) ? labels[value] : String(value)
    }

    private func displayFields(_ record: Words) -> [DisplayField] {
        let fields = [
            DisplayField(title: "意味", text: record.mean),
            DisplayField(title: "語釈", text: record.expr),
            DisplayField(title: "類似語", text: record.simlr),
            DisplayField(title: "反意語", text: record.invrt),
            DisplayField(title: "関連語", text: record.relat),
            DisplayField(title: "英文", text: record.eibun),
            DisplayField(title: "和文", text: record.wabun),
            DisplayField(title: "備考", text: record.descr)
        ]
        return fields
    }

    private func fieldHeader(_ title: String) -> some View {
        HStack(spacing: 8) {
            Button {
                if hiddenFields.contains(title) { hiddenFields.remove(title) }
                else { hiddenFields.insert(title) }
                saveBrowsingState()
            } label: {
                Image(systemName: hiddenFields.contains(title) ? "circle" : "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.blue)
                    .frame(width: 24, height: 24)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(title)の表示切り替え")
            .accessibilityValue(hiddenFields.contains(title) ? "非表示" : "表示中")
            Text(title).font(.subheadline).foregroundStyle(.blue)
        }
    }

    private func field(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldHeader(title)
            Text(text.isEmpty ? "—" : text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
    }

    private func transferView(_ kind: TransferKind) -> some View {
        NavigationStack {
            Form {
                if !transferError.isEmpty {
                    Text(transferError).foregroundStyle(.red)
                }
                if kind != .questions {
                    Picker("形式", selection: $format) {
                        ForEach(TransferFormat.allCases) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented)
                }
                if kind == .exporting {
                    Picker("対象", selection: $exportScope) {
                        ForEach(WordSearch.allCases) { Text($0.rawValue).tag($0) }
                    }
                    if exportScope != .all { Text("本：\(transferBook.isEmpty ? "（本の名前なし）" : transferBook)") }
                    if exportScope != .all && exportScope != .book {
                        TextField(exportScope.rawValue, text: $exportValue)
                            .keyboardType(exportScope == .page || exportScope == .numb ? .numberPad : .default)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    Text("JSON・CSVとも全項目を出力します。閲覧中の検索結果は変更しません。")
                        .font(.footnote).foregroundStyle(.secondary)
                } else if kind == .questions {
                    Text("本：\(transferBook)")
                    TextField("開始頁", text: $questionPage).keyboardType(.numberPad)
                    Toggle("ランダム順", isOn: $randomQuestions)
                    Text("開始頁から2頁先までの単語を出力します。従来の8項目形式です。完全なバックアップにはエクスポートを使用してください。")
                        .font(.footnote).foregroundStyle(.secondary)
                } else {
                    Text("ファイルを読み込んだ後、取り込む本を選び、追記または全データの置き換えを選択します。")
                }
            }
            .navigationTitle(kind == .importing ? "インポート" : kind == .questions ? "出題用JSON" : "エクスポート")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { transfer = nil } }
                ToolbarItem(placement: .confirmationAction) { Button("次へ") { prepareTransfer(kind) } }
            }
        }.presentationDetents([.medium, .large])
    }
}

private struct WordEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Words
    @State private var page: String
    @State private var numb: String
    @State private var sequence: String
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var saving = false
    let isNew: Bool
    @State private var confirmDelete = false
    let deletionTarget: Words
    let onSave: (Words) throws -> Void
    let onDelete: () throws -> Void

    init(record: Words, isNew: Bool, onSave: @escaping (Words) throws -> Void,
         onDelete: @escaping () throws -> Void) {
        _draft = State(initialValue: record)
        _page = State(initialValue: String(record.page))
        _numb = State(initialValue: String(record.numb))
        _sequence = State(initialValue: String(record.seq))
        self.isNew = isNew; self.onSave = onSave
        self.deletionTarget = record; self.onDelete = onDelete
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("掲載位置") {
                    positionInput("本", $draft.book)
                    positionInput("章", $draft.stage)
                    positionInput("頁", $page).keyboardType(.numberPad)
                    positionInput("通番", $numb).keyboardType(.numberPad)
                    positionInput("連番", $sequence).keyboardType(.numberPad)
                }
                Section("単語") {
                    input("単語", $draft.word)
                    input("品詞", $draft.type)
                    text("意味", $draft.mean)
                    text("語釈", $draft.expr)
                    text("類似語", $draft.simlr)
                    text("反意語", $draft.invrt)
                    text("関連語", $draft.relat)
                }
                Section("例文・備考") {
                    text("英文", $draft.eibun)
                    text("和文", $draft.wabun)
                    text("備考", $draft.descr)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(isNew ? "新規登録" : "編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") { dismiss() }.disabled(saving)
                }
                if !isNew {
                    if #available(iOS 26.0, *) {
                        ToolbarSpacer(.fixed, placement: .topBarLeading)
                    }
                    ToolbarItem(placement: .topBarLeading) {
                        Button("削除", role: .destructive) { confirmDelete = true }
                            .foregroundStyle(.red)
                            .disabled(saving)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        guard !saving else { return }
                        saving = true
                        do {
                            draft.page = try Words.number(page, name: "頁")
                            draft.numb = try Words.number(numb, name: "通番")
                            draft.seq = try Words.number(sequence, name: "連番")
                            try draft.validate()
                            try onSave(draft)
                            dismiss()
                        } catch { errorMessage = error.localizedDescription; showingError = true; saving = false }
                    }.disabled(saving)
                }
            }
            .interactiveDismissDisabled()
            .alert("この単語を削除しますか？", isPresented: $confirmDelete) {
                Button("削除", role: .destructive) {
                    guard !saving else { return }
                    saving = true
                    do {
                        try onDelete()
                        dismiss()
                    } catch {
                        errorMessage = error.localizedDescription
                        showingError = true
                        saving = false
                    }
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("\(deletionTarget.word)\n未保存の変更は保存せず、この単語を削除します。")
            }
            .alert("処理できません", isPresented: $showingError) { Button("閉じる", role: .cancel) { } } message: { Text(errorMessage) }
        }
    }

    private func positionInput(_ title: String, _ binding: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Text(title).font(.caption).foregroundStyle(.secondary)
                .frame(width: 40, alignment: .leading)
            TextField(title, text: binding)
        }
    }

    private func input(_ title: String, _ binding: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            TextField(title, text: binding, axis: .vertical)
        }
    }

    private func text(_ title: String, _ binding: Binding<String>) -> some View {
        VStack(alignment: .leading) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            TextEditor(text: binding).frame(minHeight: 80)
        }
    }
}

private struct ImportBookSelection: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selected: Set<String> = []
    @State private var submitted = false
    let records: [Words]
    let onSelect: ([Words]) -> Void
    private var books: [String] { Array(Set(records.map(\.book))).sorted() }
    private var selectedRecords: [Words] { records.filter { selected.contains($0.book) } }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(books, id: \.self) { book in
                        Button {
                            if selected.contains(book) { selected.remove(book) } else { selected.insert(book) }
                        } label: {
                            HStack {
                                Image(systemName: selected.contains(book) ? "checkmark.circle.fill" : "circle")
                                Text(book.isEmpty ? "（本の名前なし）" : book).foregroundStyle(.primary)
                                Spacer()
                                Text("\(records.filter { $0.book == book }.count)件").foregroundStyle(.secondary)
                            }
                        }.accessibilityValue(selected.contains(book) ? "選択中" : "未選択")
                    }
                } header: { Text("本を複数選択できます") } footer: { Text("選択中：\(selected.count)冊・\(selectedRecords.count)件") }
            }
            .navigationTitle("取り込む本を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("次へ") { submitted = true; onSelect(selectedRecords); dismiss() }
                        .disabled(selected.isEmpty || submitted)
                }
            }
        }
    }
}

private struct DisplayField: Identifiable {
    let title: String
    let text: String
    var id: String { title }
}

/// Pack hidden field controls into rows, wrapping at the available width.
private struct CompactFieldLayout: Layout {
    var horizontalSpacing: CGFloat = 14
    var verticalSpacing: CGFloat = 8

    private func arrangement(width: CGFloat, subviews: Subviews) -> (positions: [CGPoint], sizes: [CGSize], height: CGFloat) {
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let ideal = subview.sizeThatFits(.unspecified)
            let size = subview.sizeThatFits(ProposedViewSize(width: min(ideal.width, width), height: nil))
            if x > 0 && x + size.width > width {
                x = 0
                y += rowHeight + verticalSpacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            sizes.append(size)
            rowHeight = max(rowHeight, size.height)
            x += size.width + horizontalSpacing
        }
        return (positions, sizes, y + rowHeight)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let naturalWidth = subviews.reduce(CGFloat.zero) { $0 + $1.sizeThatFits(.unspecified).width }
            + CGFloat(max(subviews.count - 1, 0)) * horizontalSpacing
        let width = max(proposal.width ?? naturalWidth, 0)
        return CGSize(width: width, height: arrangement(width: width, subviews: subviews).height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrangement(width: bounds.width, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            let position = rows.positions[index]
            subview.place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                          anchor: .topLeading, proposal: ProposedViewSize(rows.sizes[index]))
        }
    }
}

/// Store search selections and record identity, never a stale copy of database rows.
private struct SavedWordBrowsingState: Codable {
    let book: String
    let stage: String?
    let page: Int?
    let number: Int?
    let recordID: Int?
    let hiddenFields: Set<String>
}
