//
//  ViewController.swift
//  Swift Bonjour Browser
//
//  Created by Webber Lai on 7/4/16.
//  Copyright © 2016 Webber Lai. All rights reserved.
//

import UIKit

class ViewController: UIViewController  {
    
    @IBOutlet weak var tableView : UITableView?
    @IBOutlet weak var textfield : UITextField?
    @IBOutlet weak var sendMsgBtn: UIButton?
    @IBOutlet weak var receiveTextView : UITextView?
    
    var inputStream : InputStream?
    var outputStream : NSOutputStream?
    
    //NetService Browser
    var netServiceBrowser : NetServiceBrowser!
    var services     = [NetService]()
    
    /// Netservice
    let netService : NetService = NetService.init(domain: "local", type: "_myApp._tcp.", name: UIDevice.current().name,  port: Int32(54321))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.textfield?.delegate = self
    }
    
    @IBAction func scanDevice(sender:AnyObject!){
        print("Start Scan Device")
        self.services.removeAll()
        self.netServiceBrowser = NetServiceBrowser()
        self.netServiceBrowser.delegate = self
        self.netServiceBrowser.searchForServices(ofType: "_myApp._tcp", inDomain: "")
    }
    
    @IBAction func publishService(sender:AnyObject!){
        print("Start Publish Service")
        self.netService.delegate = self
        self.netService.schedule(in: RunLoop.current(), forMode: RunLoopMode.commonModes)
        self.netService.publish(NetService.Options.listenForConnections)
    }
    
    @IBAction func stopService(sender:AnyObject!){
        print("Stop Service")
        self.netService.stop()
    }
    
    @IBAction func sendMessage(sender:AnyObject!){
        
        guard let outputStream = self.outputStream else {
            print("Connection not create yet ! =====> Return")
            return
        }
        
        guard let text = textfield?.text,
            data: NSData = text.data(using: String.Encoding.utf8) else {
                print("no data")
                return
        }
        
        print("\(outputStream) ==> Pass Data : \(text)")
        outputStream.open()
        defer {
            print("Output Stream Close")
            //outputStream.close()
        }
        
        let result = outputStream.write(UnsafePointer<UInt8>(data.bytes), maxLength: data.length)
        if result == 0 {
            print("Stream at capacity")
        } else if result == -1 {
            print("Operation failed: \(outputStream.streamError)")
        } else {
            self.textfield?.text = ""
            print("The number of bytes written is \(result)")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateInterface () {
        for service in services {
            if service.port == -1 {
                print("\(service.name)" + " Not yet resolved")
                service.delegate = self
                service.resolve(withTimeout: 10)
            }else {
                tableView?.reloadData()
            }
        }
    }

    
    func initSockerCommunication( host:CFString , port : UInt32 ){
        
        print("HOST \(host) and the port : \(port)" )
        
        DispatchQueue.main.async {
            var readstream : Unmanaged<CFReadStream>?
            
            var writestream : Unmanaged<CFWriteStream>?
            
            CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, host, port, &readstream, &writestream)
            
            self.inputStream = readstream!.takeRetainedValue()
            self.outputStream = writestream!.takeRetainedValue()
            
            self.inputStream?.delegate = self
            self.outputStream?.delegate = self
            
            self.inputStream?.schedule(in: RunLoop.main(), forMode: RunLoopMode.defaultRunLoopMode)
            self.outputStream?.schedule(in: RunLoop.main(), forMode: RunLoopMode.defaultRunLoopMode)
            
            self.inputStream?.open()
            self.outputStream?.open()
        }
    }
    
    func getTheCFStringFromString(originStr : String ) -> CFString{
        let str = originStr as CFString
        return str
    }
    
    func getIPV4StringfromAddress(address: [Data] ) -> String{
        
        if  address.count == 0{
            return "0.0.0.0"
        }
        
        let data = address.first! as NSData
        
        var ip1 = UInt8(0)
        data.getBytes(&ip1, range: NSMakeRange(4, 1))
        
        var ip2 = UInt8(0)
        data.getBytes(&ip2, range: NSMakeRange(5, 1))
        
        var ip3 = UInt8(0)
        data.getBytes(&ip3, range: NSMakeRange(6, 1))
        
        var ip4 = UInt8(0)
        data.getBytes(&ip4, range: NSMakeRange(7, 1))
        
        let ipStr = String(format: "%d.%d.%d.%d",ip1,ip2,ip3,ip4)
        
        return ipStr
    }
}

