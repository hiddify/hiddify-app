//
//  Logger.swift
//  SingBoxPacketTunnel
//
//  Created by GFWFighter on 10/24/23.
//

import Foundation

class Logger {
    private static let queue = DispatchQueue.init(label: "\(FilePath.packageName).PacketTunnelLog", qos: .utility)
    
    private let fileManager = FileManager.default
    private let url: URL
    
    private var _fileHandle: FileHandle?
    private var fileHandle: FileHandle? {
        get {
            if let _fileHandle { return _fileHandle }
            let handle = try? FileHandle(forWritingTo: url)
            _fileHandle = handle
            return handle
        }
    }
    
    private var lock = NSLock()
    
    init(path: URL) {
        url = path
    }
    
    func write(_ message: String) {
        Logger.queue.async { [message, unowned self] () in
            lock.lock()
            defer { lock.unlock() }
            let output = message + "\n"
            do {
                if !self.fileManager.fileExists(atPath: url.path) {
                    try output.write(to: url, atomically: true, encoding: .utf8)
                } else {
                    guard let fileHandle else {
                        return
                    }
                    fileHandle.seekToEndOfFile()
                    if let data = output.data(using: .utf8) {
                        fileHandle.write(data)
                    }
                }
            } catch {}
        }
    }
}
