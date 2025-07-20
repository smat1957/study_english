//
//  ContentView.swift
//  EWatch Watch App
//
//  Created by 的池秋成 on 2024/10/31.
//
// https://qiita.com/AS_atsushi/items/77c2389a7f21f15c4865
// https://devops-blog.virtualtech.jp/entry/20230105/1672886601
//
import SwiftUI
import WatchConnectivity

struct ContentView: View {
    
    @ObservedObject var connector = PhoneConnector()
    @State private var opacity = 0.0

    //@State private var isDragging:Bool = false
    var drag: some Gesture {
        DragGesture()
        //.onChanged {/*_ in self.isDragging = true*/}
            .onEnded {
                gesture in
                let horizontalTranslation = gesture.translation.width
                let verticalTranslation = gesture.translation.height
                if abs(horizontalTranslation) > abs(verticalTranslation) {
                    // 水平方向のスワイプ
                    if horizontalTranslation > 0 {
                        // 右にスワイプした場合の処理
                        //self.labelText = "右にスワイプしました"
                        if 0 < connector.current {
                            connector.current -= 1
                            self.connector.send(req:-1)
                        }
                    } else {
                        // 左にスワイプした場合の処理
                        //self.labelText = "左にスワイプしました"
                        if connector.current < connector.size-1{
                            connector.current += 1
                            self.connector.send(req:+1)
                        }
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
                //_ in self.isDragging = false
            }
    }
    
    var body: some View {
        VStack{
            //Spacer()
            Text("[ "+connector.book+" ]")
                .font(.body)
                .foregroundColor(Color.gray)
            //Spacer()
            HStack{
                Text("("+String(connector.current+1)+"/"+String(connector.size)+"),")
                    .font(.body)
                    .foregroundColor(Color.gray)
                Text("章("+connector.stage+"),")
                    .font(.body)
                    .foregroundColor(Color.gray)
                Text("頁("+connector.page+")")
                    .font(.body)
                    .foregroundColor(Color.gray)
            }
            Spacer()
            HStack{
                Button(
                    action: {
                        if 0 < connector.current {
                            connector.current -= 1
                            self.connector.send(req:-1)
                        }
                    },
                    label: { Text("<") }
                ).frame(width: 20, height: 32)
                Spacer()
                Text(connector.eword)
                    .font(.body)
                    .foregroundColor(Color.gray)
                    .onTapGesture {
                        if self.opacity==0.0 {
                            self.opacity = 1.0
                        }else{
                            self.opacity = 0.0
                        }
                    }
                Spacer()
                Button(
                    action: {
                        if connector.current < connector.size-1 {
                            connector.current += 1
                            self.connector.send(req:+1)
                        }
                    },
                    label: { Text(">") }
                ).frame(width: 20, height: 32)
            }
            Spacer()
            Text(connector.jword)
                .font(.body)
                .foregroundColor(Color.gray)
                .opacity(opacity)       // 不透明度の設定
            //Slider(value: $opacity, in: 0...1.0)
            //    .frame(height: 10)
            //Spacer()
        }.gesture(drag)
        //.withAnimation(.spring())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

class PhoneConnector: NSObject, ObservableObject, WCSessionDelegate {
    @Published var receivedMessage = "PHONE : 未受信"
    @Published var receivedStrArray:[String] = []
    @Published var current = 0
    @Published var size = 0
    @Published var seq = ""
    @Published var eword = ""
    @Published var jword = ""
    @Published var type = ""
    @Published var book = ""
    @Published var stage = ""
    @Published var page = ""

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func unpack(){
        self.current = Int(receivedStrArray[0])!
        self.size = Int(receivedStrArray[1])!
        self.eword = receivedStrArray[2]
        self.jword = receivedStrArray[3]
        self.seq = receivedStrArray[4]
        self.type = receivedStrArray[5]
        self.book = receivedStrArray[6]
        self.stage = receivedStrArray[7]
        self.page = receivedStrArray[8]
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("activationDidCompleteWith state= \(activationState.rawValue)")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("didReceiveMessage: \(message)")
                
        DispatchQueue.main.async {
            self.receivedMessage = "PHONE : \(message["PHONE_RES"] as! [String])"
            self.receivedStrArray = message["PHONE_RES"] as! [String]
            self.unpack()
        }
    }
    
    func send(req:Int) {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(["WATCH_REQ": req], replyHandler: nil) {
                error in
                print(error)
            }
        }
    }
}

#Preview {
    ContentView()
}
