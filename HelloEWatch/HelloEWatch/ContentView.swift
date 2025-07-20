//
//  ContentView.swift
//  HelloEWatch
//
//  Created by 的池秋成 on 2024/10/31.
//
import SQLite3

/// SQLite3
/// https://qiita.com/SolaRayLino/items/06704b4709c700f3c3fa
class SQLite3 {

    /// Connection
    private var db: OpaquePointer?

    /// Statement
    private var statement: OpaquePointer?

    /// データベースを開く
    /// - Parameter path: ファイルパス
    /// - Returns: 実行結果
    @discardableResult
    func open(path: String) -> Int {
        let ret = sqlite3_open_v2(path, &self.db, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX, nil)

        if ret != SQLITE_OK {
            print("error sqlite3_open_v2: code=\(ret)")
        }

        return Int(ret)
    }

    /// ステートメントを生成しないでSQLを実行
    /// - Parameter sql: SQL
    /// - Returns: 実行結果
    @discardableResult
    func exec(_ sql: String) -> Int {
        let ret = sqlite3_exec(self.db, sql, nil, nil, nil)

        if ret != SQLITE_OK {
            let msg = String(cString: sqlite3_errmsg(self.db)!)
            print("error sqlite3_exec: code=\(ret), errmsg=\(msg)")
        }

        return Int(ret)
    }

    /// ステートメントの生成
    /// - Parameter sql: SQL
    /// - Returns: 実行結果
    @discardableResult
    func prepare(_ sql: String) -> Int {
        let ret = sqlite3_prepare_v2(self.db, sql, -1, &self.statement, nil)

        if ret != SQLITE_OK {
            let msg = String(cString: sqlite3_errmsg(self.db)!)
            print("error sqlite3_prepare_v2: code=\(ret), errmsg=\(msg)")
        }

        return Int(ret)
    }


    /// 作成されたステートメントにInt型パラメーターを生成
    /// - Parameters:
    ///   - index: インデックス
    ///   - value: 値
    /// - Returns: 実行結果
    @discardableResult
    func bindInt(index: Int, value: Int) -> Int {
        let ret = sqlite3_bind_int(self.statement, Int32(index), Int32(value))

        if ret != SQLITE_OK {
            let msg = String(cString: sqlite3_errmsg(self.db)!)
            print("error sqlite3_bind_int: code=\(ret), errmsg=\(msg)")
        }

        return Int(ret)
    }

    /// 作成されたステートメントにString型(UTF-8)パラメーターを生成
    /// - Parameters:
    ///   - index: インデックス
    ///   - value: 値
    /// - Returns: 実行結果
    @discardableResult
    func bindText(index: Int, value: String) -> Int {
        let ret = sqlite3_bind_text(self.statement, Int32(index), (value as NSString).utf8String, -1, nil)

        if ret != SQLITE_OK {
            let msg = String(cString: sqlite3_errmsg(self.db)!)
            print("error sqlite3_bind_text: code=\(ret), errmsg=\(msg)")
        }

        return Int(ret)
    }

    /// ステートメントの実行（SELECTの場合は行の取得）
    /// - Returns: 実行結果
    @discardableResult
    func step() -> Int {
        let ret = sqlite3_step(self.statement)

        if ret != SQLITE_ROW && ret != SQLITE_DONE {
            let msg = String(cString: sqlite3_errmsg(self.db)!)
            print("error sqlite3_step: code=\(ret), errmsg=\(msg)")
        }

        return Int(ret)
    }

    /// ステートメントのリセット
    /// - Returns: 実行結果
    @discardableResult
    func resetStatement() -> Int {
        let ret = sqlite3_reset(self.statement)

        if ret != SQLITE_OK {
            let msg = String(cString: sqlite3_errmsg(self.db)!)
            print("error sqlite3_reset: code=\(ret), errmsg=\(msg)")
        }

        return Int(ret)
    }

    /// ステートメントの破棄
    /// - Returns: 実行結果
    @discardableResult
    func finalizeStatement() -> Int {
        let ret = sqlite3_finalize(self.statement)

        if ret != SQLITE_OK {
            let msg = String(cString: sqlite3_errmsg(self.db)!)
            print("error sqlite3_finalize: code=\(ret), errmsg=\(msg)")
        }

        return Int(ret)
    }

