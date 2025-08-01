//
//  DAO.swift
//  HelloECompo
//
//  Created by 的池秋成 on 2025/08/01.
//
import SwiftUI
import SQLite3

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
                //print("=>", i, data[i])
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
        records.removeAll()
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
        prepare("SELECT * FROM \(table_name) ORDER BY book ASC, chap ASC, page ASC, line ASC")
        append_record()
        if step() != SQLITE_DONE {
            print("error: SELECT")
        }
        resetStatement()
    }
    func select_book(book:String){
        prepare("SELECT * FROM \(table_name) WHERE book = ? ORDER BY book ASC, chap ASC, page ASC, line ASC")
        bindText(index: 1, value: book)
        append_record()
        if step() != SQLITE_DONE {
            print("error: SELECT")
        }
        resetStatement()
    }
    func select_book_chap(book:String, chap:Int){
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

