//
//  myCSV.swift
//  HelloEWord
//
//  Created by 的池秋成 on 2025/08/01.
//
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
    /*
     let str = "Hello, world!"
     let index = str.index(str.startIndex, offsetBy: 4)
     str[index] // returns Character 'o'

     let endIndex = str.index(str.endIndex, offsetBy:-2)
     str[index ..< endIndex] // returns String "o, worl"

     String(str.suffix(from: index)) // returns String "o, world!"
     String(str.prefix(upTo: index)) // returns String "Hell"
     */
}

class myCSV{

    var fname = "ECompoData"
    init(fname: String = "ECompoData"){
        self.fname = fname
    }
    func getFName() -> String {
        return self.fname+".csv"
    }

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
    func CSVDataGen() -> String{
        // heading of CSV file.
        let heading = "ID,連番,単語,品詞,意味,語釈,類似語,反意語,関連語,英文,和文,備考,本,章,頁,通番 \n"
        // file rows
        //let rows = "\(words.id),\(words.seq),\(words.word.csvEscaped),\(words.type.csvEscaped),\(words.mean.csvEscaped),\(words.expr.csvEscaped),\(words.simlr.csvEscaped),\(words.invrt.csvEscaped),\(words.relat.csvEscaped),\(words.eibun.csvEscaped),\(words.wabun.csvEscaped),\(words.descr.csvEscaped),\(words.book.csvEscaped),\(words.stage.csvEscaped),\(words.page)\(words.numb)\n"
        
        //let rows = words.map { "\($0.id),\($0.seq),\"\($0.word.replacingOccurrences(of: "\n", with: "\\n"))\",\($0.type),\"\($0.mean.replacingOccurrences(of: "\n", with: "\\n"))\",\"\($0.expr.replacingOccurrences(of: "\n", with: "\\n"))\",\"\($0.simlr.replacingOccurrences(of: "\n", with: "\\n"))\",\"\($0.invrt.replacingOccurrences(of: "\n", with: "\\n"))\",\"\($0.relat.replacingOccurrences(of: "\n", with: "\\n"))\",\"\($0.eibun.replacingOccurrences(of: "\n", with: "\\n"))\",\"\($0.wabun.replacingOccurrences(of: "\n", with: "\\n"))\",\"\($0.descr.replacingOccurrences(of: "\n", with: "\\n"))\",\($0.book),\($0.stage),\($0.page),\($0.numb)" }
        let rows = words.map { "\($0.id),\($0.seq),\"\($0.word)\",\($0.type),\"\($0.mean)\",\"\($0.expr)\",\"\($0.simlr)\",\"\($0.invrt)\",\"\($0.relat)\",\"\($0.eibun)\",\"\($0.wabun)\",\"\($0.descr)\",\($0.book),\($0.stage),\($0.page),\($0.numb)" }
        // rows to string data
        let stringData = heading + rows.joined(separator: "\n")
        return stringData
    }
    
    func generateCSV() -> URL {
        var fileURL: URL!
        let stringData = CSVDataGen()
        do {
            let path = try FileManager.default.url(for: .documentDirectory,
                                                   in: .allDomainsMask,
                                                   appropriateFor: nil,
                                                   create: false)
            //fileURL = path.appendingPathComponent("EWordData.csv")
            fileURL = path.appendingPathComponent(getFName())
            // append string data to file
            try stringData.write(to: fileURL, atomically: true , encoding: .utf8)
            print(fileURL!)
        } catch {
            print("error : generating csv file")
        }
        return fileURL
    }
    /* Generate csv */
    func fileContents(file: URL) -> String{
        // アクセス権取得
        let gotAccess = file.startAccessingSecurityScopedResource()
        if !gotAccess { return ""}
        // ファイルの内容を取得する
        //let filename = file.lastPathComponent
        //let directoryURL = file.deletingLastPathComponent()
        //let folder = URL(fileURLWithPath: directoryURL.path)
        //let filen = folder.appendingPathComponent(filename)
        //print("file://"+directoryURL.path+"/"+filename)
        var text: String = ""
        do {
            text = try String(contentsOf: file, encoding: String.Encoding.utf8)
        } catch {
            print(error.localizedDescription)
        }
        // アクセス権解放
        file.stopAccessingSecurityScopedResource()
        return text
    }
    
    func reshape(url: URL) -> [[String]]{
        var outdata: [[String]] = [[]]
        var csvdata: [String] = []
        var str: String = ""
        var flag: Bool = false
        let textString: String = fileContents(file: url)
        let lineChange = textString.replacingOccurrences(of: "\r", with: "\n")
        var lineArray: [String] = lineChange.components(separatedBy: "\n")
        if lineArray.last!.isEmpty{
            lineArray.removeLast()
        }
        for line in lineArray {
            var CR: Bool = false
            if flag {
                CR = true
            }
            let dataArray: [String] = line.components(separatedBy: ",")
            if(dataArray[0]=="ID"){continue}
            for data in dataArray{
                var CM: Bool = false
                if flag {
                    CM = true
                }
                if data=="\"" {
                    if flag {
                        csvdata.append(str.replacingOccurrences(of:"\"", with:""))
                        flag = false
                        CM = false
                        CR = false
                    }else{
                        flag=true
                    }
                } else if (!data.hasPrefix("\"")&&(!data.hasSuffix("\""))){
                    if flag {
                        var sep:String = ""
                        if CM {
                            sep = ", "
                        }
                        if CR {
                            sep = "\n"
                        }
                        if str.isEmpty {
                            if CM||CR {
                                str = sep + data
                            }else{
                                str = data
                            }
                            
                        }else{
                            if CM||CR {
                                str = str + sep + data
                            }else{
                                str += data
                            }
                        }
                        if CM {CM=false}
                        if CR {CR=false}
                    }else{
                        csvdata.append(data.replacingOccurrences(of:"\"", with:""))
                        CM = false
                        CR = false
                    }
                }else if (data.hasPrefix("\"")&&(data.hasSuffix("\""))){
                    csvdata.append(data.replacingOccurrences(of:"\"", with:""))
                    CM = false
                    CR = false
                }else if (data.hasPrefix("\"")&&(!data.hasSuffix("\""))){
                    str = data
                    flag = true
                }else if ((!data.hasPrefix("\""))&&(data.hasSuffix("\""))){
                    if str.isEmpty {
                        str = data
                    }else{
                        var sep:String = ""
                        if CM {
                            sep = ", "
                        }
                        if CR {
                            sep = "\n"
                        }
                        if CR||CM {
                            str = str + sep + data
                        }else{
                            str += data
                        }
                        if CM {CM=false}
                        if CR {CR=false}
                    }
                    csvdata.append(str.replacingOccurrences(of:"\"", with:""))
                    flag = false
                    CM = false
                    CR = false
                }
                if 16==csvdata.count{
                    if csvdata[0]==""{
                        csvdata.removeFirst()
                    }
                    outdata.append(csvdata)
                    csvdata.removeAll()
                }
            }
        }
        return outdata
    }

}
