//
//  CSV.swift
//  HelloECompo
//
//  Created by 的池秋成 on 2025/08/01.
//
import SwiftUI

class CSV{

    var fname = "ECompoData"
    init(fname: String = "ECompoData"){
        self.fname = fname
    }
    func getFName() -> String {
        return self.fname+".csv"
    }

    func CSVDataGen() -> String{
        // heading of CSV file.
        let heading = "ID,英文,和文,ヒント,行,頁,章,題目,主題,分野,本,備考 \n"
        // file rows
        //id, eibun, wabun, hint, line, page, chap, title, topic, field, book, description
        let rows = records.map { "\($0.id),\"\($0.eibun)\",\"\($0.wabun)\",\"\($0.hint)\",\($0.line),\($0.page),\($0.chap),\"\($0.title)\",\"\($0.topic)\",\"\($0.field)\",\($0.book),\"\($0.description)\"" }
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
            //fileURL = path.appendingPathComponent("ECompoData.csv")
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
                if 12==csvdata.count{
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
