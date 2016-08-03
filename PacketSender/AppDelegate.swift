//
//  AppDelegate.swift
//  TcpSender
//
//  Created by sohunjug on 2016/7/26.
//  Copyright © 2016年 sohunjug. All rights reserved.
//

import Cocoa
import Foundation
import Darwin.C
import CocoaAsyncSocket


extension String {
    
    /// Create `NSData` from hexadecimal string representation
    ///
    /// This takes a hexadecimal representation and creates a `NSData` object. Note, if the string has any spaces or non-hex characters (e.g. starts with '<' and with a '>'), those are ignored and only hex characters are processed.
    ///
    /// - returns: Data represented by this hexadecimal string.
    
    func dataFromHexadecimalString() -> NSData? {
        let data = NSMutableData(capacity: characters.count / 2)
        
        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .CaseInsensitive)
        regex.enumerateMatchesInString(self, options: [], range: NSMakeRange(0, characters.count)) { match, flags, stop in
            let byteString = (self as NSString).substringWithRange(match!.range)
            var num = UInt8(byteString, radix: 16)
            data?.appendBytes(&num, length: 1)
        }
        
        return data
    }
}

extension NSData {
    
    /// Create hexadecimal string representation of `Data` object.
    ///
    /// - returns: `String` representation of this `Data` object.
    
    func hexadecimal() -> String {
        var string = ""
        var byte: UInt8 = 0
        
        for i in 0 ..< length {
            getBytes(&byte, range: NSMakeRange(i, 1))
            string += String(format: "%02x", byte)
        }
        
        return string
    }
}

extension NSTextView {
    
