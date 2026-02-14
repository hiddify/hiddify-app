//
//  main.swift
//  PrivilegedHelper
//
//  Created by Aleksandr Strizhnev on 18.02.2025.
//

import XPC
import OSLog
import Foundation

let logger = Logger(subsystem: "hiddify-helper", category: "SingBoxHelper")

class ServiceDelegate: NSObject, NSXPCListenerDelegate {
    func listener(
        _ listener: NSXPCListener,
        shouldAcceptNewConnection newConnection: NSXPCConnection
    ) -> Bool {

        logger.info("[\(Date())] New connection attempt")
        
        newConnection.exportedInterface = NSXPCInterface(with: SingboxProtocol.self)
        
        newConnection.remoteObjectInterface = NSXPCInterface(with: SingboxReceiverProtocol.self)
        
        let exportedObject = Singbox(receiver: newConnection.remoteObjectProxy as? SingboxReceiverProtocol)
        newConnection.exportedObject = exportedObject
        
        newConnection.interruptionHandler = {
            logger.error("[\(Date())] Connection interrupted")
        }
        
        newConnection.invalidationHandler = {
            logger.error("[\(Date())] Connection invalidated")
        }
        
        newConnection.resume()
        logger.info("[\(Date())] Connection accepted")
        return true
    }
}

func startService() {
    let delegate = ServiceDelegate()
    let listener = NSXPCListener(machServiceName: "app.hiddify.com.daemon.xpc")
    
    listener.delegate = delegate
    
    signal(SIGTERM) { _ in
        logger.error("[\(Date())] Received SIGTERM, shutting down...")
        exit(0)
    }
    
    logger.info("[\(Date())] Service starting...")
    listener.resume()
    
    RunLoop.main.run()
}

startService()
