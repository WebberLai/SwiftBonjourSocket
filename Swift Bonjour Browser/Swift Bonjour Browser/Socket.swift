//
//  Socket.swift
//  Swift Bonjour Browser
//
//  Created by Roca Developer on 2016/7/14.
//  Copyright © 2016年 Roca Developer. All rights reserved.
//

import UIKit

enum SocketState : Int {
    case Init = 0
    case connect = 1
    case disconnect = 2
    case errorOccurred = 3
    
}

class Socket: NSObject {
    
    var inputStream  : InputStream?
    var outputStream : OutputStream?
    var runloop      : RunLoop?
    var status : Int = -1
    var timeout      : Float = 5.0;
    weak var mStreamDelegate:StreamDelegate?

    func initSockerCommunication( _ host:CFString , port : UInt32 ){
        
        DispatchQueue.global().async {
            
            var readstream : Unmanaged<CFReadStream>?
            var writestream : Unmanaged<CFWriteStream>?
            
            CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, host, port, &readstream, &writestream)
        
            self.inputStream = readstream!.takeRetainedValue()
            self.outputStream = writestream!.takeRetainedValue()
            
            self.inputStream?.delegate = self
            self.outputStream?.delegate = self
            
            self.inputStream?.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
            self.outputStream?.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
            
            self.inputStream?.open()
            self.outputStream?.open()
        }
    }
    
    func setStreamDelegate(_ delegete:StreamDelegate){
        mStreamDelegate = delegete
    }
    
    func getInputStream() -> InputStream{
        return self.inputStream!
    }
    
    func getOutputStream() -> OutputStream {
        return self.outputStream!
    }
}

extension Socket : StreamDelegate{
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch (eventCode){
            
        case Stream.Event.openCompleted:
            self.status = SocketState.connect.rawValue
            break
            
        case Stream.Event.hasBytesAvailable:
            break
            
        case Stream.Event.errorOccurred:
            break
            
        case Stream.Event.endEncountered:
            self.status = SocketState.errorOccurred.rawValue
            break
            
        default:
            print("")
        }
        mStreamDelegate?.stream?(aStream, handle: eventCode)
    }
}
