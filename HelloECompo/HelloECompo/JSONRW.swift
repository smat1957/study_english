//
//  JSONRW.swift
//  HelloECompo
//
//  Created by 的池秋成 on 2025/08/01.
//
import SwiftUI

class JSONRW {
    var fname = "output"
    init(fname: String = "output"){
        self.fname = fname
    }
    func getFName() -> String {
        return self.fname+".json"
    }

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
            let fileURL = documentsDirectory.appendingPathComponent(getFName())
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
            //let cmdlineargs=["eisaku", sort]
            //print( do_python(cmdlnargs: cmdlineargs) )
        } catch {
            print("JSONエンコードに失敗しました： \(error)")
        }
    }
    /*
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
    */
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
