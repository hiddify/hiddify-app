//
//  TrafficReader.swift
//  SingBoxPacketTunnel
//
//  Created by GFWFighter on 7/25/1402 AP.
//

import Foundation

struct TrafficReaderUpdate: Codable {
    let up: Int64
    let down: Int64
}


class TrafficReader {
    private var task: URLSessionWebSocketTask!
    private let callback: (TrafficReaderUpdate) -> ()
    
    init(onUpdate: @escaping (TrafficReaderUpdate) -> ()) {
        self.callback = onUpdate
        Task(priority: .background) { [weak self] () in
            await self?.setup()
        }
    }
    
    private func setup() async {
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        //return
        while true {
            do {
                let (_, response) = try await URLSession.shared.data(from: URL(string: "http://127.0.0.1:10864")!)
                let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                if code >= 200 && code < 300 {
                    break
                }
            } catch {
                // pass
            }
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
        let task = URLSession.shared.webSocketTask(with: URL(string: "ws://127.0.0.1:10864/traffic")!)
        self.task = task
        read()
        task.resume()
    }
    
    private func read() {
        task.receive { [weak self] result in
            switch result {
            case .failure(_):
                break
            case .success(let message):
                switch message {
                case .string(let message):
                    guard let data = message.data(using: .utf8) else {
                        break
                    }
                    guard let response = try? JSONDecoder().decode(TrafficReaderUpdate.self, from: data) else {
                        break
                    }
                    self?.callback(response)
                default:
                    break
                }
                self?.read()
            }
        }
    }
}
