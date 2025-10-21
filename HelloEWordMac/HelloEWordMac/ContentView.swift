//
//  ContentView.swift
//  HelloEWordMac
//
//  Created by 的池秋成 on 2024/10/17.
//
//
//  ContentView.swift
//  HelloWorld
//
//  Created by 的池秋成 on 2024/09/29.
//

import SwiftUI
//import SQLite3
//import SwiftData

struct ContentView: View {
    var dao = DAO()
    var csv = myCSV(fname: "ECompoData")
    let myjson = JSONRW(fname: "output")

    init(){
        //self.dao = DAO()
        self.dao.initial()
        books = self.dao.distinct(field_name: "book")
    }
    private let searchobjs = ["全","本","章","頁","番","語","W"]
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
    @State private var exportFile: Bool = false
    @State private var importFile: Bool = false
    @State private var text: String = ""
    @State private var stringData: String = ""
    @State private var csvIOoption = ""
    @State private var csvData: [[String]] = []
    private let options = ["CSV入力","CSV出力","JSON出力"]
    
    func reshape(data:[String]){
        var csvdata: [String] = []
        var str: String = ""
        var flag: Bool = false
        for i in 0..<data.count {
            let str0 = data[i]
            if (str0.hasPrefix("\"")&&(!str0.hasSuffix("\""))){
                str = str0
                flag = true
            }else if ((!str0.hasPrefix("\""))&&(str0.hasSuffix("\""))){
                str += ","+str0
                csvdata.append(str.replacingOccurrences(of:"\"", with:""))
                flag = false
            }else if ((str0.hasPrefix("\""))&&(str0.hasSuffix("\""))){
                if (flag){
                    str += ","+str0
                }else{
                    csvdata.append(str0.replacingOccurrences(of:"\"", with:""))
                }
            }else{
                if (flag){
                    str += ","+str0
                }else{
                    csvdata.append(str0.replacingOccurrences(of:"\"", with:""))
                }
            }
        }
        dao.insert_fromcsv(data: csvdata)
    }
    func okActionUpdate(){
        var data = [String]()
        //data[0] = String(seqnum)
        data.append(String(seqnum))
        //data[1] = eword
        data.append(eword)
        //data[2] = selectedtype
        data.append(selectedtype)
        //data[3] = jword
        data.append(jword)
        //data[4] = ewexp
        data.append(ewexp)
        //data[5] = esim
        data.append(esim)
        //data[6] = einv
        data.append(einv)
        //data[7] = eassc
        data.append(eassc)
        //data[8] = ebun
        data.append(ebun)
        //data[9] = wbun
        data.append(wbun)
        //data[10] = descr
        data.append(descr)
        //data[11] = selectedbook
        data.append(selectedbook)
        //data[12] = selectedstage
        data.append(selectedstage)
        //data[13] = npage
        data.append(String(npage))
        //data[14] = num
        data.append(String(numb))
        self.dao.update(data: data, id:id)
        editupdate = "Edit"
        newsave = "New"
        isUpdate = false
    }
    func okActionSave(){
        var data = [String]()
        //data[0] = String(seqnum)
        data.append(String(seqnum))
        //data[1] = eword
        data.append(eword)
        //data[2] = selectedtype
        data.append(selectedtype)
        //data[3] = jword
        data.append(jword)
        //data[4] = ewexp
        data.append(ewexp)
        //data[5] = esim
        data.append(esim)
        //data[6] = einv
        data.append(einv)
        //data[7] = eassc
        data.append(eassc)
        //data[8] = ebun
        data.append(ebun)
        //data[9] = wbun
        data.append(wbun)
        //data[10] = descr
        data.append(descr)
        //data[11] = selectedbook
        data.append(selectedbook)
        //data[12] = selectedstage
        data.append(selectedstage)
        //data[13] = npage
        data.append(String(npage))
        //data[14] = num
        data.append(String(numb))
        self.dao.insert(data: data)
        newsave = "New"
        editupdate = "Edit"
        isSave = false
    }
    func okActionDelete(){
        self.dao.delete(id:id)
        isError = false
    }
    func okActionCSV(){
        _ = csv.generateCSV()
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
    func okActionPrintRandom(){
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
            print("Debug:",words[n].id, words[n].wabun)
        }
        myjson.jsongen()
        printAlert = false
    }
    
