//
//  SmpFileDocument.swift
//  HelloEWord
//
//  Created by 的池秋成 on 2025/08/01.
//
//
// https://swappli.com/fileimporter1/
// https://swiftwithmajid.com/2023/05/10/file-importing-and-exporting-in-swiftui/
//

import SwiftUI

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
/*
/// /Documents/hogeディレクトリ内の操作するやつ
/// https://qiita.com/am10/items/3b2eb3d9f6c6955455b6
struct HogeFileOperator {
    private let fileManager = FileManager.default
    private let rootDirectory = NSHomeDirectory() + "/Documents/hoge"

    init() {
        // ルートディレクトリを作成する
        createDirectory(atPath: "")
    }

    private func convertPath(_ path: String) -> String {
        if path.hasPrefix("/") {
            return rootDirectory + path
        }
        return rootDirectory + "/" + path
    }

    /// ディレクトリを作成する
    /// - Parameter path: 対象パス
    func createDirectory(atPath path: String) {
        if fileExists(atPath: path) {
            return
        }
        do {
           try fileManager.createDirectory(atPath: convertPath(path), withIntermediateDirectories: false, attributes: nil)
        } catch let error {
            print(error.localizedDescription)
        }
    }

    /// ファイルを作成する
    /// - Parameters:
    ///   - path: 保存先ファイルパス
    ///   - contents: コンテンツ
    func createFile(atPath path: String, contents: Data?) {
        // 同名ファイルがある場合は上書きされるので判定いるかも？
//        if fileExists(atPath: path) {
//            print("already exists file: \(NSString(string: path).lastPathComponent)")
//            return
//        }
        if !fileManager.createFile(atPath: convertPath(path), contents: contents, attributes: nil) {
            print("Create file error")
        }
    }

    /// ファイルがあるか確認する
    /// - Parameter path: 対象ファイルパス
    /// - Returns: ファイルがあるかどうか
    func fileExists(atPath path: String) -> Bool {
        return fileManager.fileExists(atPath: convertPath(path))
    }

    /// 対象パスがディレクトリか確認する
    /// - Parameter path: 対象パス
    /// - Returns:ディレクトリかどうか（存在しない場合もfalse）
    func isDirectory(atPath path: String) -> Bool {
        var isDirectory: ObjCBool = false
        fileManager.fileExists(atPath: convertPath(path), isDirectory: &isDirectory)
        return isDirectory.boolValue
    }

    /// ファイルを移動する
    /// - Parameters:
    ///   - srcPath: 移動元ファイルパス
    ///   - dstPath: 移動先ファイルパス
    func moveItem(atPath srcPath: String, toPath dstPath: String) {
        // 移動先に同名ファイルが存在する場合はエラー
        do {
           try fileManager.moveItem(atPath: convertPath(srcPath), toPath: convertPath(dstPath))
        } catch let error {
            print(error.localizedDescription)
        }
    }

    /// ファイルをコピーする
    /// - Parameters:
    ///   - srcPath: コピー元ファイルパス
    ///   - dstPath: コピー先ファイルパス
    func copyItem(atPath srcPath: String, toPath dstPath: String) {
        // コピー先に同名ファイルが存在する場合はエラー
        do {
           try fileManager.copyItem(atPath: convertPath(srcPath), toPath: convertPath(dstPath))
        } catch let error {
            print(error.localizedDescription)
        }
    }

    /// ファイルを削除する
    /// - Parameter path: 対象ファイルパス
    func removeItem(atPath path: String) {
        do {
           try fileManager.removeItem(atPath: convertPath(path))
        } catch let error {
            print(error.localizedDescription)
        }
    }

    /// ファイルをリネームする
    /// - Parameters:
    ///   - path: 対象ファイルパス
    ///   - newName: 変更後のファイル名
    func renameItem(atPath path: String, to newName: String) {
        let srcPath = path
        let dstPath = NSString(string: NSString(string: srcPath).deletingLastPathComponent).appendingPathComponent(newName)
        moveItem(atPath: srcPath, toPath: dstPath)
    }

    // ディレクトリ内のアイテムのパスを取得する
    /// - Parameter path: 対象ディレクトリパス
    /// - Returns:対象ディレクトリ内のアイテムのパス一覧
    func contentsOfDirectory(atPath path: String) -> [String] {
        do {
           return try fileManager.contentsOfDirectory(atPath: convertPath(path))
        } catch let error {
            print(error.localizedDescription)
            return []
        }
    }

    /// ディレクトリ内のアイテムのパスを再帰的に取得する
    /// - Parameter path: 対象ディレクトリパス
    /// - Returns:対象ディレクトリ内のアイテムのパス一覧
    func subpathsOfDirectory(atPath path: String) -> [String] {
        do {
           return try fileManager.subpathsOfDirectory(atPath: convertPath(path))
        } catch let error {
            print(error.localizedDescription)
            return []
        }
    }

    /// ファイル情報を取得する
    /// - Parameter path: 対象ファイルパス
    /// - Returns: 対象ファイルの情報（作成日など）
    func attributesOfItem(atPath path: String) -> [FileAttributeKey : Any] {
        do {
           return try fileManager.attributesOfItem(atPath: convertPath(path))
        } catch let error {
            print(error.localizedDescription)
            return [:]
        }
    }
}
*/
/*
// こんな感じで使う
let hoge = HogeFileOperator()
hoge.createDirectory(atPath: "fuga")
hoge.createDirectory(atPath: "fuga/foo")
print(hoge.isDirectory(atPath: "fuga")) // true
hoge.createFile(atPath: "fuga/piyo.txt", contents: "あいうえお".data(using: .utf8))
hoge.copyItem(atPath: "fuga/piyo.txt", toPath: "fuga/piyoコピー.txt")
hoge.copyItem(atPath: "fuga/piyo.txt", toPath: "fuga/piyoコピー2.txt")
hoge.moveItem(atPath: "fuga/piyo.txt", toPath: "fuga/foo/piyo.txt")
hoge.removeItem(atPath: "fuga/piyoコピー2.txt")
hoge.renameItem(atPath: "fuga/piyoコピー.txt", to: "コピーです.txt")
print(hoge.contentsOfDirectory(atPath: "")) // ["fuga"]
print(hoge.subpathsOfDirectory(atPath: "")) // ["fuga", "fuga/コピーです.txt", "fuga/foo", "fuga/foo/piyo.txt"]
let attributes = hoge.attributesOfItem(atPath: "fuga/コピーです.txt")
*/
