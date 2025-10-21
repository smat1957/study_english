//
//  ContentView.swift
//  HelloWorld2
//
//  Created by 的池秋成 on 2024/10/14.
//

import SwiftUI

extension UIApplication {
    func closeKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct ContentView: View {
    var dao = DAO()
    var csv = myCSV(fname: "ECompoData")
    let myjson = JSONRW(fname: "output")
    
    init(){
        self.dao.initial()
        books = self.dao.distinct(field_name: "book")
    }
    
    private let searchobjs = ["全","本","章","頁","番","単"]
    @State private var books = ["超上級英英単","1級パス単","1級単熟語Ex","上級英英単","準1級パス単","準1級単熟語Ex","入試ターゲット","入試シス単"]
    private let types = ["noun","verb","adjective","adverb","preposition"]
    private let stages = ["1","2","3","4","5","6","7","8","9","10"]
    private let seqs = ["ー","①","②","③","④","⑤"]
    @State var newsave:String = "New"
    @State var editupdate:String = "Edit"
    @State var id = 0
    @State var eword = ""
    @State var jword = ""
    @State var ewexp = ""
    @State var ebun = ""
    @State var wbun = ""
    @State var esim = ""
    @State var einv = ""
    @State var eassc = ""
    @State var descr = ""

    @State var npage = "0"
    @State var numb = "0"
    @State var selectedsearch = "本"
    @State var selectedbook = "上級英英単"
    @State var selectedstage = "1"
    @State var seqnum = 1
    @State var selectedtype = "noun"
    @State var current = 0
    @State var sizeofwords = 0
    @State var isError: Bool = false
    @State var isUpdate: Bool = false
    @State var isSave: Bool = false
    @State private var isBook: Bool = false
    @State private var isBikou: Bool = false
    @State private var isWabun: Bool = false
    @State private var isEibun: Bool = false
    @State private var isAssoc: Bool = false
    @State private var isInvrt: Bool = false
    @State private var isSimlr: Bool = false
    @State private var isExpre: Bool = false
    @State private var isJWord: Bool = false
    @State private var isEWord: Bool = false
    @State private var isDisableBook: Bool = false
    @State private var altBook: Bool = true
    @State private var altBikou: Bool = true
    @State private var altWabun: Bool = true
    @State private var altEibun: Bool = true
    @State private var altAssoc: Bool = true
    @State private var altInvrt: Bool = true
    @State private var altSimlr: Bool = true
    @State private var altExpre: Bool = true
    @State private var altJWord: Bool = true
    @State private var altEWord: Bool = true
    @State private var exportFile: Bool = false
    @State private var importFile: Bool = false
    @State private var text: String = ""
    @State private var stringData: String = ""
    @State private var csvIOoption = ""
    @State private var csvData: [[String]] = []
    private let options = ["CSV入力","CSV出力","JSON出力"]

    enum FocusTextFields {
        //case bookf
        case stagef
        case pagef
        case linef
        //case ewordf
        //case jwordf
        //case ewexpf
        //case esimf
        //case einvf
        //case asscf
        //case ebunf
        //case wbunf
        //case descrf
    }
    
    @FocusState private var focusState: FocusTextFields?
    
    func clear_fields(){
        eword = ""
        jword = ""
        ewexp = ""
        ebun = ""
        wbun = ""
        esim = ""
        einv = ""
        eassc = ""
        descr = ""
        npage = "0"
        numb = "0"
    }

    func setData() -> [String]{
        var data = [String]()
        data.append(String(seqnum))
        data.append(eword)
        data.append(selectedtype)
        data.append(jword)
        data.append(ewexp)
        data.append(esim)
        data.append(einv)
        data.append(eassc)
        data.append(ebun)
        data.append(wbun)
        data.append(descr)
        data.append(selectedbook)
        data.append(selectedstage)
        data.append(String(npage))
        data.append(String(numb))
        return data
    }

    func search(){
        if selectedsearch==searchobjs[0] {
            self.dao.select_all()
        }else if selectedsearch==searchobjs[1] {
            self.dao.select_book(book: selectedbook)
        }else if selectedsearch==searchobjs[2] {
            self.dao.select_book_stage(book: selectedbook, stage: selectedstage)
        }else if selectedsearch==searchobjs[3] {
            self.dao.select_book_page(book: selectedbook, page: Int(npage)!)
        }else if selectedsearch==searchobjs[4] {
            self.dao.select_book_numb(book: selectedbook, numb: Int(numb)!)
        }else if selectedsearch==searchobjs[5] {
            self.dao.select_book_word(book: selectedbook, word: eword)
        }else if selectedsearch==searchobjs[6] {
            self.dao.select_word(word: eword)
        }
    }
    
    func okActionUpdate(){
        let curr = self.current
        let data = setData()
        self.dao.update(data: data, id:id)
        self.search()
        self.current = curr
        self.sizeofwords = words.count
        self.showcurrent(current: self.current)
        editupdate = "Edit"
        newsave = "New"
        isUpdate = false
        focusState = nil
    }
    
    func okActionSave(){
        let curr = self.current
        let data = setData()
        self.dao.insert(data: data)
        self.search()
        self.current = curr + 1
        self.sizeofwords = words.count
        self.showcurrent(current: self.current)
        newsave = "New"
        editupdate = "Edit"
        isSave = false
        focusState = nil
    }
    
    func okActionDelete(){
        let curr = self.current
        self.dao.delete(id:id)
        self.search()
        self.current = curr - 1
        self.sizeofwords = words.count
        self.showcurrent(current: self.current)
        isError = false
    }

    func showcurrent(current:Int){
            if words.count==0{return}
            id = words[current].id
            seqnum = words[current].seq+1
            eword = words[current].word
            selectedtype = words[current].type
            selectedstage = words[current].stage
            selectedbook = words[current].book
            jword = words[current].mean
            ewexp = words[current].expr
            ebun = words[current].eibun
            wbun = words[current].wabun
            esim = words[current].simlr
            einv = words[current].invrt
            eassc = words[current].relat
            descr = words[current].descr
            npage = String(words[current].page)
            numb = String(words[current].numb)
            sizeofwords = words.count
    }
    
    @State private var printAlert = false
    @State private var showAlert = false
    @State private var csv_data: [[String]] = []
    
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
        self.dao.select_book_page2(book: selectedbook, from_page: Int(npage)!, to_page: Int(npage)!+2)
        let num_of_records=words.count
        let randomNumbers = pickRandomNumbers(from: num_of_records, count: num_of_records)
        myjson.initial()
        for n in randomNumbers {
            myjson.booksappend(
                book:words[n].book,
                stage:words[n].stage,
                page:words[n].page,
                numb:words[n].numb,
                word:words[n].word,
                mean:words[n].mean,
                eibun:words[n].eibun,
                wabun:words[n].wabun
            )
            print("Debug:",words[n].page, words[n].numb, words[n].wabun)
        }
        myjson.jsongen(sort:sort)
        printAlert = false
    }
    