    /// SELECTしたステートメントからInt値を取得
    /// - Parameter index: カラムインデックス(0から)
    /// - Returns: Int値
    func columnInt(index: Int) -> Int {
        return Int(sqlite3_column_int(self.statement, Int32(index)))
    }

    /// SELECTしたステートメントからString値を取得
    /// - Parameter index: カラムインデックス(0から)
    /// - Returns: String値
    func columnText(index: Int) -> String {
        return String(cString: sqlite3_column_text(self.statement, Int32(index)))
    }

    /// データベースを閉じる
    /// - Returns: 実行結果
    @discardableResult
    func close() -> Int {
        let ret = sqlite3_close_v2(self.db)

        if ret != SQLITE_OK {
            let msg = String(cString: sqlite3_errmsg(self.db)!)
            print("error sqlite3_close_v2: code=\(ret), errmsg=\(msg)")
        }

        return Int(ret)
    }

    /// テーブル存在チェック
    /// - Parameters:
    ///   - sqlite3: SQLite3
    ///   - table: テーブル名
    func existsTable(_ tableName: String) -> Bool {
        self.prepare("SELECT COUNT(*) AS CNT FROM sqlite_master WHERE type = ? and name = ?")
        defer { self.finalizeStatement() }

        self.bindText(index: 1, value: "table")
        self.bindText(index: 2, value: tableName)

        if self.step() == SQLITE_ROW {
            if self.columnInt(index: 0) > 0 {
                return true
            }
        }

        return false
    }
}

struct Word {
    var id: Int
    var seq: Int
    var word: String
    var type: String
    var mean: String
    var expr: String
    var simlr: String
    var invrt: String
    var relat: String
    var eibun: String
    var wabun: String
    var descr: String
    var book: String
    var stage: String
    var page: Int
    var numb: Int
}

var words:[Word] = []

class DAO:SQLite3{
    let table_name:String = "watchEword"
    
    func initial(){
        let rootDirectory = NSHomeDirectory() + "/Documents"
        open(path: rootDirectory+"/eword_watch_sqlite3")
        //drop_table()
        //create_table()
        print("dao!->",rootDirectory+"/eword_watch_sqlite3")
    }
    
    func drop_table(){
        exec("""
    DROP TABLE \(table_name)
    """)
    }
    
    func create_table(){
        exec("""
    CREATE TABLE \(table_name) (
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        seq INTEGER,
        word TEXT NOT NULL,
        type TEXT,
        mean TEXT,
        expr TEXT,
        simlr TEXT,
        invrt TEXT,
        relat TEXT,
        eibun TEXT,
        wabun TEXT,
        descr TEXT,
        book TEXT,
        stage TEXT,
        page INTEGER,
        numb INTEGER
    )
    """)
    }
    
    func delete(id:Int){
        prepare("DELETE FROM \(table_name) WHERE id=?")
        bindInt(index: 1, value: id)
        if step() != SQLITE_DONE {
            print("error: DELETE")
        }
        resetStatement()
    }
    
    func insert_fromcsv(data:[String]){
        print("..>", data)
        prepare("INSERT INTO \(table_name)(seq,word,type,mean,expr,simlr,invrt,relat,eibun,wabun,descr,book,stage,page,numb) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)")
        bindInt(index: 1, value: Int(data[1])!)
        for i in 2..<14{
            bindText(index: i, value: String(data[i]))
        }
        for i in 14..<16{
            bindInt(index: i, value: Int(data[i])!)
        }
        if step() != SQLITE_DONE {
            print("error: INSERT")
        }
        resetStatement()
    }

    func insert(data:[String]){
        prepare("INSERT INTO \(table_name)(seq,word,type,mean,expr,simlr,invrt,relat,eibun,wabun,descr,book,stage,page,numb) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)")
        bindInt(index: 1, value: Int(data[0])!-1)
        for i in 1..<11{
            bindText(index: i+1, value: String(data[i]))
        }
        for i in 11..<15{
            if i<13 {
                bindText(index: i+1, value: String(data[i]))
            }else {
                bindInt(index: i+1, value: Int(data[i])!)
            }
        }
        if step() != SQLITE_DONE {
            print("error: INSERT")
        }
        resetStatement()
    }
    