    func appendString(string s: String) {
        if let ts = textStorage {
            let ls = NSAttributedString(string: s)
            #if swift(>=3.0) // #swift3-1st-kwarg
                ts.append(ls)
            #else
                ts.appendAttributedString(ls)
            #endif
        }
        
        let charCount = (s as NSString).length
        self.scrollRangeToVisible(NSMakeRange(charCount, 0))
        needsDisplay = true
    }
    
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, GCDAsyncSocketDelegate, GCDAsyncUdpSocketDelegate {
    
    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var recvText: NSTextView!
    @IBOutlet weak var sendText: NSTextView!
    @IBOutlet weak var contentView: NSVisualEffectView!
    @IBOutlet weak var agreement: NSComboBox!
    @IBOutlet weak var connect: NSButton!
    @IBOutlet weak var ip: NSTextField!
    @IBOutlet weak var port: NSTextField!
    @IBOutlet weak var sendCount: NSTextField!
    
    private var recvaddress: NSData!
    private var tcpsocket: GCDAsyncSocket!
    private var tcpclient: GCDAsyncSocket!
    private var udpsocket: GCDAsyncUdpSocket!
    private var connectionFlag: Bool = true
    private let Defaults = NSUserDefaults.standardUserDefaults()
    
    func changeAppleInterfaceTheme(aNotification: NSNotification) {
        let appearance = NSUserDefaults.standardUserDefaults().stringForKey("AppleInterfaceStyle") ?? "Light"
        if appearance == "Dark" {
            self.window.appearance = NSAppearance.init(named: NSAppearanceNameVibrantDark)
            //self.contentView.material = NSVisualEffectMaterial.Dark
            //recvText.superview?.appearance = NSAppearance.init(named: NSAppearanceNameVibrantDark)
            recvText.appearance = NSAppearance.init(named: NSAppearanceNameVibrantDark)
        } else {
            self.window.appearance = NSAppearance.init(named: NSAppearanceNameVibrantLight)
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return false
    }
    
    func applicationShouldHandleReopen(sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if flag == false {
            for w in sender.windows {
                w.makeKeyAndOrderFront(self)
            }
        }
        return true
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // let appearance = NSUserDefaults.standardUserDefaults().stringForKey("AppleInterfaceStyle") ?? "Light"
        let initDefaults = NSDictionary.init(contentsOfFile: NSBundle.mainBundle().pathForResource("SenderConfig", ofType: "plist")!)
        Defaults.registerDefaults(initDefaults as! [String : AnyObject])
        NSDistributedNotificationCenter.defaultCenter().addObserver(self, selector: #selector(changeAppleInterfaceTheme(_:)), name: "AppleInterfaceThemeChangedNotification", object: nil)
        changeAppleInterfaceTheme(aNotification)
        agreement.selectItemAtIndex(Defaults.integerForKey("Agreement"))
        ip.stringValue = Defaults.stringForKey("IP")!
        port.stringValue = Defaults.stringForKey("Port")!
        sendText.string = Defaults.stringForKey("send_text")!
        recvText.string = Defaults.stringForKey("recv_text")!
        sendCount.stringValue = "1"
        //recvText.string = appearance
        // Insert code here to initialize your application
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    @IBAction func getMineIP(sender: NSButton) {
        ip.stringValue = "127.0.0.1"
    }
    
    @IBAction func recvClean(sender: NSButton) {
        recvText.string = ""
    }
    
    @IBAction func sendClean(sender: NSButton) {
        sendText.string = ""
    }
    
    @IBAction func connectAction(sender: NSButton) {
        do {
            if connectionFlag {
                switch agreement.indexOfSelectedItem {
                case 0:
                    tcpsocket = GCDAsyncSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
                    try tcpsocket.connectToHost(ip.stringValue, onPort: UInt16(port.integerValue))
                    break
                case 1:
                    tcpsocket = GCDAsyncSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
                    try tcpsocket.acceptOnPort(UInt16(port.integerValue))
                    if Defaults.boolForKey("recv_clean") == false {
                        recvText.string = ""
                    }
                    recvText.appendString(string: "> [ from " + ip.stringValue + ":" + port.stringValue + " ] TCP Server Started \n")
                    break
                case 2:
                    udpsocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
                    try udpsocket.connectToHost(ip.stringValue, onPort: UInt16(port.integerValue))
                    break
                case 3:
                    udpsocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
                    try udpsocket.bindToPort(UInt16(port.integerValue))
                    try udpsocket.beginReceiving()
                    if Defaults.boolForKey("recv_clean") == false {
                        recvText.string = ""
                    }
                    recvText.appendString(string: "> [ from " + ip.stringValue + ":" + port.stringValue + " ] UDP Server Started \n")
                default:
                    break
                }
                connectionFlag = false
            } else {
                switch agreement.indexOfSelectedItem {
                case 0:
                    tcpsocket.disconnect()
                    break
                case 1:
                    tcpsocket.disconnect()
                    break
                case 2:
                    udpsocket.close()
                    break
                case 3:
                    udpsocket.close()
                    recvaddress = nil
                    break
                default:
                    break
                }
                connectionFlag = true
            }
        } catch let e {
            print(e)
            connectionFlag = true
        }
        
        if connectionFlag {
            connect.title = "Connect"
            agreement.enabled = true
            connect.image = NSImage(contentsOfFile: NSBundle.mainBundle().pathForImageResource("disconnected")!)
        } else {
            connect.title = "Disconnect"
            agreement.enabled = false
            connect.image = NSImage(contentsOfFile: NSBundle.mainBundle().pathForImageResource("connected")!)
        }
        Defaults.setInteger(port.integerValue, forKey: "Port")
        Defaults.setInteger(agreement.indexOfSelectedItem, forKey: "Agreement")
        Defaults.setValue(ip.stringValue, forKey: "IP")
    }
    
    @IBAction func sendAction(sender: NSButton) {
        sendMul()
    }
    
    func sendMul() {
        var c = sendCount.integerValue
        if self.Defaults.boolForKey("send_loop") {
            c = 1
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
        while c > 0 && ((self.tcpsocket != nil && self.tcpsocket.isConnected) || (self.tcpclient != nil && self.tcpclient.isConnected) || (self.udpsocket != nil && (self.udpsocket.isConnected() || self.recvaddress != nil))) {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.sendFunction()
            })
            c = c - 1;
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.sendCount.stringValue = String(c)
            })
        }
            if c == 0 {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.sendCount.stringValue = "1"
            })
            }
        if self.Defaults.boolForKey("send_clean") == false {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.sendText.string = ""
            })
        }
        })
    }
    
    func sendFunction() {
        //var ret = (true, "")
        
        var data: NSData! = sendText.string?.dataUsingEncoding(NSUTF8StringEncoding)
        if connectionFlag == false {
            if Defaults.boolForKey("send_hex") == false {
                data = sendText.string?.dataFromHexadecimalString()
            }
            
            if Defaults.boolForKey("send_format") == false {
                var send: String = NSString(data: data, encoding: NSUTF8StringEncoding)! as String
                send = send.stringByReplacingOccurrencesOfString("\\r", withString: "\r")
                send = send.stringByReplacingOccurrencesOfString("\\n", withString: "\n")
                send = send.stringByReplacingOccurrencesOfString("\\t", withString: "\t")
                send = send.stringByReplacingOccurrencesOfString("\\0", withString: "\0")
                data = send.dataUsingEncoding(NSUTF8StringEncoding)
            }
            
            if Defaults.boolForKey("send_append") == false {
                var send: String = NSString(data: data, encoding: NSUTF8StringEncoding)! as String
                send = send + "\r\n"
                data = send.dataUsingEncoding(NSUTF8StringEncoding)
            }
            
            switch agreement.indexOfSelectedItem {
            case 0:
                //ret = tcpClient.send(str: sendText.string!)
                tcpsocket.writeData(data, withTimeout: 5, tag: 0)
                break
            case 1:
                //ret = tcpClient.send(str: sendText.string!)
                tcpclient.writeData(data, withTimeout: 5, tag: 1)
                break
            case 2:
                //ret = udpClient.send(str: sendText.string!)
                udpsocket.sendData(data, withTimeout: 5, tag: 2)
                break
            case 3:
                udpsocket.sendData(data, toAddress: recvaddress, withTimeout: 5, tag: 3)
                break
            default: break
            }
        }
    }
    
    func socket(sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        if Defaults.boolForKey("recv_clean") == false {
            recvText.string = ""
        }
        let from: String = sock.connectedHost! + ":" + String(sock.connectedPort)
        recvText.appendString(string: "> [ from " + from + " ] TCP Connected \n")
        tcpsocket.readDataWithTimeout(-1, tag: 1)
    }
    
    func socket(sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        if tcpclient == nil {
            tcpclient = newSocket
        }
        if Defaults.boolForKey("recv_clean") == false {
            recvText.string = ""
        }
        let from: String = tcpclient.connectedHost! + ":" + String(tcpclient.connectedPort)
        recvText.appendString(string: "> [ from " + from + " ] TCP Accepted \n")
        tcpclient.readDataWithTimeout(-1, tag: 1)
    }
    
    func socketDidDisconnect(sock: GCDAsyncSocket, withError err: NSError?) {
        if tcpclient == nil && tcpsocket.isConnected == false && Defaults.boolForKey("send_reconnect") == false && sendCount.integerValue > 1 {
            tcpsocket = GCDAsyncSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
            do {
                try tcpsocket.connectToHost(ip.stringValue, onPort: UInt16(port.integerValue))
                connectionFlag = false
            } catch {
                connectionFlag = true
            }
            sendMul()
            return
        }
        if tcpclient == nil || tcpclient == sock {
            tcpclient = nil
        }
        connectionFlag = true
        connect.title = "Connect"
        agreement.enabled = true
        recvText.appendString(string: "> TCP Disconnected \n")
    }
    
    func socket(sock: GCDAsyncSocket, didReadData data: NSData, withTag tag: Int) {
        let from: String = sock.connectedHost! + ":" + String(sock.connectedPort)
        var recvdata: String = String(data: data, encoding: NSUTF8StringEncoding)!
        if Defaults.boolForKey("recv_hex") == false {
            recvdata = data.hexadecimal()
        }
        if Defaults.boolForKey("recv_format") == false {
            recvdata = recvdata.stringByReplacingOccurrencesOfString("\r", withString: "\\r")
            recvdata = recvdata.stringByReplacingOccurrencesOfString("\n", withString: "\\n")
            recvdata = recvdata.stringByReplacingOccurrencesOfString("\t", withString: "\\t")
            recvdata = recvdata.stringByReplacingOccurrencesOfString("\0", withString: "\\0")
        }
        recvText.appendString(string: "> [ from " + from + " ] TCP Recved " + String(recvdata.characters.count) + "\n" + recvdata + "\n")
        tcpclient.readDataWithTimeout(-1, tag: tag)
    }
    
    func socket(sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        let from: String = sock.connectedHost! + ":" + String(sock.connectedPort)
        recvText.appendString(string: "> [ from " + from + " ] TCP Sended \n")
    }
    
    func udpSocket(sock: GCDAsyncUdpSocket, didConnectToAddress address: NSData) {
        if Defaults.boolForKey("recv_clean") == false {
            recvText.string = ""
        }
        let from: String = sock.connectedHost()! + ":" + String(sock.connectedPort())
        recvText.appendString(string: "> [ from " + from + " ] UDP Connected \n")
        do {
            try sock.beginReceiving()
        } catch {
            connectionFlag = true
            connect.title = "Connect"
            agreement.enabled = true
        }
    }
    
    func udpSocket(sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        var from: String!
        if sock.connectedHost() == nil {
            from = GCDAsyncUdpSocket.hostFromAddress(recvaddress)! + ":" + String(GCDAsyncUdpSocket.portFromAddress(recvaddress))
        } else {
            from = sock.connectedHost()! + ":" + String(sock.connectedPort())
        }
        recvText.appendString(string: "> [ from " + from + " ] UDP Sended \n")
    }
    
    func udpSocketDidClose(sock: GCDAsyncUdpSocket, withError error: NSError) {
        recvText.appendString(string: "> UDP Disconnected \n")
        recvaddress = nil
        connectionFlag = true
        connect.title = "Connect"
        agreement.enabled = true
    }
    
    func udpSocket(sock: GCDAsyncUdpSocket, didReceiveData data: NSData, fromAddress address: NSData, withFilterContext filterContext: AnyObject?) {
        let from: String = GCDAsyncUdpSocket.hostFromAddress(address)! + ":" + String(GCDAsyncUdpSocket.portFromAddress(address))
        recvaddress = address.copy() as! NSData
        var recvdata: String = String(data: data, encoding: NSUTF8StringEncoding)!
        if Defaults.boolForKey("recv_hex") == false {
            recvdata = data.hexadecimal()
        }
        if Defaults.boolForKey("recv_format") == false {
            recvdata = recvdata.stringByReplacingOccurrencesOfString("\r", withString: "\\r")
            recvdata = recvdata.stringByReplacingOccurrencesOfString("\n", withString: "\\n")
            recvdata = recvdata.stringByReplacingOccurrencesOfString("\t", withString: "\\t")
            recvdata = recvdata.stringByReplacingOccurrencesOfString("\0", withString: "\\0")
        }
        recvText.appendString(string: "> [ from " + from + " ] UDP Recved " + String(recvdata.characters.count) + "\n" + recvdata + "\n")
        do {
            try sock.beginReceiving()
        } catch {
            connectionFlag = true
            connect.title = "Connect"
            agreement.enabled = true
        }
    }
}

