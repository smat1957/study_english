//
//  DAO.swift
//  HelloEWord
//
//  Created by 的池秋成 on 2025/08/01.
//
import SwiftUI
import SQLite3

struct Words {
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

nonisolated(unsafe) var words = [Words]()

class DAO:SQLite3{
    let table_name:String = "eword"
    func initial(){
        let rootDirectory = NSHomeDirectory() + "/Documents"
        open(path: rootDirectory+"/eword_sqlite3")
        //drop_table()
        //create_table()
        print("dao!->",rootDirectory+"/eword_sqlite3")
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
        //print("..>", data)
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
            words.append(Words(id:id, seq:seq, word:word, type:type, mean:mean, expr:expr, simlr:simlr, invrt:invrt, relat:relat, eibun:eibun, wabun:wabun, descr:descr, book:book, stage:stage, page:page, numb:numb))
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
    func select_book_page2(book:String, from_page:Int, to_page:Int){
        prepare("SELECT * FROM \(table_name) WHERE book = ? AND page BETWEEN ? AND ? ORDER BY book ASC, stage ASC, page ASC, numb ASC, word ASC, seq ASC")
        bindText(index: 1, value: book)
        bindInt(index: 2, value: from_page)
        bindInt(index: 3, value: to_page)
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

