//
//  ContentView.swift
//  HelloECompoMac
//
//  Created by 的池秋成 on 2024/10/17.
//
//
//  ContentView.swift
//  HelloECompo
//
//  Created by 的池秋成 on 2024/10/15.
//

import SwiftUI
import SQLite3

//
// https://swappli.com/fileimporter1/
// https://swiftwithmajid.com/2023/05/10/file-importing-and-exporting-in-swiftui/
//
import UniformTypeIdentifiers

struct SmpFileDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    static var writableContentTypes: [UTType] { [.plainText] }

    var text: String

    init(text: String = "") {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(data: data, encoding: .utf8) ?? ""
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8) ?? Data()
        return FileWrapper(regularFileWithContents: data)
    }
}
/*
struct FileImporterSmp: View {
    // https://swappli.com/fileimporter1/
    @State private var text = ""
    @State private var importFile: Bool = false
    
    var body: some View {
        TextField("ファイルの内容", text: $text)
        
        //インポートボタン
        Button("Inport File") {
            // ファイルをインポートするロジックを実装する
            importFile = true
        }
        .fileImporter(isPresented: $importFile,
                      allowedContentTypes: [.plainText],
                      allowsMultipleSelection: false
                      
        ) { result in
            switch result {
            case .success(let directory):
                directory.forEach { file in
                    // アクセス権取得
                    let gotAccess = file.startAccessingSecurityScopedResource()
                    if !gotAccess { return }
                    
                    // ファイルの内容を取得する
                    do {
                        text = try String(contentsOf: file)
                    } catch {
                        print(error.localizedDescription)
                    }
                    print(text)
                    
                    // アクセス権解放
                    file.stopAccessingSecurityScopedResource()
               }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
        onCancellation: {
            print("cancell success")
        }
    }
}

struct FileExporterSmp: View {
    // https://swappli.com/fileexporter/
    @State private var text = ""
    @State private var exportFile: Bool = false
    
    var body: some View {
        TextField("ファイルの内容", text: $text)
        
        //エクスポートボタン
        Button("Export File") {
            // ファイルをエクスポートするロジックを実装する
            exportFile = true
        }
        .fileExporter(
            isPresented: $exportFile,
            document: SmpFileDocument(text: text),
            contentTypes: [.plainText],
            defaultFilename: "DefaultName"
        ) { result in
            // エクスポートの完了時に実行されるコードを定義する
            switch result {
            case .success:
                print("Export success")
            case .failure:
                print("Export failed")
            }
        }
        onCancellation: {
            print("cancel success")
        }
    }
}
*/

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

struct Record{
    var id: Int
    var eibun: String
    var wabun: String
    var hint: String
    var line: Int
    var page: Int
    var chap: Int
    var title: String
    var topic: String
    var field: String
    var book: String
    var description: String
}

nonisolated(unsafe) var records = [Record]()