extension ViewController : NetServiceBrowserDelegate{
    func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        print("netServiceBrowserWillSearch")
    }
    
    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        print("netServiceBrowserDidStopSearch")
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        print("netServiceBrowser didNotSearch Error \(errorDict)")
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        print("adding a service : \(service)")
        self.services.append(service)
        if !moreComing {
            self.updateInterface()
        }
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        print("removing a service : \(service)")
        if let index = services.index(of: service) {
            self.services.remove(at: index)
            if !moreComing {
                self.updateInterface()
            }
        }
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFindDomain domainString: String, moreComing: Bool) {
        print("netServiceBrowser didFindDomain Domain : \(domainString)")
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemoveDomain domainString: String, moreComing: Bool) {
        print("netServiceBrowser didRemoveDomain Domain : \(domainString)")
    }
}

extension ViewController : NetServiceDelegate {
        
        func netServiceWillPublish(_ sender: NetService) {
            print("netServiceWillPublish \(sender)")
        }
    
        func netServiceDidPublish(_ sender: NetService) {
            print("netServiceDidPublish \(sender)")
        }
    
        func netServiceWillResolve(_ sender: NetService) {
            print("netServiceWillResolve \(sender)")
        }
    
        func netServiceDidResolveAddress(_ sender: NetService) {
            print("netServiceDidResolveAddress service name \(sender.name) of type \(sender.type)," +
            "port \(sender.port), addresses \(sender.addresses)")
            self.updateInterface()
        }
    
        func netService(_ sender: NetService, didUpdateTXTRecord data: Data) {
            print("netService : \(sender) didUpdateTXTRecord Data : \(data)")
        }
    
        func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
            print("netService : \(sender) didNotPublish Error : \(errorDict)")
        }
    
        func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
            //If Got Errir -72001 => A publication or resolution request was sent to an NSNetService instance which was already published or a search request was made of an NSNetServiceBrowser instance which was already searching.
            print("netService : \(sender) didNotResolve Error : \(errorDict)")
        }
    
        func netServiceDidStop(_ sender: NetService) {
            print("netServiceDidStop : \(sender)")
        }
    
        func netService(_ sender: NetService, didAcceptConnectionWith inputStream: InputStream, outputStream: NSOutputStream) {
            
            self.receiveTextView?.text = "Accept Connection Success"
            
            print("netService : \(sender) didAcceptConnectionWith Input Stream : \(inputStream) , Output Stream : \(outputStream)")
            inputStream.delegate = self
            outputStream.delegate = self
            inputStream.schedule(in: RunLoop.main(), forMode: RunLoopMode.defaultRunLoopMode)
            outputStream.schedule(in: RunLoop.main(), forMode: RunLoopMode.defaultRunLoopMode)
            inputStream.open()
            outputStream.open()
        }
}

extension ViewController : StreamDelegate{
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch (eventCode){
        
        case Stream.Event.openCompleted:
            NSLog("Stream opened")
            break
        
        case Stream.Event.hasBytesAvailable:
            
            NSLog("HasBytesAvailable")

            var buffer = [UInt8](repeating:0, count:4096)
            
            let inputStream = aStream as? InputStream
            
            while ((inputStream?.hasBytesAvailable) != false){
                let len = inputStream?.read(&buffer, maxLength: buffer.count)
                if(len > 0){
                    let output = NSString(bytes: &buffer, length: buffer.count, encoding: String.Encoding.utf8.rawValue)
                    if (output != ""){
                        NSLog("Server Received : %@", output!)
                        self.receiveTextView?.text = output as String?
                    }
                }else{
                    //不然會While跑到死
                    break
                }
            }
            break
        
        case Stream.Event.errorOccurred:
            NSLog("ErrorOccurred")
            break
        case Stream.Event.endEncountered:
            NSLog("EndEncountered")
            break
        default:
            NSLog("unknown.")
        }
    }
}

extension ViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //Socket Start Connect
        
        let serv = services[indexPath.row] as NetService
        
        self.initSockerCommunication(host: self.getIPV4StringfromAddress(address: serv.addresses!) as CFString , port: UInt32(serv.port))
        
    }
}

extension ViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return services.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let service = services[indexPath.row]
        cell.textLabel?.text = service.name
        cell.detailTextLabel?.text = self.getIPV4StringfromAddress(address: service.addresses!)
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}


extension ViewController : UITextFieldDelegate{
    
     func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
