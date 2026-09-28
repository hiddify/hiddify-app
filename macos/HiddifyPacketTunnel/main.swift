//
//  main.swift
//  HiddifyPacketTunnel
//
//  Created by ~NOTHING~ on 2026-09-27.
//

import Foundation
import NetworkExtension

autoreleasepool {
    // Register this process with NetworkExtension before handling provider events.
    NEProvider.startSystemExtensionMode()
}

// Keep the system extension alive to receive tunnel lifecycle callbacks.
dispatchMain()
