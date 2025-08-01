//
//  SmpFileDocument.swift
//  HelloECompo
//
//  Created by 的池秋成 on 2025/08/01.
//
//
import SwiftUI
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