class DAO:SQLite3{
    let table_name:String = "ecompo"
    func initial(){
        let rootDirectory = NSHomeDirectory() + "/Documents"
        open(path: rootDirectory+"/ecompo_sqlite3")
        //drop_table()
        //create_table()
        print("dao!->",rootDirectory+"/ecompo_sqlite3")
    }
    func drop_table(){
        let sql = "DROP TABLE \(table_name)"
        exec(sql)
    }
    func create_table(){
        let sql = ("CREATE TABLE \(table_name) (id integer primary key autoincrement unique,eibun text,wabun text,hint text,line integer,page integer,chap integer, title text,topic text,field text,book text,description text)")
        exec(sql)
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
        //print("=>", data.count, data)
        insert(data: data)
        /*
        prepare("INSERT INTO \(table_name) (eibun, wabun, hint, line, page, chap, title, topic, field, book, description) VALUES (?,?,?,?,?,?,?,?,?,?,?)")
        for i in 1..<12{
            if (3<i)&&(i<7){
                //print("=>", i, data[i+1])
                bindInt(index: i, value: Int(data[i])!)
            }else{
                bindText(index: i, value: String(data[i]))
            }
        }
        if step() != SQLITE_DONE {
            print("error: INSERT csv")
        }
        resetStatement()
        */
    }
    func insert(data:[String]){
        prepare("INSERT INTO \(table_name) (eibun, wabun, hint, line, page, chap, title, topic, field, book, description) VALUES (?,?,?,?,?,?,?,?,?,?,?)")
        for i in 1..<12{
            if (3<i)&&(i<7){
                bindInt(index: i, value: Int(data[i])!)
            }else{
                bindText(index: i, value: String(data[i]))
            }
        }
        if step() != SQLITE_DONE {
            print("error: INSERT")
        }
        resetStatement()
    }
    func update(data:[String], id:Int){
        prepare("UPDATE \(table_name) SET eibun=?, wabun=?, hint=?, line=?, page=?, chap=?, title=?, topic=?, field=?, book=?, description=? WHERE id=?")
        for i in 1..<12{
            if (3<i)&&(i<7){
                bindInt(index: i, value: Int(data[i])!)
            }else{
                bindText(index: i, value: String(data[i]))
            }
        }
        bindInt(index: 12, value: id)
        if step() != SQLITE_DONE {
            print("error: UPDATE")
        }
        resetStatement()
    }
    func append_record(){
        while step() == SQLITE_ROW {
            let id = columnInt(index: 0)
            let eibun = columnText(index: 1)
            let wabun = columnText(index: 2)
            let hint = columnText(index: 3)
            let line = columnInt(index: 4)
            let page = columnInt(index: 5)
            let chap = columnInt(index: 6)
            let title = columnText(index: 7)
            let topic = columnText(index: 8)
            let field = columnText(index: 9)
            let book = columnText(index: 10)
            let description = columnText(index: 11)
            records.append(Record(id:id, eibun:eibun, wabun:wabun, hint:hint, line:line, page:page, chap:chap, title:title, topic:topic, field:field, book:book, description:description))
            //print("IntField:\(id), TextField:\(eibun)")
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
    func distinct_book(book_name: String, field_name: String) -> [String]{
        let sql = "SELECT DISTINCT \(field_name) FROM \(table_name) WHERE book=? ORDER BY \(field_name) ASC"
        prepare(sql)
        bindText(index: 1, value: book_name)
        var list = [String]()
        while step() == SQLITE_ROW {
            list.append(columnText(index: 0))
        }
        resetStatement()
        return list
    }
    func select_all(){
        records.removeAll()
        prepare("SELECT * FROM \(table_name) ORDER BY book ASC, chap ASC, page ASC, line ASC")
        append_record()
        if step() != SQLITE_DONE {
            print("error: SELECT")
        }
        resetStatement()
    }
    func select_book(book:String){
        records.removeAll()
        prepare("SELECT * FROM \(table_name) WHERE book = ? ORDER BY book ASC, chap ASC, page ASC, line ASC")
        bindText(index: 1, value: book)
        append_record()
        if step() != SQLITE_DONE {
            print("error: SELECT")
        }
        resetStatement()
    }
    func select_book_chap(book:String, chap:Int){
        records.removeAll()
        prepare("SELECT * FROM \(table_name) WHERE book = ? AND chap = ? ORDER BY book ASC, chap ASC, page ASC, line ASC")
        bindText(index: 1, value: book)
        bindInt(index: 2, value: chap)
        append_record()
        if step() != SQLITE_DONE {
            print("error: SELECT")
        }
        resetStatement()
    }
    func select_book_page(book:String, page:Int){
        records.removeAll()
        prepare("SELECT * FROM \(table_name) WHERE book = ? AND page = ? ORDER BY book ASC, chap ASC, page ASC, line ASC")
        bindText(index: 1, value: book)
        bindInt(index: 2, value: page)
        append_record()
        if step() != SQLITE_DONE {
            print("error: SELECT")
        }
        resetStatement()
    }
    func select_book_field(book:String, field:String){
        records.removeAll()
        let sql = "SELECT * FROM \(table_name) WHERE book = ? AND field = ? ORDER BY book ASC, chap ASC, page ASC, line ASC"
        prepare(sql)
        bindText(index: 1, value: book)
        bindText(index: 2, value: field)
        append_record()
        if step() != SQLITE_DONE {
            print("error: SELECT")
        }
        resetStatement()
    }
    func select_book_topic(book:String, topic:String){
        records.removeAll()
        prepare("SELECT * FROM \(table_name) WHERE book = ? AND topic = ? ORDER BY book ASC, chap ASC, page ASC, line ASC")
        bindText(index: 1, value: book)
        bindText(index: 2, value: topic)
        append_record()
        if step() != SQLITE_DONE {
            print("error: SELECT")
        }
        resetStatement()
    }
    func select_book_title(book:String, title:String){
        records.removeAll()
        prepare("SELECT * FROM \(table_name) WHERE book = ? AND title = ? ORDER BY book ASC, chap ASC, page ASC, line ASC")
        bindText(index: 1, value: book)
        bindText(index: 2, value: title)
        append_record()
        if step() != SQLITE_DONE {
            print("error: SELECT")
        }
        resetStatement()
    }

}
/*
extension String {
    var csvEscaped: String {
        struct My {
            static let specials = CharacterSet(charactersIn: ", \r\n\t\"")
        }
        return self.unicodeScalars.contains{My.specials.contains($0)}
            ? "\"" + self.replacingOccurrences(of: "\"", with: "\"\"") + "\""
            : self
    }
}
*/
class CSV{

    var fname = "ECompoData"
    init(fname: String = "ECompoData"){
        self.fname = fname
    }
    func getFName() -> String {
        return self.fname+".csv"
    }

    func CSVDataGen() -> String{
        // heading of CSV file.
        let heading = "ID,英文,和文,ヒント,行,頁,章,題目,主題,分野,本,備考 \n"
        // file rows
        //id, eibun, wabun, hint, line, page, chap, title, topic, field, book, description
        let rows = records.map { "\($0.id),\"\($0.eibun)\",\"\($0.wabun)\",\"\($0.hint)\",\($0.line),\($0.page),\($0.chap),\"\($0.title)\",\"\($0.topic)\",\"\($0.field)\",\($0.book),\"\($0.description)\"" }
        // rows to string data
        let stringData = heading + rows.joined(separator: "\n")
        return stringData
    }
    
    func generateCSV() -> URL {
        var fileURL: URL!
        let stringData = CSVDataGen()
        do {
            let path = try FileManager.default.url(for: .documentDirectory,
                                                   in: .allDomainsMask,
                                                   appropriateFor: nil,
                                                   create: false)
            fileURL = path.appendingPathComponent("ECompoData.csv")
            // append string data to file
            try stringData.write(to: fileURL, atomically: true , encoding: .utf8)
            print(fileURL!)
        } catch {
            print("error : generating csv file")
        }
        return fileURL
    }
    /* Generate csv */
    
    func fileContents(file: URL) -> String{
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
                if 12==csvdata.count{
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

class JSONRW {
    struct Book: Codable {
        let book: String
        let field: String
        let topic: String
        let title: String
        let page: Int
        let line: Int
        let wabun: String
        let eibun: String
    }
    var books = [
        Book(book:"",field:"",topic:"",title:"",page:0,line:0,wabun:"",eibun:""),
        Book(book:"",field:"",topic:"",title:"",page:0,line:0,wabun:"",eibun:"")
    ]
    func initial(){
        books = []
    }
    func jsonwrite(){
        jsonwrite(books:books)
    }
    func jsonwrite(books: [Book]){
        let encoder = JSONEncoder()
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        if let documentsDirectory = urls.first {
            let fileURL = documentsDirectory.appendingPathComponent("output.json")
            do{
                let jsonData = try encoder.encode(books)
                try jsonData.write(to: fileURL)
                print("保存成功： \(fileURL.path)")
            }catch {
                print("保存エラー： \(error)")
            }
        }
    }
    func booksappend(book:String,field:String,topic:String,title:String,page:Int,line:Int,wabun:String,eibun:String) {
        let b = Book(book:book,field:field,topic:topic,title:title,page:page,line:line,wabun:wabun,eibun:eibun)
        books.append(b)
    }
    func jsongen(sort: String){
        jsongen(books: books, sort:sort)
    }
    func jsongen(books: [Book], sort: String){
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(books)
            if String(data: jsonData, encoding: .utf8) != nil {
                jsonwrite()
                //writeToFile(text: jsonString)
            }
            let cmdlineargs=["eisaku", sort]
            print( do_python(cmdlnargs: cmdlineargs) )
        } catch {
            print("JSONエンコードに失敗しました： \(error)")
        }
    }
    func do_python(cmdlnargs: [String]) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        let path: String = "/Users/mat/Documents/PycharmProjects/json2tex/"
        var strArray:[String] = [path + "do0.sh"]
        strArray.append(contentsOf: cmdlnargs)
        process.arguments = strArray
        let pipe = Pipe()
        process.standardOutput = pipe
        var output: String = ""
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            output = String(data: data, encoding: .utf8) ?? ""
            //print("Python script output: \(output)")
        } catch {
            print("Error: \(error.localizedDescription)")
            output = error.localizedDescription
        }
        return output
    }
/*
    func dicttype(){
        let dict: [String: Any] = [
            "book": "",
            "field": "",
            "topic": "",
            "title": "",
            "page": 0,
            "line": 0,
            "wabun": "",
            "eibun": ""
        ]
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8){
                writeToFile(text: jsonString)
            }
        } catch {
            print("辞書をJSONに変換できません： \(error)")
        }
    }
    
    func writeToFile(text: String) {
            /// ①DocumentsフォルダURL取得
            guard let dirURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                fatalError("フォルダURL取得エラー")
            }
            /// ②対象のファイルURL取得
            let fileURL = dirURL.appendingPathComponent("output.json")
            /// ③ファイルの書き込み
            do {
                try text.write(to: fileURL, atomically: true, encoding: .utf8)
            } catch {
                print("Error: \(error)")
            }
    }
    
    func readFromFile() -> String {
            /// ①DocumentsフォルダURL取得
            guard let dirURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                fatalError("フォルダURL取得エラー")
            }
            /// ②対象のファイルURL取得
            let fileURL = dirURL.appendingPathComponent("output.json")
            /// ③ファイルの読み込み
            guard let fileContents = try? String(contentsOf: fileURL, encoding: .utf8) else {
                fatalError("ファイル読み込みエラー")
            }
            /// ④読み込んだ内容を戻り値として返す
            return fileContents
    }
*/
}
//GeometryReader { geometry in
//    Text("Width: \(geometry.size.width)")
//}

struct ContentView: View {
    let dao = DAO()
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
    @State private var isEibun: Bool = true
    @State private var isHint: Bool = true
    @State private var book: String = ""
    @State private var selectedBook: String = "準1級：完全制覇"
    @State private var selectedField: String = ""
    @State private var selectedTopic: String = ""
    @State private var selectedTitle: String = ""
    @State private var selectedSearch: String = "本"
    @State private var current = 0
    @State private var sizeofRecords = 0
    @State private var new_save: String = "New"
    @State private var isSave: Bool = false
    @State private var edit_update: String = "Edit"
    @State private var isUpdate: Bool = false
    @State private var isDelete: Bool = false
    @State private var exportFile: Bool = false
    @State private var importFile: Bool = false
    @State private var isDisable: Bool = false
    //@State private var isVisible: Bool = true
    @State private var text: String = ""
    @State private var stringData: String = ""
    @State private var csvIOoption = ""
    @State private var csvData: [[String]] = []
    private let options = ["CSVから入力","CSVへ出力","問題(分野別)","問題(話題別)"]
    private let searchObjs = ["全","本","分野","話題","題目","頁"]
    //@State private var Books = ["1級完全制覇", "1級文単", "準1級完全制覇", "準1級文単", "入試問題精講"]
    @State private var Books = [""]
    @State private var Titles = [""]
    @State private var Topics = [""]
    @State private var Fields = [""]

    init(){
        self.dao.initial()
        dao.select_all()
        current = 0
        sizeofRecords = records.count
        Books = dao.distinct(field_name: "book")
        Fields = dao.distinct(field_name: "field")
        Topics = dao.distinct(field_name: "topic")
        Titles = dao.distinct(field_name: "title")
        //show_current(current: current)
    }

    func reshape(lineArray:[String]){
        var csvdata: [String] = []
        var str: String = ""
        var flag: Bool = false
        for line in lineArray {
            let dataArray: [String] = line.components(separatedBy: ",")
            if(dataArray[1]=="英文"){continue}
            for data in dataArray{
                if data=="\"" {
                    if flag==false{
                        flag=true
                    }else{
                        csvdata.append(str.replacingOccurrences(of:"\"", with:""))
                        flag = false
                    }
                } else if (!data.hasPrefix("\"")&&(!data.hasSuffix("\""))){
                    if flag {
                        if str.isEmpty {
                            str = data
                        }else{
                            str = str + "\n" + data
                        }
                    }else{
                        csvdata.append(data.replacingOccurrences(of:"\"", with:""))
                    }
                }else if (data.hasPrefix("\"")&&(data.hasSuffix("\""))){
                    csvdata.append(data.replacingOccurrences(of:"\"", with:""))
                }else if (data.hasPrefix("\"")&&(!data.hasSuffix("\""))){
                    str = data
                    flag = true
                }else if ((!data.hasPrefix("\""))&&(data.hasSuffix("\""))){
                    if str.isEmpty {
                        str = data
                    }else{
                        str = str + "\n" + data
                    }
                    csvdata.append(str.replacingOccurrences(of:"\"", with:""))
                    flag = false
                }
                if csvdata[0]==""{
                    csvdata.removeFirst()
                }
                if 12==csvdata.count{
                    print("->",csvdata)
                    dao.insert_fromcsv(data: csvdata)
                    csvdata.removeAll()
                }
            }
        }
    }
    func clear_fields(){
        line = "0"
        page = "0"
        chap = "0"
        field = ""
        topic = ""
        title = ""
        wabun = ""
        eibun = ""
        hint = ""
        description = ""
    }
    func show_current(current:Int){
        //id, eibun, wabun, hint, line, page, chap, title, topic, field, book, description
        id = records[current].id
        eibun = records[current].eibun
        wabun = records[current].wabun
        hint = records[current].hint
        line = String(records[current].line)
        page = String(records[current].page)
        chap = String(records[current].chap)
        title = records[current].title
        topic = records[current].topic
        field = records[current].field
        selectedBook = records[current].book
        selectedField = field
        selectedTopic = topic
        selectedTitle = title
        description = records[current].description
        sizeofRecords = records.count
        Books = dao.distinct(field_name: "book")
        Titles = dao.distinct_book(book_name: selectedBook, field_name: "title")
        Topics = dao.distinct_book(book_name: selectedBook, field_name: "topic")
        Fields = dao.distinct_book(book_name: selectedBook, field_name: "field")
    }
    func setData() -> [String]{
        var data = [String]()
        data.append(String(id))
        data.append(eibun)
        data.append(wabun)
        data.append(hint)
        data.append(String(line))
        data.append(String(page))
        data.append(String(chap))
        data.append(title)
        data.append(topic)
        data.append(field)
        data.append(book)
        data.append(description)
        return data
    }
    func okActionUpdate(){
        let data = setData()
        dao.update(data: data, id:id)
        edit_update = "Edit"
        new_save = "New"
        isUpdate = false
    }
    func okActionSave(){
        let data = setData()
        dao.insert(data: data)
        new_save = "New"
        edit_update = "Edit"
        isSave = false
    }
    func okActionDelete(){
        self.dao.delete(id:id)
        isDelete = false
    }
    
    func pickRandomNumbers(from num:Int, count: Int = 10) -> [Int] {
        let numbers = Array(0..<num)
        //guard num >= count else {
            //numbers = Array(0..)
            //return []
        //}
        let shuffled = numbers.shuffled()
        let selected = Array(shuffled.prefix(count))
        return selected
    }
    func okActionPrintRandom(sort:String){
        if sort=="field" {
            self.dao.select_book_field(book: selectedBook, field: selectedField)
        }else{
            self.dao.select_book_topic(book: selectedBook, topic: selectedTopic)
        }
        let num_of_records=records.count
        let randomNumbers = pickRandomNumbers(from: num_of_records)
        myjson.initial()
        for n in randomNumbers {
            myjson.booksappend(
                book:records[n].book,
                field:records[n].field,
                topic:records[n].topic,
                title:records[n].title,
                page:records[n].page,
                line:records[n].line,
                wabun:records[n].wabun,
                eibun:records[n].eibun
            )
            print("Debug:",records[n].id, records[n].wabun)
        }
        myjson.jsongen(sort:sort)
        printAlert1 = false
        printAlert2 = false
    }
    
    func okActionPrintAll(sort:String){
        if sort=="field" {
            self.dao.select_book_field(book: selectedBook, field: selectedField)
        }else{
            self.dao.select_book_topic(book: selectedBook, topic: selectedTopic)
        }
        let num_of_records=records.count
        //let randomNumbers = pickRandomNumbers(from: num_of_records, count: num_of_records)
        myjson.initial()
        for n in 0 ..< num_of_records {
            myjson.booksappend(
                book:records[n].book,
                field:records[n].field,
                topic:records[n].topic,
                title:records[n].title,
                page:records[n].page,
                line:records[n].line,
                wabun:records[n].wabun,
                eibun:records[n].eibun
            )
            print("Debug",records[n].id, records[n].wabun)
        }
        myjson.jsongen(sort:sort)
        printAlert1 = false
        printAlert2 = false
    }
    func nothankyou(){
        printAlert1 = false
        printAlert2 = false
    }
    @State private var showAlert = false
    @State private var importedData: [[String]] = []
    @State private var yesnoflag = false
    @State private var printAlert1 = false
    @State private var printAlert2 = false

    func yesaction() {
        yesnoflag = false
        print("Yes selected")
    }

    func noaction() {
        yesnoflag = true
        print("No selected")
    }

    func processCSV() {
        if !yesnoflag {
            dao.close()
            dao.initial()
            dao.drop_table()
            dao.create_table()
        }
        for csvdata in importedData {
            if csvdata.count > 1 {
                dao.insert_fromcsv(data: csvdata)
            }
        }
        dao.select_all()
        current = 0
        sizeofRecords = records.count
        Books = dao.distinct(field_name: "book")
        Fields = dao.distinct(field_name: "field")
        Topics = dao.distinct(field_name: "topic")
        Titles = dao.distinct(field_name: "title")
        show_current(current: current)
    }
        
    var body: some View {
        VStack(alignment: .center){
            VStack(alignment: .center){
                HStack{
                    Spacer()
                    Button("|<<") {
                        current = 0
                        show_current(current:current)
                    }.buttonStyle(.bordered)
                    Spacer()
                    Button("<") {
                        if 0<current{
                            current -= 1
                        }
                        show_current(current:current)
                    }.buttonStyle(.bordered)
                    Spacer()
                    Text(String(current+1)+"/"+String(sizeofRecords))
                    Spacer()
                    Button(">") {
                        if current<records.count-1{
                            current += 1
                        }
                        show_current(current:current)
                    }.buttonStyle(.bordered)
                    Spacer()
                    Button(">>|") {
                        current = records.count-1
                        show_current(current:current)
                    }.buttonStyle(.bordered)
                    Spacer()
                    Menu{
                        // https://swappli.com/menu-picker/
                        Picker("選択", selection: $csvIOoption){
                            ForEach(options, id: \.self){ option in Text(option) }
                        }.pickerStyle(.inline)
                    } label: {
                        //Text("CSV:")
                        Image(systemName: "gearshape").symbolRenderingMode(.monochrome)
                        //icon: do { Image(uiImage: ImageRenderer(content: Text("🏠")).uiImage!) }
                    }
                    if(csvIOoption=="CSVへ出力"){
                        Button(csvIOoption) {
                            // ファイルをエクスポートするロジックを実装する
                            stringData = csv.CSVDataGen()
                            exportFile = true
                            importFile = false
                        }
                        .fileExporter(
                            isPresented: $exportFile,
                            document: SmpFileDocument(text: stringData),
                            contentTypes: [.plainText],
                            defaultFilename: csv.getFName()
                        ) { result in
                            // エクスポートの完了時に実行されるコードを定義する
                            switch result {
                            case .success(let file):
                                print(file.absoluteString)
                            case .failure(let error):
                                print(error)
                            }
                        }
                        onCancellation: {
                            print("cancel success")
                        }
                    }else if(csvIOoption=="CSVから入力"){
                        Button(csvIOoption) {
                            // ファイルをインポートするロジックを実装する
                            importFile = true
                            exportFile = false
                        }.buttonBorderShape(.capsule)
                            .fileImporter(
                                isPresented: $importFile,
                                allowedContentTypes: [.plainText],
                                allowsMultipleSelection: false
                            ) { result in
                                switch result {
                                case .success(let files):
                                    guard let file = files.first else { return }
                                    // 仮の reshape 読み込み処理
                                    let data: [[String]] = csv.reshape(url: file)
                                    self.importedData = data
                                    self.showAlert = true  // -> アラート表示トリガー

                                case .failure(let error):
                                    print("Import error: \(error.localizedDescription)")
                                }
                            }
                            .alert("New or Append", isPresented: $showAlert) {
                                Button("Yes") {
                                    yesaction()
                                    processCSV()
                                }
                                Button("No", role: .cancel) {
                                    noaction()
                                    processCSV()
                                }
                            } message: {
                                Text("DBを作り直しますか？")
                            }
                    }else if(csvIOoption=="問題(分野別)"){
                        Button("問題(分野別)"){printAlert1=true}
                            .alert("Print Random or All ?", isPresented: $printAlert1) {
                            Button("Random(10)") {
                                okActionPrintRandom(sort:"field")
                            }
                            Button("Sequential(All)") {
                                okActionPrintAll(sort:"field")
                            }
                            Button("No, Thank you", role: .cancel) {
                                nothankyou()
                            }
                        } message: {
                            Text("試験問題(分野別)生成しますか？")
                        }
                    }else if(csvIOoption=="問題(話題別)"){
                        Button("問題(話題別)"){printAlert2=true}
                            .alert("Print Random or All ?", isPresented: $printAlert2) {
                            Button("Random(10)") {
                                okActionPrintRandom(sort:"topic")
                            }
                            Button("Sequential(All)") {
                                okActionPrintAll(sort:"topic")
                            }
                            Button("No, Thank you", role: .cancel) {
                                nothankyou()
                            }
                        } message: {
                            Text("試験問題(話題別)生成しますか？")
                        }
                    }
                    
                    Spacer()
                }//.padding()
                HStack{
                    Button("検索") {
                        var book:String = ""
                        book = selectedBook
                        if selectedSearch==searchObjs[0] {
                            self.dao.select_all()
                        }else if selectedSearch==searchObjs[1] {
                            self.dao.select_book(book: selectedBook)
                        }else if selectedSearch==searchObjs[2] {
                            self.dao.select_book_field(book: selectedBook, field: selectedField)
                        }else if selectedSearch==searchObjs[3] {
                            self.dao.select_book_topic(book: selectedBook, topic: selectedTopic)
                        }else if selectedSearch==searchObjs[4] {
                            self.dao.select_book_title(book: selectedBook, title: selectedTitle)
                        }else if selectedSearch==searchObjs[5] {
                            self.dao.select_book_page(book: book, page: Int(page)!)
                        }
                        if records.count>0{
                            current=0
                            show_current(current:current)
                        }else if records.count==0{
                            records.removeAll()
                            current = 0
                            sizeofRecords = 0
                            clear_fields()
                        }
                        selectedBook = book
                        new_save = "New"
                        edit_update = "Edit"
                    }.buttonStyle(.bordered)
                    //Spacer()
                    Picker(selection:$selectedSearch, label: Text("検索")) {
                        ForEach (searchObjs, id: \.self) {
                            Text($0)
                        }
                    }.pickerStyle(.menu)
                        .frame(width:155)
                        .clipped()
                        .contentShape(Rectangle())
                    Button( new_save ) {
                        if new_save=="New" {
                            clear_fields()
                            new_save = "Save"
                        } else if new_save=="Save" {
                            isSave = true
                        }
                    }.buttonStyle(.bordered)
                        .alert(isPresented: $isSave){
                            Alert(title:Text("Save?"), message: Text("id=new"+", sentence="+eibun),
                                  primaryButton:.default(Text("Ok"),action:{okActionSave()}),
                                  secondaryButton:.cancel(Text("Cancel"), action:{}))
                        }
                    //Spacer()
                    Button(edit_update) {
                        if edit_update=="Edit"{
                            edit_update = "Updt"
                            new_save = "Save"
                            book=selectedBook
                            field=selectedField
                            topic=selectedTopic
                            title=selectedTitle
                        } else if edit_update=="Updt"{
                            isUpdate = true
                        }
                    }.buttonStyle(.bordered)
                        .alert(isPresented: $isUpdate){
                            Alert(title:Text("Update?"), message: Text("id="+String(id)+", sentence="+eibun),
                                  primaryButton:.default(Text("Ok"),action:{okActionUpdate()}),
                                  secondaryButton:.cancel(Text("Cancel"), action:{}))
                        }
                    //Spacer()
                    Button("Del") {
                        isDelete = true
                    }.buttonStyle(.bordered)
                        .alert(isPresented: $isDelete){
                            Alert(title:Text("Delete?"), message: Text("id="+String(id)+",sentence="+eibun),
                                  primaryButton:.default(Text("Ok"),action:{okActionDelete()}),
                                  secondaryButton:.cancel(Text("Cancel"), action:{}))
                        }
                }//.padding()
                HStack{
                    Text("行")
                    ZStack{
                        TextField("999", text: $line)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 46)
                            .border(Color.gray)
                            //.keyboardType(.numberPad)
                            //.multilineTextAlignment(.trailing)
                            //.focused($focusedField, equals: .line)
                            //.foregroundColor(.primary)
                            //.background(Color(UIColor.systemGray6))
                    }//.frame(width: UIScreen.main.bounds.width,height: UIScreen.main.bounds.height)
                    .contentShape(RoundedRectangle(cornerRadius: 10))
                    .onTapGesture {
                        focusedField = nil
                    }
                    Text("頁")
                    ZStack{
                    TextField("999", text: $page)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 46)
                        .border(Color.gray)
                        //.keyboardType(.numberPad)
                        //.multilineTextAlignment(.trailing)
                        //.focused($focusedField, equals: .page)
                        //.foregroundColor(.primary)
                        //.background(Color(UIColor.systemGray6))
                    }//.frame(width: UIScreen.main.bounds.width,height: UIScreen.main.bounds.height)
                    .contentShape(RoundedRectangle(cornerRadius: 10))
                    .onTapGesture {
                        focusedField = nil
                    }
                    /*
                    Text("章")
                    TextField("999", text: $chap)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 46)
                        .border(Color.gray)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                    */
                    if (new_save=="Save")||(edit_update=="Updt"){
                        //book = selectedBook
                        Text("本")
                        TextField("本", text: $book, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .border(Color.gray)
                            //.autocapitalization(.none)
                            //.keyboardType(.default)
                            .disableAutocorrection(true)
                    }else{
                        Picker(selection:$selectedBook, label: Text("本")) {
                            ForEach (Books, id: \.self) {
                                Text($0)
                            }
                        }.pickerStyle(.menu)
                            .frame(width: .infinity)
                            .clipped()
                            .contentShape(Rectangle())
                            .onChange(of: selectedBook) { newValue in
                                if newValue.isEmpty {
                                    isDisable = true
                                } else {
                                    self.dao.select_book(book: selectedBook)
                                    if records.count>0{
                                        current=0
                                        show_current(current:current)
                                    }else if records.count==0{
                                        records.removeAll()
                                        current = 0
                                        sizeofRecords = 0
                                        clear_fields()
                                    }
                                    isDisable = false
                                }
                            }
                    }
                }//.padding()
                VStack{
                    HStack{
                        //Text("分野")
                        if (new_save=="Save")||(edit_update=="Updt"){
                            //field = selectedField
                            TextField("分野", text: $field, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .border(Color.gray)
                                //.autocapitalization(.none)
                                //.keyboardType(.default)
                                .disableAutocorrection(true)
                             
                        }else{
                            Picker(selection:$selectedField, label: Text("分野")) {
                                ForEach (Fields, id: \.self) {
                                    Text($0).font(.subheadline)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: .infinity, height: 38)
                            .clipped()
                            .contentShape(Rectangle())
                        }
                   }//.padding()
                    HStack{
                        //Text("話題")
                        if (new_save=="Save")||(edit_update=="Updt"){
                            //topic = selectedTopic
                            TextField("話題", text: $topic, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .border(Color.gray)
                                //.autocapitalization(.none)
                                //.keyboardType(.default)
                                .disableAutocorrection(true)
                        }else{
                            Picker(selection:$selectedTopic, label: Text("話題")) {
                                ForEach (Topics, id: \.self) {
                                    Text($0).font(.subheadline)
                                }
                            }.pickerStyle(.menu)
                                .frame(width: .infinity, height: 38)
                                .clipped()
                                .contentShape(Rectangle())
                        }
                    }//.padding()
                    HStack{
                        //Text("題目")
                        if (new_save=="Save")||(edit_update=="Updt"){
                            //title = selectedTitle
                            TextField("題目", text: $title, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .border(Color.gray)
                                //.autocapitalization(.none)
                                //.keyboardType(.default)
                                .disableAutocorrection(true)
                        }else{
                            Picker(selection:$selectedTitle, label: Text("題目")) {
                                ForEach (Titles, id: \.self) {
                                    Text($0).font(.subheadline)
                                }
                            }.pickerStyle(.menu)
                                .frame(width: .infinity, height: 38)
                                .clipped()
                                .contentShape(Rectangle())
                        }
                    }//.padding()
                }.padding()
                Divider()
                //Spacer()
            }
            Spacer()
            ZStack{
                VStack() {
                    //Spacer()
                    HStack{
                        GeometryReader { geometry in
                            HStack {
                                Text("和文")
                                // 入力
                                TextEditor(text: $wabun)
                                    .frame(width: geometry.size.width * 0.8, height: 160)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.blue, lineWidth: 1)
                                    ).font(.system(size: 15))
                                /*
                                // 表示
                                Text(wabun)
                                    .foregroundColor(.yellow)
                                    .lineLimit(nil)
                                    .padding(5)
                                    .frame(width: geometry.size.width * 0.8, height: 200, alignment: .topLeading)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.green, lineWidth: 5)
                                    )
                                */
                            }
                        }
                        /*
                        VStack{
                            Text("和文")
                            Toggle(isOn: $isWabun) {
                                let _ = isWabun = false
                            }.fixedSize()
                                .scaleEffect(0.5)
                        }//.padding()
                        if isWabun {
                            TextField("和文", text: $wabun, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .border(Color.gray)
                                //.autocapitalization(.none)
                                //.keyboardType(.default)
                                .disableAutocorrection(true)
                                .focused($focusedField, equals: .wabun)
                                .foregroundColor(.primary)
                                //.background(Color(UIColor.systemGray6))
                                .font(.system(size: 15))
                        } else {
                            TextField("和文", text: $wabun, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .border(Color.gray)
                                //.autocapitalization(.none)
                                //.keyboardType(.default)
                                .disableAutocorrection(true)
                                .focused($focusedField, equals: .wabun)
                                //.foregroundColor(Color(UIColor.systemGray6))
                                //.background(Color(UIColor.systemGray6))
                                .font(.system(size: 15))
                        }
                        */
                    }//.frame(width: UIScreen.main.bounds.width,height: UIScreen.main.bounds.height)
                    .contentShape(RoundedRectangle(cornerRadius: 10))
                    .onTapGesture {
                        focusedField = nil
                    }
                    HStack{
                        GeometryReader { geometry in
                            HStack {
                                Text("英文")
                                // 入力
                                TextEditor(text: $eibun)
                                    .frame(width: geometry.size.width * 0.8, height: 160)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.blue, lineWidth: 1)
                                    ).font(.system(size: 15))
                                /*
                                // 表示
                                Text(wabun)
                                    .foregroundColor(.yellow)
                                    .lineLimit(nil)
                                    .padding(5)
                                    .frame(width: geometry.size.width * 0.8, height: 200, alignment: .topLeading)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.green, lineWidth: 5)
                                    )
                                */
                            }
                        }

                        /*
                        VStack{
                            Text("英文")
                            Toggle(isOn: $isEibun) {
                                let _ = isEibun = false
                            }.fixedSize()
                                .scaleEffect(0.5)
                        }//.padding()
                        if isEibun {
                            TextField("英文", text: $eibun, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .border(Color.gray)
                                //.autocapitalization(.none)
                                //.keyboardType(.default)
                                .disableAutocorrection(true)
                                .focused($focusedField, equals: .eibun)
                                .foregroundColor(.primary)
                                //.background(Color(UIColor.systemGray6))
                                //.font(.system(size: 15))
                        } else {
                            TextField("英文", text: $eibun, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .border(Color.gray)
                                //.autocapitalization(.none)
                                //.keyboardType(.default)
                                .disableAutocorrection(true)
                                .focused($focusedField, equals: .eibun)
                                //.foregroundColor(Color(UIColor.systemGray6))
                                //.background(Color(UIColor.systemGray6))
                                .font(.system(size: 15))
                        }
                        */
                    }//.frame(width: UIScreen.main.bounds.width,height: UIScreen.main.bounds.height)
                    .contentShape(RoundedRectangle(cornerRadius: 10))
                    .onTapGesture {
                        focusedField = nil
                    }
                    HStack{
                        GeometryReader { geometry in
                            HStack {
                                Text("備考")
                                // 入力
                                TextEditor(text: $hint)
                                    .frame(width: geometry.size.width * 0.8, height: 160)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.blue, lineWidth: 1)
                                    ).font(.system(size: 15))
                                /*
                                // 表示
                                Text(wabun)
                                    .foregroundColor(.yellow)
                                    .lineLimit(nil)
                                    .padding(5)
                                    .frame(width: geometry.size.width * 0.8, height: 200, alignment: .topLeading)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.green, lineWidth: 5)
                                    )
                                */
                            }
                        }

                        /*
                        VStack{
                            Text("備考")
                            Toggle(isOn: $isHint) {
                                let _ = isHint = false
                            }.fixedSize()
                                .scaleEffect(0.5)
                        }//.padding()
                        if isHint {
                             TextField("備考", text: $hint, axis: .vertical)
                                 .textFieldStyle(RoundedBorderTextFieldStyle())
                                 .border(Color.gray)
                                 //.autocapitalization(.none)
                                 //.keyboardType(.default)
                                 .disableAutocorrection(true)
                                 .focused($focusedField, equals: .hint)
                                 .foregroundColor(.primary)
                                 //.background(Color(UIColor.systemGray6))
                                 .font(.system(size: 15))
                        } else {
                             TextField("備考", text: $hint, axis: .vertical)
                                 .textFieldStyle(RoundedBorderTextFieldStyle())
                                 .border(Color.gray)
                                 //.autocapitalization(.none)
                                 //.keyboardType(.default)
                                 .disableAutocorrection(true)
                                 .focused($focusedField, equals: .hint)
                                 //.foregroundColor(Color(UIColor.systemGray6))
                                 //.background(Color(UIColor.systemGray6))
                                 .font(.system(size: 15))
                        }
                        */
                    }//.frame(width: UIScreen.main.bounds.width,height: UIScreen.main.bounds.height)
                    .contentShape(RoundedRectangle(cornerRadius: 10))
                    .onTapGesture {
                        focusedField = nil
                }
                }//.padding()
            }.gesture(
                DragGesture()
                    .onEnded { gesture in
                        let horizontalTranslation = gesture.translation.width
                        let verticalTranslation = gesture.translation.height
                        
                        if abs(horizontalTranslation) > abs(verticalTranslation) {
                            // 水平方向のスワイプ
                            if horizontalTranslation > 0 {
                                // 右にスワイプした場合の処理
                                //self.labelText = "右にスワイプしました"
                                if 0<current{
                                    current -= 1
                                }
                                show_current(current:current)
                            } else {
                                // 左にスワイプした場合の処理
                                //self.labelText = "左にスワイプしました"
                                if current<records.count-1{
                                    current += 1
                                }
                                show_current(current:current)
                            }
                        } else {
                            // 垂直方向のスワイプ
                            if verticalTranslation > 0 {
                                // 下にスワイプした場合の処理
                                //self.labelText = "下にスワイプしました"
                            } else {
                                // 上にスワイプした場合の処理
                                //self.labelText = "上にスワイプしました"
                            }
                        }
                    }
            )//.withAnimation(.spring())
            //Divider()
            //Spacer()
        }.padding()
    }
}

#Preview {
    ContentView()
}

/*
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
*/
