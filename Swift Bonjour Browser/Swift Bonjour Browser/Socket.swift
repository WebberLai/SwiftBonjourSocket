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
    case Connect = 1
    case Disconnect = 2
    case ErrorOccurred = 3
    
}

class Socket: NSObject {
    
    var inputStream  : InputStream?
    var outputStream : NSOutputStream?
    var runloop      : RunLoop?
    var status : Int = -1
    var timeout      : Float = 5.0;
    weak var mStreamDelegate:StreamDelegate?

    func initSockerCommunication( host:CFString , port : UInt32 ){
        DispatchQueue.main.async {
            
            var readstream : Unmanaged<CFReadStream>?
            var writestream : Unmanaged<CFWriteStream>?
            
            CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, host, port, &readstream, &writestream)
        
            self.inputStream = readstream!.takeRetainedValue()
            self.outputStream = writestream!.takeRetainedValue()
            
            self.inputStream?.delegate = self
            self.outputStream?.delegate = self
            
            self.inputStream?.schedule(in: RunLoop.current(), forMode: RunLoopMode.defaultRunLoopMode)
            self.outputStream?.schedule(in: RunLoop.current(), forMode: RunLoopMode.defaultRunLoopMode)
            
            self.inputStream?.open()
            self.outputStream?.open()
        }
    }
    
    func setStreamDelegate(delegete:StreamDelegate){
        mStreamDelegate = delegete
    }
    
    func getInputStream() -> InputStream{
        return self.inputStream!
    }
    
    func getOutputStream() -> NSOutputStream {
        return self.outputStream!
    }
}

extension Socket : StreamDelegate{
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch (eventCode){
            
        case Stream.Event.openCompleted:
            self.status = SocketState.Connect.rawValue
            NSLog("Stream opened")
            break
            
        case Stream.Event.hasBytesAvailable:
            NSLog("HasBytesAvailable")
            break
            
        case Stream.Event.errorOccurred:
            NSLog("ErrorOccurred")
            break
            
        case Stream.Event.endEncountered:
            self.status = SocketState.ErrorOccurred.rawValue
            NSLog("EndEncountered")
            break
            
        default:
            NSLog("unknown.")
        }
        mStreamDelegate?.stream?(aStream, handle: eventCode)
    }
}
