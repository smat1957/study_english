//
//  JSONRW.swift
//  HelloEWord
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
        let stage: String
        let page: Int
        let numb: Int
        let word: String
        let mean: String
        let eibun: String
        let wabun: String
    }
    var books = [
        Book(book:"",stage:"",page:0,numb:0,word:"",mean:"",eibun:"",wabun:""),
        Book(book:"",stage:"",page:0,numb:0,word:"",mean:"",eibun:"",wabun:"")
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
    func booksappend(book:String,stage:String,page:Int,numb:Int,word:String,mean:String,eibun:String,wabun:String) {
        let b = Book(book:book,stage:stage,page:page,numb:numb,word:word,mean:mean,eibun:eibun,wabun:wabun)
        books.append(b)
    }
    func jsongen(){
        jsongen(books: books)
    }
    func jsongen(books: [Book]){
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(books)
            if String(data: jsonData, encoding: .utf8) != nil {
                jsonwrite()
                //writeToFile(text: jsonString)
            }
            let cmdlineargs=["eitango"]
            print( do_python(cmdlnargs: cmdlineargs) )
        } catch {
            print("JSONエンコードに失敗しました： \(error)")
        }
    }
    func do_python(cmdlnargs: [String]) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        let path: String = "/Users/mat/Documents/PycharmProjects/json2tex4EWord/"
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

}