    func okActionPrintAll(){
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
            print("Debug",words[n].id, words[n].wabun)
        }
        myjson.jsongen()
        printAlert = false
    }

    func nothankyou(){
        printAlert = false
    }

    
    var body: some View {
        VStack{
            //Spacer()
            HStack{
                //Spacer()
                Button("検索") {
                    //words.removeAll()
                    var book:String = ""
                    book = selectedbook
                    //var stage:String = ""
                    //stage = selectedstage
                    //var page:String = ""
                    //page = npage
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
                        self.dao.select_book_word(book: selectedbook, word: eword)
                    }else if selectedsearch==searchobjs[6]{
                        self.dao.select_word(word: eword)
                    }
                    if words.count>0{
                        current=0
                        showcurrent(current:current)
                    }else if words.count==0{
                        words.removeAll()
                        current = 0
                        sizeofwords = 0
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
                    //    showcurrent(current: 0)
                    }
                    //selectedbook = book
                    //selectedstage = stage
                    //npage = page
                    newsave = "New"
                    editupdate = "Edit"
                }.buttonStyle(.bordered)
                //Spacer()
                Picker(selection:$selectedsearch, label: Text("検索")) {
                    ForEach (searchobjs, id: \.self) {
                        Text($0)
                    }
                }.pickerStyle(.menu)
                    .frame(width:100)
                    .clipped()
                    .contentShape(Rectangle())
                //Text("：")
                //Spacer()
                //Text( newsave )
                //.frame( width: .infinity, height: 50 )
                Button( newsave ) {
                    if newsave=="New" {
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
                //Text("本")
                Picker(selection:$selectedbook, label: Text("本")) {
                    ForEach (books, id: \.self) {
                        Text($0)
                    }
                }.pickerStyle(.menu)
                    //.frame(width:110)
                    .clipped()
                    .contentShape(Rectangle())
                
                Picker(selection:$selectedstage, label: Text("章")) {
                    ForEach (stages, id: \.self) {
                        Text($0)
                    }
                }.pickerStyle(.menu)
                    .frame(width:70)
                    .clipped()
                    .contentShape(Rectangle())
                Text("章")
                //Text("：")
                TextField("999", text: $npage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 46)
                    .border(Color.gray)
                    //.keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                Text("頁")
                //Spacer()
                TextField("999", text: $numb)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 46)
                    .border(Color.gray)
                    //.keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .disableAutocorrection(true)
                Text("番")
                //Spacer()
            }
            //Spacer()
        }   //.border(.gray)
            //.padding(.all)
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
                    TextField("単語", text: $eword, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        //.frame(width: 200)
                        .border(Color.gray)
                        //.autocapitalization(.none)
                        //.keyboardType(.asciiCapable)
                        //.multilineTextAlignment(.trailing)
                        .disableAutocorrection(true)
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
                    Text("意味")
                    /*
                    TextField("意味", text: $jword, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    //.frame(width: .infinity)
                        .border(Color.gray)
                        //.autocapitalization(.none)
                        //.keyboardType(.asciiCapable)
                        .disableAutocorrection(true)
                    */
                    
                    TextEditor(text: $jword)
                        .frame(height:50)
                        .border(Color.gray)
                        .font(.system(.subheadline, design: .monospaced))
                        .overlay(alignment: .topLeading) {
                            if text.isEmpty {
                                Text("")
                                    .allowsHitTesting(false)
                            }
                        }
                    
                }
                Spacer()
                HStack{
                    Text("語釈")
                    TextField("語釈", text: $ewexp, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    //.frame(width: .infinity)
                        .border(Color.gray)
                        //.autocapitalization(.none)
                        //.keyboardType(.asciiCapable)
                        .disableAutocorrection(true)
                }
                Spacer()
                HStack{
                    Text("類似")
                    TextField("類似語", text: $esim, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    //.frame(width: .infinity)
                        .border(Color.gray)
                        //.autocapitalization(.none)
                        //.keyboardType(.asciiCapable)
                        .disableAutocorrection(true)
                }
                Spacer()
                HStack{
                    Text("反対")
                    TextField("反対語", text: $einv, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    //.frame(width: .infinity)
                        .border(Color.gray)
                        //.autocapitalization(.none)
                        //.keyboardType(.asciiCapable)
                        .disableAutocorrection(true)
                }
                Spacer()
                HStack{
                    Text("関連")
                    TextField("関連語", text: $eassc, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    //.frame(width: .infinity)
                        .border(Color.gray)
                        //.autocapitalization(.none)
                        //.keyboardType(.asciiCapable)
                        .disableAutocorrection(true)
                }
                Spacer()
                HStack{
                    //VStack{
                        Text("英文")
                    //}
                    TextField("英文", text: $ebun, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    //.frame(width: .infinity)
                        .border(Color.gray)
                        //.autocapitalization(.none)
                        //.keyboardType(.asciiCapable)
                        .disableAutocorrection(true)
                }
                Spacer()
                HStack{
                    Text("和文")
                    /*
                    TextField("和文", text: $wbun, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    //.frame(width: .infinity)
                        .border(Color.gray)
                        //.autocapitalization(.none)
                        //.keyboardType(.asciiCapable)
                        .disableAutocorrection(true)
                     */
                    
                    TextEditor(text: $wbun)
                        .frame(height:70)
                        .border(Color.gray)
                        .font(.system(.subheadline, design: .monospaced))
                        .overlay(alignment: .topLeading) {
                            if text.isEmpty {
                                Text("")
                                    .allowsHitTesting(false)
                            }
                        }
                    
                }
                Spacer()
                HStack{
                    Text("備考")
                    /*
                    TextField("備考", text: $descr, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    //.frame(width: .infinity)
                        .border(Color.gray)
                        //.autocapitalization(.none)
                        //.keyboardType(.asciiCapable)
                        .disableAutocorrection(true)
                     */
                    
                    TextEditor(text: $descr)
                        .frame(height:50)
                        .border(Color.gray)
                        .font(.system(.subheadline, design: .monospaced))
                        .overlay(alignment: .topLeading) {
                            if text.isEmpty {
                                Text("")
                                    .allowsHitTesting(false)
                            }
                        }
                }
                //Spacer()
            }//.border(.gray)
            .padding(.all)
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
        )//.withAnimation(.spring())
        Divider()
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
                Button("CSV出力") {
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
                Button("CSV入力") {
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
                Button("JSON出力"){printAlert=true}
                    .alert("Random or Ascending ?", isPresented: $printAlert) {
                    Button("Random(All)") {
                        okActionPrintRandom()
                    }
                    Button("Ascending(All)") {
                        okActionPrintAll()
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

    }
}

#Preview {
    ContentView()
    //subView(word:"word")
}