    func update(data:[String], id:Int){
        prepare("UPDATE \(table_name) SET seq=?,word=?,type=?,mean=?,expr=?,simlr=?,invrt=?,relat=?,eibun=?,wabun=?,descr=?,book=?,stage=?,page=?,numb=? WHERE id=?")
        bindInt(index: 1, value: Int(data[0])!-1)
        for i in 1..<11{
            bindText(index: i+1, value: String(data[i]))
        }
        for i in 11..<15{
            if i<13 {
                bindText(index: i+1, value: String(data[i]))
            }else {
                bindInt(index: i+1, value: Int(data[i])!)
            }
        }
        bindInt(index: 16, value: id)
        if step() != SQLITE_DONE {
            print("error: UPDATE")
        }
        resetStatement()
    }
    
    func append_word(){
        words.removeAll()
        while step() == SQLITE_ROW {
            let id = columnInt(index: 0)
            let seq = columnInt(index: 1)
            let word = columnText(index: 2)
            let type = columnText(index: 3)
            let mean = columnText(index: 4)
            let expr = columnText(index: 5)
            let simlr = columnText(index: 6)
            let invrt = columnText(index: 7)
            let relat = columnText(index: 8)
            let eibun = columnText(index: 9)
            let wabun = columnText(index: 10)
            let descr = columnText(index: 11)
            let book = columnText(index: 12)
            let stage = columnText(index: 13)
            let page = columnInt(index: 14)
            let numb = columnInt(index: 15)
            words.append(Word(id:id, seq:seq, word:word, type:type, mean:mean, expr:expr, simlr:simlr, invrt:invrt, relat:relat, eibun:eibun, wabun:wabun, descr:descr, book:book, stage:stage, page:page, numb:numb))
            //print("IntField:\(id), TextField:\(word)")
        }
    }
    
    func distinct(field_name: String) -> [String]{
        let sql = "SELECT DISTINCT \(field_name) FROM \(table_name) ORDER BY \(field_name) ASC"
        prepare(sql)
        var list = [String]()
        while step() == SQLITE_ROW {
            list.append(columnText(index: 0))
        }
        resetStatement()
        return list
    }

    func distinct_onBook(field_name: String, book: String) -> [String]{
        let sql = "SELECT DISTINCT \(field_name) FROM \(table_name) WHERE book = \"\(book)\" ORDER BY \(field_name) ASC"
        prepare(sql)
        var list = [String]()
        while step() == SQLITE_ROW {
            list.append(columnText(index: 0))
        }
        resetStatement()
        return list
    }
    func distinct_onStageBook(field_name: String, stage: String, book: String) -> [String]{
        let sql = "SELECT DISTINCT \(field_name) FROM \(table_name) WHERE book = \"\(book)\" AND stage = \"\(stage)\" ORDER BY \(field_name) ASC"
        prepare(sql)
        var list = [String]()
        while step() == SQLITE_ROW {
            list.append(columnText(index: 0))
        }
        resetStatement()
        return list
    }

    func select_all(){
        prepare("SELECT * FROM \(table_name) ORDER BY book ASC, stage ASC, page ASC, numb ASC, word ASC, seq ASC")
        append_word()
        if step() != SQLITE_DONE {
            print("error: SELECT")
        }
        resetStatement()
    }
    
    func select_book(book:String){
        prepare("SELECT * FROM \(table_name) WHERE book = ? ORDER BY book ASC, stage ASC, page ASC, numb ASC, word ASC, seq ASC")
        bindText(index: 1, value: book)
        append_word()
        if step() != SQLITE_DONE {
            print("error: SELECT")
        }
        resetStatement()
    }
    
    func select_book_stage(book:String, stage:String){
        prepare("SELECT * FROM \(table_name) WHERE book = ? AND stage = ? ORDER BY book ASC, stage ASC, page ASC, numb ASC, word ASC, seq ASC")
        bindText(index: 1, value: book)
        bindText(index: 2, value: stage)
        append_word()
        if step() != SQLITE_DONE {
            print("error: SELECT")
        }
        resetStatement()
    }
    
    func select_book_page(book:String, page:Int){
        prepare("SELECT * FROM \(table_name) WHERE book = ? AND page = ? ORDER BY book ASC, stage ASC, page ASC, numb ASC, word ASC, seq ASC")
        bindText(index: 1, value: book)
        bindInt(index: 2, value: page)
        append_word()
        if step() != SQLITE_DONE {
            print("error: SELECT")
        }
        resetStatement()
    }
    