    func okActionPrintAll(sort:String){
        self.dao.select_book_page2(book: selectedbook, from_page: Int(npage)!, to_page: Int(npage)!+2)
        let num_of_records=words.count
        //let randomNumbers = pickRandomNumbers(from: num_of_records, count: num_of_records)
        myjson.initial()
        for n in 0 ..< num_of_records {
            myjson.booksappend(
                book:words[n].book,
                stage:words[n].stage,
                page:words[n].page,
                numb:words[n].numb,
                word:words[n].word,
                mean:words[n].mean,
                eibun:words[n].eibun,
                wabun:words[n].wabun
            )
            print("Debug",words[n].page, words[n].numb, words[n].wabun)
        }
        myjson.jsongen(sort:sort)
        printAlert = false
    }

    func nothankyou(){
        printAlert = false
    }

    var body: some View {
        VStack{
            //Spacer()
            HStack{
                Spacer()
                Button("|<<") {
                    current = 0
                    showcurrent(current:current)
                }.buttonStyle(.bordered)
                Spacer()
                Button("<") {
                    if 0<current{
                        current -= 1
                    }
                    showcurrent(current:current)
                }.buttonStyle(.bordered)
                Spacer()
                Text(String(current+1)+"/"+String(sizeofwords))
                Spacer()
                Button(">") {
                    if current<words.count-1{
                        current += 1
                    }
                    showcurrent(current:current)
                }.buttonStyle(.bordered)
                Spacer()
                Button(">>|") {
                    current = words.count-1
                    showcurrent(current:current)
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
                        defaultFilename: "EWordData.csv"
                    ) { result in
                        // エクスポートの完了時に実行されるコードを定義する
                        switch result {
                        case .success(let file):
                            print(file.absoluteString)
                            //case .success:
                            //    print("Export success")
                        case .failure(let error):
                            print(error)
                            //case .failure:
                            //    print("Export failed")
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
                        .fileImporter(isPresented: $importFile,
                                      allowedContentTypes: [.plainText],
                                      allowsMultipleSelection: false
                        ) { result in
                            switch result {
                            case .success(let directory):
                                directory.forEach { file in
                                    // CSVの読み込み
                                    csv_data = csv.reshape(url: file)
                                    self.showAlert = true  // -> アラート表示トリガー
                                    // DBに登録
                                    //dao.close()
                                    //dao.initial()
                                    //dao.drop_table()
                                    //dao.create_table()
                                    //for csvdata in data{
                                    //    if 1<csvdata.count{
                                    //        dao.insert_fromcsv(data: csvdata)
                                    //    }
                                    //}
                                }
                            case .failure(let error):
                                print(error.localizedDescription)
                            }
                        }
                        .alert("New or Append", isPresented: $showAlert) {
                            Button("Yes") {
                                //yesaction()
                                // DBに登録
                                dao.close()
                                dao.initial()
                                dao.drop_table()
                                dao.create_table()
                                //processCSV()
                                for csvdata in csv_data{
                                    if 1<csvdata.count{
                                        dao.insert_fromcsv(data: csvdata)
                                    }
                                }
                                self.books = dao.distinct(field_name: "book")
                                self.showAlert = false
                            }
                            Button("No", role: .cancel) {
                                //noaction()
                                //processCSV()
                                for csvdata in csv_data{
                                    if 1<csvdata.count{
                                        dao.insert_fromcsv(data: csvdata)
                                    }
                                }
                                self.showAlert = false
                            }
                        } message: {
                            Text("DBを作り直しますか？")
                        }

                    //onCancellation: {
                    //    print("cancell success")
                    //}
                }else if(csvIOoption=="JSON出力"){
                    Button("JS"){printAlert=true}
                        .alert("Random or Ascending ?", isPresented: $printAlert) {
                        Button("Random(All)") {
                            okActionPrintRandom(sort:"field")
                        }
                        Button("Ascending(All)") {
                            okActionPrintAll(sort:"field")
                        }
                        Button("Cancel", role: .cancel) {
                            nothankyou()
                        }
                    } message: {
                        Text("現在のページ〜から出題します")
                    }

                }
                Spacer()
            }
            
            //}
            HStack{
                //Spacer()
                Button("検索") {
                    let book:String = selectedbook
                    //let curr:Int = current
                    /*
                    if selectedsearch==searchobjs[0] {
                        self.dao.select_all()
                    }else if selectedsearch==searchobjs[1] {
                        self.dao.select_book(book: selectedbook)
                    }else if selectedsearch==searchobjs[2] {
                        self.dao.select_book_stage(book: selectedbook, stage: selectedstage)
                    }else if selectedsearch==searchobjs[3] {
                        self.dao.select_book_page(book: selectedbook, page: Int(npage)!)
                    }else if selectedsearch==searchobjs[4] {
                        self.dao.select_book_numb(book: book, numb: Int(numb)!)
                    }else if selectedsearch==searchobjs[5] {
                        self.dao.select_book_word(book: book, word: eword)
                    }else if selectedsearch==searchobjs[6] {
                        self.dao.select_word(word: eword)
                    }
                    */
                    search()
                    current=0
                    if words.count>0{
                        sizeofwords = words.count
                        showcurrent(current:current)
                    }else if words.count==0{
                        sizeofwords = 0
                        words.removeAll()
                        clear_fields()
                    }
                    selectedbook = book
                    newsave = "New"
                    editupdate = "Edit"
                    focusState = nil
                }.buttonStyle(.bordered)
                //Spacer()
                Picker(selection:$selectedsearch, label: Text("検索")) {
                    ForEach (searchobjs, id: \.self) {
                        Text($0)
                    }
                }.pickerStyle(.menu)
                    .frame(width:55)
                    .clipped()
                    .contentShape(Rectangle())
                Button( newsave ) {
                    if newsave=="New" {
                        clear_fields()
                        newsave = "Save"
                    } else if newsave=="Save" {
                        isSave = true
                    }
                }.buttonStyle(.bordered)
                    .alert(isPresented: $isSave){
                        Alert(title:Text("Save?"), message: Text("id=new"+", word="+eword),
                              primaryButton:.default(Text("Ok"),action:{okActionSave()}),
                              secondaryButton:.cancel(Text("Cancel"), action:{}))
                    }
                //Spacer()
                Button(editupdate) {
                    if editupdate=="Edit"{
                        editupdate = "Updt"
                        newsave = "Save"
                    } else if editupdate=="Updt"{
                        isUpdate = true
                    }
                }.buttonStyle(.bordered)
                    .alert(isPresented: $isUpdate){
                        Alert(title:Text("Update?"), message: Text("id="+String(id)+", word="+eword),
                              primaryButton:.default(Text("Ok"),action:{okActionUpdate()}),
                              secondaryButton:.cancel(Text("Cancel"), action:{}))
                    }
                //Spacer()
                Button("Del") {
                    isError = true
                }.buttonStyle(.bordered)
                    .alert(isPresented: $isError){
                        Alert(title:Text("Delete?"), message: Text("id="+String(id)+",word="+eword),
                              primaryButton:.default(Text("Ok"),action:{okActionDelete()}),
                              secondaryButton:.cancel(Text("Cancel"), action:{}))
                    }
                //Spacer()
            }
            HStack{
                //Spacer()
                if newsave=="Save"||editupdate=="Updt"{
                    Button("本") {
                        isBook.toggle()
                    }.buttonStyle(.bordered)
                    TextField("本", text: $selectedbook, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .border(Color.gray)
                        .autocapitalization(.none)
                        //.keyboardType(.default)
                        .disableAutocorrection(true)
                        .font(.system(size: 15))
                        //.focused($focusState, equals: .bookf)
                        .sheet(isPresented: $isBook) {
                            @State var s:String = "本"
                            EditView(ttl: $s, str: $selectedbook)
                        }
                }else{
                    Text("本")
                    Picker(selection:$selectedbook, label: Text("本")) {
                        ForEach (books, id: \.self) {
                            Text($0)
                        }
                    }.pickerStyle(.menu)
                    .frame(width:110)
                    .clipped()
                    .contentShape(Rectangle())
                    
                    .onChange(of: selectedbook) {
                        if selectedbook.isEmpty {
                            isDisableBook = true
                        } else {
                            //selectedSearch = "本"
                            self.dao.select_book(book: selectedbook)
                            current=0
                            if words.count>0{
                                //current=0
                                showcurrent(current:current)
                            }else if words.count==0{
                                words.removeAll()
                                //current = 0
                                //sizeofwords = 0
                                clear_fields()
                            }
                            isDisableBook = false
                        }
                    }
                    
                }
                
                TextField("999", text: $selectedstage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 30)
                    .border(Color.gray)
                    .keyboardType(.numberPad)
                    .focused($focusState, equals: .stagef)
                    .multilineTextAlignment(.trailing)
                Text("章")
                
                //Text("：")
                TextField("999", text: $npage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 46)
                    .border(Color.gray)
                    .keyboardType(.numberPad)
                    .focused($focusState, equals: .pagef)
                    .multilineTextAlignment(.trailing)
                Text("頁")
                
                //Spacer()
                TextField("999", text: $numb)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 46)
                    .border(Color.gray)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .focused($focusState, equals: .linef)
                    .disableAutocorrection(true)
                Text("番")
                //Spacer()
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .onTapGesture {
                    UIApplication.shared.closeKeyboard()
            }
        }
        Divider()
        ZStack{
            VStack{
                //Spacer()
                HStack{
                    Spacer()
                    Picker(selection:$seqnum, label: Text("番")) {
                        ForEach(0..<seqs.count, id: \.self) { index in
                            Text(seqs[index]).tag(index+1)
                        }
                    }.pickerStyle(.menu)
                        .frame(width:60)
                        .clipped()
                        .contentShape(Rectangle())
                    if (newsave=="Save")||(editupdate=="Updt"){
                        Button("単語") {
                            isEWord.toggle()
                        }.buttonStyle(.bordered)
                    }else{
                        //Text("単語")
                    }
                    TextField("単語", text: $eword, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        //.frame(width: 200)
                        .border(Color.gray)
                        .autocapitalization(.none)
                        //.keyboardType(.default)
                        .multilineTextAlignment(.trailing)
                        .disableAutocorrection(true)
                        .foregroundColor(altEWord ? .primary:Color(UIColor.systemGray6))
                        .background(Color(UIColor.systemGray6))
                        //.focused($focusState, equals: .ewordf)
                        .sheet(isPresented: $isEWord) {
                            @State var s:String = "単語"
                            EditView(ttl: $s, str: $eword)
                        }
                    Picker(selection:$selectedtype, label: Text("品詞")) {
                        ForEach (types, id: \.self) {
                            Text($0)
                        }
                    }.pickerStyle(.menu)
                    //.frame(width:110)
                        .clipped()
                        .contentShape(Rectangle())
                    
                    Spacer()
                }
                Spacer()
                HStack{
                    VStack(spacing: 0){
                        if (newsave=="Save")||(editupdate=="Updt"){
                            Button("意味") {
                                isJWord.toggle()
                            }.buttonStyle(.bordered)
                        }else{
                            Text("意味")
                        }
                        Toggle(isOn: $altJWord) {
                            let _ = altJWord = false
                        }.fixedSize()
                            .scaleEffect(0.5)
                    }
                    TextField("意味", text: $jword, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        //.frame(width: .infinity)
                        .border(Color.gray)
                        .autocapitalization(.none)
                        //.keyboardType(.default)
                        .disableAutocorrection(true)
                        .foregroundColor(altJWord ? .primary:Color(UIColor.systemGray6))
                        .background(Color(UIColor.systemGray6))
                        //.focused($focusState, equals: .jwordf)
                        .sheet(isPresented: $isJWord) {
                            @State var s:String = "意味"
                            EditView(ttl: $s, str: $jword)
                        }
                }.ignoresSafeArea(.keyboard, edges: .all)
                Spacer()
                HStack{
                    VStack(spacing: 0){
                        if (newsave=="Save")||(editupdate=="Updt"){
                            Button("語釈") {
                                isExpre.toggle()
                            }.buttonStyle(.bordered)
                        }else{
                            Text("語釈")
                        }
                        Toggle(isOn: $altExpre) {
                            let _ = altExpre = false
                        }.fixedSize()
                            .scaleEffect(0.5)
                    }
                    TextField("語釈", text: $ewexp, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        //.frame(width: .infinity)
                        .border(Color.gray)
                        .autocapitalization(.none)
                        //.keyboardType(.default)
                        .disableAutocorrection(true)
                        .foregroundColor(altExpre ? .primary:Color(UIColor.systemGray6))
                        .background(Color(UIColor.systemGray6))
                        //.focused($focusState, equals: .ewexpf)
                        .sheet(isPresented: $isExpre) {
                            @State var s:String = "語釈"
                            EditView(ttl: $s, str: $ewexp)
                        }

                }.ignoresSafeArea(.keyboard, edges: .all)
                Spacer()
                HStack{
                    VStack(spacing: 0){
                        if (newsave=="Save")||(editupdate=="Updt"){
                            Button("類似") {
                                isSimlr.toggle()
                            }.buttonStyle(.bordered)
                        }else{
                            Text("類似")
                        }
                        Toggle(isOn: $altSimlr) {
                            let _ = altSimlr = false
                        }.fixedSize()
                            .scaleEffect(0.5)
                    }
                    TextField("類似語", text: $esim, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        //.frame(width: .infinity)
                        .border(Color.gray)
                        .autocapitalization(.none)
                        //.keyboardType(.default)
                        .disableAutocorrection(true)
                        .foregroundColor(altSimlr ? .primary:Color(UIColor.systemGray6))
                        .background(Color(UIColor.systemGray6))
                        //.focused($focusState, equals: .esimf)
                        .sheet(isPresented: $isSimlr) {
                            @State var s:String = "類似語"
                            EditView(ttl: $s, str: $esim)
                        }
                }.ignoresSafeArea(.keyboard, edges: .all)
                Spacer()
                HStack{
                    VStack(spacing: 0){
                        if (newsave=="Save")||(editupdate=="Updt"){
                            Button("反対") {
                                isInvrt.toggle()
                            }.buttonStyle(.bordered)
                        }else{
                            Text("反対")
                        }
                        Toggle(isOn: $altInvrt) {
                            let _ = altInvrt = false
                        }.fixedSize()
                            .scaleEffect(0.5)
                    }
                    TextField("反対語", text: $einv, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        //.frame(width: .infinity)
                        .border(Color.gray)
                        .autocapitalization(.none)
                        //.keyboardType(.default)
                        .disableAutocorrection(true)
                        .foregroundColor(altInvrt ? .primary:Color(UIColor.systemGray6))
                        .background(Color(UIColor.systemGray6))
                        //.focused($focusState, equals: .einvf)
                        .sheet(isPresented: $isInvrt) {
                            @State var s:String = "反対語"
                            EditView(ttl: $s, str: $einv)
                        }

                }.ignoresSafeArea(.keyboard, edges: .all)
                Spacer()
                HStack{
                    VStack(spacing: 0){
                        if (newsave=="Save")||(editupdate=="Updt"){
                            Button("関連") {
                                isAssoc.toggle()
                            }.buttonStyle(.bordered)
                        }else{
                            Text("関連")
                        }
                        Toggle(isOn: $altAssoc) {
                            let _ = altAssoc = false
                        }.fixedSize()
                            .scaleEffect(0.5)
                    }
                    TextField("関連語", text: $eassc, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        //.frame(width: .infinity)
                        .border(Color.gray)
                        .autocapitalization(.none)
                        //.keyboardType(.default)
                        .disableAutocorrection(true)
                        .foregroundColor(altAssoc ? .primary:Color(UIColor.systemGray6))
                        .background(Color(UIColor.systemGray6))
                        //.focused($focusState, equals: .asscf)
                        .sheet(isPresented: $isAssoc) {
                            @State var s:String = "関連語"
                            EditView(ttl: $s, str: $eassc)
                        }
                }.ignoresSafeArea(.keyboard, edges: .all)
                Spacer()
                HStack{
                    VStack(spacing: 0){
                        if (newsave=="Save")||(editupdate=="Updt"){
                            Button("英文") {
                                isEibun.toggle()
                            }.buttonStyle(.bordered)
                        }else{
                            Text("英文")
                        }
                        Toggle(isOn: $altEibun) {
                            let _ = altEibun = false
                        }.fixedSize()
                            .scaleEffect(0.5)
                    }
                    TextField("英文", text: $ebun, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        //.frame(width: .infinity)
                        .border(Color.gray)
                        .autocapitalization(.none)
                        //.keyboardType(.default)
                        .disableAutocorrection(true)
                        .foregroundColor(altEibun ? .primary:Color(UIColor.systemGray6))
                        .background(Color(UIColor.systemGray6))
                        //.focused($focusState, equals: .ebunf)
                        .sheet(isPresented: $isEibun) {
                            @State var s:String = "英文"
                            EditView(ttl: $s, str: $ebun)
                        }

                }.ignoresSafeArea(.keyboard, edges: .all)
                Spacer()
                HStack{
                    VStack(spacing: 0){
                        if (newsave=="Save")||(editupdate=="Updt"){
                            Button("和文") {
                                isWabun.toggle()
                            }.buttonStyle(.bordered)
                        }else{
                            Text("和文")
                        }
                        Toggle(isOn: $altWabun) {
                            let _ = altWabun = false
                        }.fixedSize()
                            .scaleEffect(0.5)
                    }
                    TextField("和文", text: $wbun, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        //.frame(width: .infinity)
                        .border(Color.gray)
                        .autocapitalization(.none)
                        //.keyboardType(.default)
                        .disableAutocorrection(true)
                        .foregroundColor(altWabun ? .primary:Color(UIColor.systemGray6))
                        .background(Color(UIColor.systemGray6))
                        //.focused($focusState, equals: .wbunf)
                        .sheet(isPresented: $isWabun) {
                            @State var s:String = "和文"
                            EditView(ttl: $s, str: $wbun)
                        }
                }.ignoresSafeArea(.keyboard, edges: .all)
                Spacer()
                HStack{
                    VStack(spacing: 0){
                        if (newsave=="Save")||(editupdate=="Updt"){
                            Button("備考") {
                                isBikou.toggle()
                            }.buttonStyle(.bordered)
                        }else{
                            Text("備考")
                        }
                        Toggle(isOn: $altBikou) {
                            let _ = altBikou = false
                        }.fixedSize()
                            .scaleEffect(0.5)
                    }
                    TextField("備考", text: $descr, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        //.frame(width: .infinity)
                        .border(Color.gray)
                        .autocapitalization(.none)
                        .keyboardType(.default)
                        .disableAutocorrection(true)
                        .foregroundColor(altBikou ? .primary:Color(UIColor.systemGray6))
                        .background(Color(UIColor.systemGray6))
                        //.focused($focusState, equals: .descrf)
                        .sheet(isPresented: $isBikou) {
                            @State var s:String = "備考"
                            EditView(ttl: $s, str: $descr)
                        }.navigationBarTitle("備考")
                }.ignoresSafeArea(.keyboard, edges: .all)
                //Spacer()
            }//.border(.gray)
            .padding(.all)
        }
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
                            showcurrent(current:current)
                        } else {
                            // 左にスワイプした場合の処理
                            //self.labelText = "左にスワイプしました"
                            if current<words.count-1{
                                current += 1
                            }
                            showcurrent(current:current)
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
        )
        //.withAnimation(.spring())
        //Divider()
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
    //subView(word:"word")
}
