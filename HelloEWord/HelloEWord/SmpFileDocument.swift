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
    static var readableContentTypes: [UTType] { [.json, .commaSeparatedText, .plainText] }
    static var writableContentTypes: [UTType] { [.json, .commaSeparatedText, .plainText] }

    var text: String

    init(text: String = "") {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents,
           let decoded = String(data: data, encoding: .utf8) {
            text = decoded
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8) ?? Data()
        return FileWrapper(regularFileWithContents: data)
    }
}