    func select_book_numb(book:String, numb:Int){
        prepare("SELECT * FROM \(table_name) WHERE book = ? AND numb = ? ORDER BY book ASC, stage ASC, page ASC, numb ASC, word ASC, seq ASC")
        bindText(index: 1, value: book)
        bindInt(index: 2, value: numb)
        append_word()
        if step() != SQLITE_DONE {
            print("error: SELECT")
        }
        resetStatement()
    }

    func select_book_word(book:String, word:String){
        prepare("SELECT * FROM \(table_name) WHERE book = ? AND word = ? ORDER BY book ASC, stage ASC, page ASC, numb ASC, word ASC, seq ASC")
        bindText(index: 1, value: book)
        bindText(index: 2, value: word)
        append_word()
        if step() != SQLITE_DONE {
            print("error: SELECT")
        }
        resetStatement()
    }
    
    func select_word(word:String){
        prepare("SELECT * FROM \(table_name) WHERE word = ? ORDER BY book ASC, stage ASC, page ASC, numb ASC, word ASC, seq ASC")
        bindText(index: 1, value: word)
        append_word()
        if step() != SQLITE_DONE {
            print("error: SELECT")
        }
        resetStatement()
    }
}

class myCSV{
    /* Generate csv */
    func fileContents(file: URL) -> String {
        // アクセス権取得
        let gotAccess = file.startAccessingSecurityScopedResource()
        if !gotAccess { return ""}
        // ファイルの内容を取得する
        //let filename = file.lastPathComponent
        //let directoryURL = file.deletingLastPathComponent()
        //let folder = URL(fileURLWithPath: directoryURL.path)
        //let filen = folder.appendingPathComponent(filename)
        //print("file://"+directoryURL.path+"/"+filename)
        var text: String = ""
        do {
            text = try String(contentsOf: file, encoding: String.Encoding.utf8)
        } catch {
            print(error.localizedDescription)
        }
        // アクセス権解放
        file.stopAccessingSecurityScopedResource()
        return text
    }
    
    func reshape(url: URL) -> [[String]]{
        var outdata: [[String]] = [[]]
        var csvdata: [String] = []
        var str: String = ""
        var flag: Bool = false
        let textString: String = fileContents(file: url)
        let lineChange = textString.replacingOccurrences(of: "\r", with: "\n")
        var lineArray: [String] = lineChange.components(separatedBy: "\n")
        if lineArray.last!.isEmpty{
            lineArray.removeLast()
        }
        for line in lineArray {
            var CR: Bool = false
            if flag {
                CR = true
            }
            let dataArray: [String] = line.components(separatedBy: ",")
            if(dataArray[0]=="ID"){continue}
            for data in dataArray{
                var CM: Bool = false
                if flag {
                    CM = true
                }
                if data=="\"" {
                    if flag {
                        csvdata.append(str.replacingOccurrences(of:"\"", with:""))
                        flag = false
                        CM = false
                        CR = false
                    }else{
                        flag=true
                    }
                } else if (!data.hasPrefix("\"")&&(!data.hasSuffix("\""))){
                    if flag {
                        var sep:String = ""
                        if CM {
                            sep = ", "
                        }
                        if CR {
                            sep = "\n"
                        }
                        if str.isEmpty {
                            if CM||CR {
                                str = sep + data
                            }else{
                                str = data
                            }
                            
                        }else{
                            if CM||CR {
                                str = str + sep + data
                            }else{
                                str += data
                            }
                        }
                        if CM {CM=false}
                        if CR {CR=false}
                    }else{
                        csvdata.append(data.replacingOccurrences(of:"\"", with:""))
                        CM = false
                        CR = false
                    }
                }else if (data.hasPrefix("\"")&&(data.hasSuffix("\""))){
                    csvdata.append(data.replacingOccurrences(of:"\"", with:""))
                    CM = false
                    CR = false
                }else if (data.hasPrefix("\"")&&(!data.hasSuffix("\""))){
                    str = data
                    flag = true
                }else if ((!data.hasPrefix("\""))&&(data.hasSuffix("\""))){
                    if str.isEmpty {
                        str = data
                    }else{
                        var sep:String = ""
                        if CM {
                            sep = ", "
                        }
                        if CR {
                            sep = "\n"
                        }
                        if CR||CM {
                            str = str + sep + data
                        }else{
                            str += data
                        }
                        if CM {CM=false}
                        if CR {CR=false}
                    }
                    csvdata.append(str.replacingOccurrences(of:"\"", with:""))
                    flag = false
                    CM = false
                    CR = false
                }
                if 16==csvdata.count{
                    if csvdata[0]==""{
                        csvdata.removeFirst()
                    }
                    outdata.append(csvdata)
                    csvdata.removeAll()
                }
            }
        }
        return outdata
    }
}

