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

//GeometryReader { geometry in
//    Text("Width: \(geometry.size.width)")
//}

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
