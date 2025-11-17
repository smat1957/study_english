//
//  ContentView.swift
//  HelloECompo
//
//  Created by 的池秋成 on 2024/10/15.
//
import Foundation
import SwiftUI

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
    let dao = DAO()
    let csv = CSV(fname: "ECompoData")
    let myjson = JSONRW(fname: "output")
    
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
    @State private var csvIOoption = ""
    @State private var csvData: [[String]] = []
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
        show_current(current: current)
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
        if records.count==0{return}
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
        let curr = self.current
        let data = setData()
        dao.update(data: data, id:id)
        search()
        self.current = curr
        show_current(current:self.current)
        edit_update = "Edit"
        new_save = "New"
        isUpdate = false
        focusedField = nil
    }
    func okActionSave(){
        let curr = self.current
        let data = setData()
        dao.insert(data: data)
        search()
        self.current = curr + 1
        show_current(current:self.current)
        new_save = "New"
        edit_update = "Edit"
        isSave = false
        focusedField = nil
    }
    func okActionDelete(){
        let curr = self.current
        self.dao.delete(id:id)
        search()
        self.current = curr - 1
        show_current(current:self.current)
        isDelete = false
        focusedField = nil
    }
    /*
    func python01(cmdlnargs: [String]) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        let path: String = "/Users/mat/Documents/PycharmProjects/qa4u"
        var strArray:[String] = [path + "/qa4u3/go.sh"]
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

    func search(){
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
    }
    private let options = ["CSV入力","CSV出力","分野(JSON出力)","話題(JSON出力)"]
    @State private var printAlert1 = false
    @State private var printAlert2 = false
    @State private var showAlert = false
    @State private var importedData: [[String]] = []
    @State private var yesnoflag = false

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

    @State var noEdit: Bool = false

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
                    if(csvIOoption=="CSV出力"){
                        Button("出") {
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
                    }else if(csvIOoption=="CSV入力"){
                        Button("入") {
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
                    }else if(csvIOoption=="分野(JSON出力)"){
                        Button("分"){printAlert1=true}
                            .alert("Random or Ascending ?", isPresented: $printAlert1) {
                            Button("Random(10)") {
                                okActionPrintRandom(sort:"field")
                            }
                            Button("Ascending(All)") {
                                okActionPrintAll(sort:"field")
                            }
                            Button("Cancel", role: .cancel) {
                                nothankyou()
                            }
                        } message: {
                            Text("分野「"+selectedField+"」\nについて出題します")
                        }
                    }else if(csvIOoption=="話題(JSON出力)"){
                        Button("話"){printAlert2=true}
                            .alert("Random or Ascending ?", isPresented: $printAlert2) {
                            Button("Random(10)") {
                                okActionPrintRandom(sort:"topic")
                            }
                            Button("Ascending(All)") {
                                okActionPrintAll(sort:"topic")
                            }
                            Button("Cancel", role: .cancel) {
                                nothankyou()
                            }
                        } message: {
                            Text("話題「"+selectedTopic+"」\nについて出題します")
                        }
                    }

                    Spacer()
                }//.padding()
                HStack{
                    Button("検索") {
                        let book:String = selectedBook
                        self.search()
                        self.current = 0
                        if records.count>0{
                            self.sizeofRecords = records.count
                            self.show_current(current:current)
                        }else if records.count==0{
                            records.removeAll()
                            self.sizeofRecords = 0
                            self.clear_fields()
                        }
                        self.selectedBook = book
                        self.new_save = "New"
                        self.edit_update = "Edit"
                        self.focusedField = nil
                    }.buttonStyle(.bordered)
                    //Spacer()
                    Picker(selection:$selectedSearch, label: Text("検索")) {
                        ForEach (searchObjs, id: \.self) {
                            Text($0)
                        }
                    }.pickerStyle(.menu)
                        .frame(width:55)
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
                //.onTapGesture {
                //    focusedField = nil
                //}
                HStack{
                    Text("行")
                    ZStack{
                        TextField("999", text: $line)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 46)
                            .border(Color.gray)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .line)
                            .foregroundColor(.primary)
                            .background(Color(UIColor.systemGray6))
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
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .page)
                        .foregroundColor(.primary)
                        .background(Color(UIColor.systemGray6))
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
                        //
                        if (new_save=="Save")||(edit_update=="Updt"){
                            Button("本") {
                                altBook.toggle()
                            }.buttonStyle(.bordered)
                        }else{
                            Text("本")
                        }
                        TextField("本", text: $book, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .border(Color.gray)
                            .autocapitalization(.none)
                            //.keyboardType(.default)
                            .disableAutocorrection(true)
                            .font(.system(size: 15))
                            //.onSubmit {
                            //    altBook.toggle()
                            //}
                            //.focused($focusState, equals: .bookf)
                            .sheet(isPresented: $altBook) {
                                @State var s:String = "本"
                                EditView(ttl: $s, str: $book)
                            }
                    }else{
                        Picker(selection:$selectedBook, label: Text("本")) {
                            ForEach (Books, id: \.self) {
                                Text($0)
                            }
                        }.pickerStyle(.menu)
                            .frame(width: 160) //.frame(width: .infinity)
                            .clipped()
                            .contentShape(Rectangle())
                            //.onChange(of: selectedBook) { newValue in
                            //    if newValue.isEmpty {
                            .onChange(of: selectedBook) {
                                if selectedBook.isEmpty {
                                    isDisableBook = true
                                } else {
                                    if selectedSearch != searchObjs[0] {
                                        //selectedSearch = "本"
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
                                        isDisableBook = false
                                    }
                                }
                            }
                    }
                }.padding()
                VStack{
                    HStack{
                        //
                        if (new_save=="Save")||(edit_update=="Updt"){
                            Button("分野") {
                                altField.toggle()
                            }.buttonStyle(.bordered)
                        }else{
                            Text("分野")
                        }
                        if (new_save=="Save")||(edit_update=="Updt"){
                            //field = selectedField
                            TextField("分野", text: $field, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .border(Color.gray)
                                .autocapitalization(.none)
                                //.keyboardType(.default)
                                .disableAutocorrection(true)
                                .font(.system(size: 15))
                                //.onSubmit {
                                //    altField.toggle()
                                //}
                                //.focused($focusState, equals: .fieldf)
                                .sheet(isPresented: $altField) {
                                    @State var s:String = "分野"
                                    EditView(ttl: $s, str: $field)
                                }
                        }else{
                            Picker(selection:$selectedField, label: Text(selectedField)) {
                                ForEach (Fields, id: \.self) {
                                    Text($0).font(.subheadline)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: .infinity, height: 38)
                            .clipped()
                            .contentShape(Rectangle())
/*
                            .onChange(of: selectedField) { newValue in
                                if newValue.isEmpty {
                                    isDisableField = true
                                } else {
                                    //selectedSearch = "分野"
                                    self.dao.select_book_field(book: selectedBook, field: selectedField)
                                    if records.count>0{
                                        current=0
                                        show_current(current:current)
                                    }else if records.count==0{
                                        records.removeAll()
                                        current = 0
                                        sizeofRecords = 0
                                        clear_fields()
                                    }
                                    isDisableField = false
                                }
                            }
*/
                        }
                    }//.padding()
                    //.onTapGesture {
                    //    focusedField = nil
                    //}
                    HStack{
                        //
                        if (new_save=="Save")||(edit_update=="Updt"){
                            Button("話題") {
                                altTopic.toggle()
                            }.buttonStyle(.bordered)
                        }else{
                            Text("話題")
                        }
                        if (new_save=="Save")||(edit_update=="Updt"){
                            //topic = selectedTopic
                            TextField("話題", text: $topic, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .border(Color.gray)
                                .autocapitalization(.none)
                                //.keyboardType(.default)
                                .disableAutocorrection(true)
                                .font(.system(size: 15))
                                //.onSubmit {
                                //    altTopic.toggle()
                                //}
                                //.focused($focusState, equals: .topicf)
                                .sheet(isPresented: $altTopic) {
                                    @State var s:String = "話題"
                                    EditView(ttl: $s, str: $topic)
                                }

                        }else{
                            Picker(selection:$selectedTopic, label: Text("話題")) {
                                ForEach (Topics, id: \.self) {
                                    Text($0).font(.subheadline)
                                }
                            }.pickerStyle(.wheel)
                                .frame(width: .infinity, height: 38)
                                .clipped()
                                .contentShape(Rectangle())
/*
                                .onChange(of: selectedTopic) { newValue in
                                    if newValue.isEmpty {
                                        isDisableTopic = true
                                    } else {
                                        //selectedSearch = "話題"
                                        self.dao.select_book_topic(book: selectedBook, topic: selectedTopic)
                                        if records.count>0{
                                            current=0
                                            show_current(current:current)
                                        }else if records.count==0{
                                            records.removeAll()
                                            current = 0
                                            sizeofRecords = 0
                                            clear_fields()
                                        }
                                        isDisableTopic = false
                                    }
                                }
*/
                        }
                    }//.padding()
                    //.onTapGesture {
                    //    focusedField = nil
                    //}
                    HStack{
                        //
                        if (new_save=="Save")||(edit_update=="Updt"){
                            Button("題目") {
                                altTitle.toggle()
                            }.buttonStyle(.bordered)
                        }else{
                            Text("題目")
                        }
                        if (new_save=="Save")||(edit_update=="Updt"){
                            TextField("題目", text: $title, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .border(Color.gray)
                                .autocapitalization(.none)
                                //.keyboardType(.default)
                                .disableAutocorrection(true)
                                .font(.system(size: 15))
                                //.onSubmit {
                                //    altTitle.toggle()
                                //}
                                //.focused($focusState, equals: .titlef)
                                .sheet(isPresented: $altTitle) {
                                    @State var s:String = "題目"
                                    EditView(ttl: $s, str: $title)
                                }

                        }else{
                            Picker(selection:$selectedTitle, label: Text("題目")) {
                                ForEach (Titles, id: \.self) {
                                    Text($0).font(.subheadline)
                                }
                            }.pickerStyle(.wheel)
                                .frame(width: .infinity, height: 38)
                                .clipped()
                                .contentShape(Rectangle())
/*
                                .onChange(of: selectedTitle) { newValue in
                                    if newValue.isEmpty {
                                        isDisableTitle = true
                                    } else {
                                        //selectedSearch = "題目"
                                        self.dao.select_book_title(book: selectedBook, title: selectedTitle)
                                        if records.count>0{
                                            current=0
                                            show_current(current:current)
                                        }else if records.count==0{
                                            records.removeAll()
                                            current = 0
                                            sizeofRecords = 0
                                            clear_fields()
                                        }
                                        isDisableTitle = false
                                    }
                                }
*/
                        }
                    }//.padding()
                    //.onTapGesture {
                    //    focusedField = nil
                    //}
                }//.padding()
                //Spacer()
            }//.padding()
            .onTapGesture { UIApplication.shared.closeKeyboard() }
            //.onTapGesture {
            //    focusedField = nil
            //}
            //Spacer()
            Divider()
            Spacer()
            ZStack{
                VStack() {
                    //Spacer()
                    HStack{
                        VStack(spacing: 0){
                            if (new_save=="Save")||(edit_update=="Updt"){
                                Button("和文") {
                                    altWabun.toggle()
                                }.buttonStyle(.bordered)
                            }else{
                                Text("和文")
                            }
                            Toggle(isOn: $isWabun) {
                                let _ = isWabun = false
                            }.fixedSize()
                                .scaleEffect(0.5)
                        }//.padding()
                        if isWabun {
                            TextField("和文", text: $wabun, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .border(Color.gray)
                                .autocapitalization(.none)
                                .keyboardType(.default)
                                .disableAutocorrection(true)
                                //.focused($focusedField, equals: .wabunf)
                                .foregroundColor(.primary)
                                .background(Color(UIColor.systemGray6))
                                .font(.system(size: 15))
                                .disabled(noEdit)
                                //.onSubmit {
                                //    altWabun.toggle()
                                //}
                                //.focused($focusState, equals: .wbunf)
                                //.focused($focusedField, equals: .wbunf)
                                .sheet(isPresented: $altWabun) {
                                    @State var s:String = "和文"
                                    EditView(ttl: $s, str: $wabun)
                                }

                        } else {
                            TextField("和文", text: $wabun, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .border(Color.gray)
                                .autocapitalization(.none)
                                .keyboardType(.default)
                                .disableAutocorrection(true)
                                //.focused($focusedField, equals: .wabun)
                                .foregroundColor(Color(UIColor.systemGray6))
                                .background(Color(UIColor.systemGray6))
                                .font(.system(size: 15))
                                .disabled(noEdit)
                        }
                    }//.frame(width: UIScreen.main.bounds.width,height: UIScreen.main.bounds.height)
                    .contentShape(RoundedRectangle(cornerRadius: 10))
                    //.onTapGesture {
                    //    focusedField = nil
                    //}
                    HStack{
                        VStack(spacing: 0){
                            if (new_save=="Save")||(edit_update=="Updt"){
                                Button("英文") {
                                    altEibun.toggle()
                                }.buttonStyle(.bordered)
                            }else{
                                Text("英文")
                            }
                            Toggle(isOn: $isEibun) {
                                let _ = isEibun = false
                            }.fixedSize()
                                .scaleEffect(0.5)
                        }//.padding()
                        if isEibun {
                            TextField("英文", text: $eibun, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .border(Color.gray)
                                .autocapitalization(.none)
                                //.keyboardType(.default)
                                .disableAutocorrection(true)
                                //.focused($focusedField, equals: .eibunf)
                                .foregroundColor(.primary)
                                .background(Color(UIColor.systemGray6))
                                .font(.system(size: 15))
                                .disabled(noEdit)
                                //.onSubmit {
                                //    altEibun.toggle()
                                //}
                                //.focused($focusState, equals: .ebunf)
                                //.focused($focusedField, equals: .ebunf)
                                .sheet(isPresented: $altEibun) {
                                    @State var s:String = "英文"
                                    EditView(ttl: $s, str: $eibun)
                                }
                        } else {
                            TextField("英文", text: $eibun, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .border(Color.gray)
                                .autocapitalization(.none)
                                .keyboardType(.default)
                                .disableAutocorrection(true)
                                //.focused($focusedField, equals: .eibun)
                                .foregroundColor(Color(UIColor.systemGray6))
                                .background(Color(UIColor.systemGray6))
                                .font(.system(size: 15))
                                .disabled(noEdit)
                        }
                    }//.frame(width: UIScreen.main.bounds.width,height: UIScreen.main.bounds.height)
                    .contentShape(RoundedRectangle(cornerRadius: 10))
                    //.onTapGesture {
                    //    focusedField = nil
                    //}
                    HStack{
                        VStack(spacing: 0){
                            if (new_save=="Save")||(edit_update=="Updt"){
                                Button("備考") {
                                    altHint.toggle()
                                }.buttonStyle(.bordered)
                            }else{
                                Text("備考")
                            }
                            Toggle(isOn: $isHint) {
                                let _ = isHint = false
                            }.fixedSize()
                                .scaleEffect(0.5)
                        }//.padding()
                        if isHint {
                            //NavigationLink(destination: EditView(text: hint)) {
                                TextField("備考", text: $hint, axis: .vertical)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .border(Color.gray)
                                    .autocapitalization(.none)
                                    //.keyboardType(.default)
                                    .disableAutocorrection(true)
                                    //.focused($focusedField, equals: .hintf)
                                    .foregroundColor(.primary)
                                    .background(Color(UIColor.systemGray6))
                                    .font(.system(size: 15))
                                    .disabled(noEdit)
                                    //.onSubmit {
                                    //    altHint.toggle()
                                    //}
                                    //.focused($focusState, equals: .hintf)
                                    //.focused($focusedField, equals: .hintf)
                                    .sheet(isPresented: $altHint) {
                                        @State var s:String = "備考"
                                        EditView(ttl: $s, str: $hint)
                                    }

                            //}
                        } else {
                             TextField("備考", text: $hint, axis: .vertical)
                                 .textFieldStyle(RoundedBorderTextFieldStyle())
                                 .border(Color.gray)
                                 .autocapitalization(.none)
                                 .keyboardType(.default)
                                 .disableAutocorrection(true)
                                 //.focused($focusedField, equals: .hint)
                                 .foregroundColor(Color(UIColor.systemGray6))
                                 .background(Color(UIColor.systemGray6))
                                 .font(.system(size: 15))
                                 .disabled(noEdit)
                        }
                    }//.frame(width: UIScreen.main.bounds.width,height: UIScreen.main.bounds.height)
                    .contentShape(RoundedRectangle(cornerRadius: 10))
                    //.onTapGesture {
                    //    focusedField = nil
                    //}
                }//.padding()
            }
            //.ignoresSafeArea(.keyboard, edges: .bottom)
            .onTapGesture { UIApplication.shared.closeKeyboard() }
            .gesture(
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

#Preview {
    ContentView()
}