// https://qiita.com/AS_atsushi/items/77c2389a7f21f15c4865
// https://devops-blog.virtualtech.jp/entry/20230105/1672886601
//
import SwiftUI
import WatchConnectivity

struct ContentView: View {
    @ObservedObject private var connector = WatchConnector()
    private let dao = DAO()
    private let csv = myCSV()
    @State private var fileImport: Bool = false
    @State private var selectedBook: String = "上級英英単"
    @State private var selectedStage: String = "1"
    @State private var selectedPage: String = "12"
    @State private var selectedSrch: String = "全て"
    @State private var books = ["超上級英英単","1級パス単","1級単熟語Ex","上級英英単","準1級パス単","準1級単熟語Ex","入試ターゲット","入試シス単"]
    @State private var stages = ["1","2","3","4","5","6","7","8","9","10"]
    @State private var pages = ["1","2","3","4","5","6","7","8","9","10"]
    @State private var srchObjs = ["全て", "本で", "章で", "頁で"]
    func forAppearance(){
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.backgroundColor = UIColor(
            red: 30/255,
            green: 150/255,
            blue: 234/255,
            alpha: 1.0
        )
        navigationBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font : UIFont.systemFont(ofSize: 30, weight: .bold)
        ]
        navigationBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font : UIFont.systemFont(ofSize: 30, weight: .bold)
        ]
        
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
    }
    init() {
        self.forAppearance()
        self.dao.initial()
        words.removeAll()
        self.books = self.dao.distinct(field_name: "book")
        self.dao.select_book(book: books[0])
    }
    
    func search(){
        words.removeAll()
        if selectedSrch == "全て" {
            self.dao.select_all()
            self.books = self.dao.distinct(field_name: "book")
        } else if selectedSrch == "頁で" {
            self.dao.select_book_page(book: self.selectedBook, page: Int(self.selectedPage)!)
        } else if selectedSrch == "章で" {
            self.dao.select_book_stage(book: self.selectedBook, stage: self.selectedStage)
        } else if selectedSrch == "本で" {
            self.dao.select_book(book: self.selectedBook)
            self.stages = self.dao.distinct_onBook(field_name: "stage", book: self.selectedBook)
            self.pages = self.dao.distinct_onStageBook(field_name: "page", stage: self.selectedStage, book: self.selectedBook)
        }
        self.connector.current = 0
        self.connector.selectedSrch = self.selectedSrch
    }

    var body: some View {
        NavigationStack{
            VStack{
                //Spacer()
                HStack{
                    Button(action: {self.fileImport = true},
                           label:{Image(systemName: "gearshape").symbolRenderingMode(.monochrome)})
                    .buttonBorderShape(.capsule)
                    .tint(.pink)
                    .buttonStyle(.borderedProminent)
                    .padding()
                    .fileImporter(isPresented: $fileImport,
                                  allowedContentTypes: [.plainText],
                                  allowsMultipleSelection: false
                    ) { result in
                        switch result {
                        case .success(let directory):
                            directory.forEach { file in
                                // CSVの読み込み
                                let data: [[String]] = self.csv.reshape(url: file)
                                // DBに登録
                                self.dao.close()
                                self.dao.initial()
                                self.dao.drop_table()
                                self.dao.create_table()
                                for csvdata in data{
                                    if 1<csvdata.count{
                                        self.dao.insert_fromcsv(data: csvdata)
                                    }
                                }
                                self.selectedSrch = "全て"
                                self.search()
                                self.books = self.dao.distinct(field_name: "book")
                                self.stages = self.dao.distinct_onBook(field_name: "stage", book: self.selectedBook)
                                self.pages = self.dao.distinct_onStageBook(field_name: "page", stage: self.selectedStage, book: self.selectedBook)
                            }
                        case .failure(let error):
                            print(error.localizedDescription)
                        }
                    }
                    onCancellation: {
                        print("cancell success")
                    }
                    Text("\(words.count) 件")
                    //Spacer()
                    Text("：")
                    //Spacer()
                    Button("検索", action: search)
                        .buttonBorderShape(.capsule)
                        .tint(.pink)
                        .buttonStyle(.borderedProminent)
                        .padding()
                    Picker(selection:$selectedSrch, label: Text("検索対象を選択")) {
                        ForEach (self.srchObjs, id: \.self) { obj in
                            Text(obj)
                        }
                    }.pickerStyle(.menu)
                        .clipped()
                        .contentShape(Rectangle())
                        .onChange(of: self.selectedBook) { }
                }
                HStack{
                    Spacer()
                    Picker(selection:$selectedBook, label: Text("本を選択")) {
                        ForEach (self.books, id: \.self) { book in
                            Text(book)
                        }
                    }.pickerStyle(.menu)
                        .clipped()
                        .contentShape(Rectangle())
                        .onChange(of: self.selectedBook) {
                            self.selectedSrch = "本で"
                            self.search()
                            self.stages = self.dao.distinct_onBook(field_name: "stage", book: self.selectedBook)
                            self.pages = self.dao.distinct_onStageBook(field_name: "page", stage: self.selectedStage, book: self.selectedBook)
                        }
                    Spacer()
                    Text("章")
                    Picker(selection:$selectedStage, label: Text("章(Stage)を選択")) {
                        ForEach (self.stages, id: \.self) { stage in
                            Text(stage)
                        }
                    }.pickerStyle(.menu)
                        .clipped()
                        .contentShape(Rectangle())
                        .onChange(of: self.selectedStage) {
                            self.selectedSrch = "章で"
                            self.search()
                            self.pages = self.dao.distinct_onStageBook(field_name: "page", stage: self.selectedStage, book: self.selectedBook)
                        }
                    Spacer()
                    Text("頁")
                    Picker(selection:$selectedPage, label: Text("頁を選択")) {
                        ForEach (self.pages, id: \.self) { page in
                            Text(page)
                        }
                    }.pickerStyle(.menu)
                        .clipped()
                        .contentShape(Rectangle())
                        .onChange(of: self.selectedPage) {
                            self.selectedSrch = "頁で"
                            self.search()
                        }
                    Spacer()
                }
                Spacer()
                HStack{
                    Spacer()
                    Button(action: {
                        if words.count != 0 {
                            self.connector.selectedSrch = self.selectedSrch
                            self.connector.current = 0
                            self.connector.request = 0
                            _ = self.connector.getCurrent()
                        }
                    }, label: {
                        Image(systemName: "applewatch.and.arrow.forward")
                            .frame(width: 50, height: 50)
                    })
                    .padding()
                    .accentColor(Color.white)
                    .background(Color(red: 30/255, green: 150/255, blue: 234/255))
                    .font(.system(size: 30))
                    .cornerRadius(50)
                }
                .padding()
                Spacer()
            }.frame(maxHeight: .infinity)
            .navigationTitle("WatchEWord App")
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

class WatchConnector: NSObject, ObservableObject, WCSessionDelegate {
    
    @Published var receivedMessage = "WATCH: 未受信"
    @Published var request = 0
    @Published var sendStr = ""
    @Published var strArray:[String] = []
    @Published var current = 0
    @Published var selectedSrch = ""
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func getCurrent() -> [String] {
        if self.request == -1 {
            if 0 < self.current {
                self.current -= 1
            }
        } else if self.request == +1 {
            if self.current < words.count-1 {
                self.current += 1
            }
        }
        var lst:[String] = []
        if 0 <= self.current && self.current <= words.count-1 {
            lst.append(String(self.current))
            lst.append(String(words.count))
            lst.append(words[self.current].word)
            lst.append(words[self.current].mean)
            lst.append(String(words[self.current].seq))
            lst.append(words[self.current].type)
            lst.append(words[self.current].book)
            lst.append(words[self.current].stage)
            lst.append(String(words[self.current].page))
        }
        self.strArray = lst
        self.send()
        return lst
    }
    
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        print("activationDidCompleteWith state= \(activationState.rawValue)")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("sessionDidBecomeInactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("sessionDidDeactivate")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        print("didReceiveMessage: \(message)")
        DispatchQueue.main.async {
            self.receivedMessage = "WATCH : \(message["WATCH_REQ"] as! Int)"
            self.request = message["WATCH_REQ"] as! Int
            _ = self.getCurrent()
        }
    }
    
    func send() {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(["PHONE_RES" : strArray], replyHandler: nil)
        }
    }
}

#Preview {
    ContentView()
}
