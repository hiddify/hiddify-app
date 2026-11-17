//
//  FilePath.swift
//  SingBoxPacketTunnel
//
//  Created by GFWFighter on 7/25/1402 AP.
//

import Foundation

public enum FilePath {
    public static let packageName = {
        Bundle.main.infoDictionary?["BASE_BUNDLE_IDENTIFIER"] as? String ?? "unknown"
    }()
}

public extension FilePath {
    static let groupName = "group.\(packageName)"

    private static let defaultSharedDirectory: URL! = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: FilePath.groupName)

    static let sharedDirectory = defaultSharedDirectory!

    static let cacheDirectory = sharedDirectory
        .appendingPathComponent("Library", isDirectory: true)
        .appendingPathComponent("Caches", isDirectory: true)

    /// In Library/Application Support, which iOS keeps: it empties Library/Caches when storage runs
    /// low, and the profiles' configs in here are their only copy. With them gone, no profile could
    /// connect until the app was installed again (#2548).
    static let workingDirectory = sharedDirectory
        .appendingPathComponent("Library", isDirectory: true)
        .appendingPathComponent("Application Support", isDirectory: true)
        .appendingPathComponent("Working", isDirectory: true)

    /// Where the working directory was before (#2548).
    private static let cachesWorkingDirectory = cacheDirectory.appendingPathComponent("Working", isDirectory: true)

    /// Creates the working directory, moving the old one out of Library/Caches the first time. The
    /// app and the packet tunnel both call it; whichever comes second finds the move done.
    static func prepareWorkingDirectory() {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: cachesWorkingDirectory.path) {
            if !fileManager.fileExists(atPath: workingDirectory.path) {
                try? fileManager.createDirectory(
                    at: workingDirectory.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try? fileManager.moveItem(at: cachesWorkingDirectory, to: workingDirectory)
            }
            // What is still in the old directory is moved item by item: the move above can fail
            // (the other process moving it at the same time, a file in use), and the new directory
            // made below then stopped any later move, leaving the profiles in Library/Caches.
            moveRemainingItems(from: cachesWorkingDirectory, to: workingDirectory, fileManager: fileManager)
        }
        try? fileManager.createDirectory(at: workingDirectory, withIntermediateDirectories: true)
        // as in Library/Caches, not part of a device backup: it holds rule sets and caches too
        var directory = workingDirectory
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? directory.setResourceValues(values)
    }

    /// Moves what [source] still holds into [destination], into its folders too, keeping what is
    /// there already, and removes [source] once it is empty.
    private static func moveRemainingItems(from source: URL, to destination: URL, fileManager: FileManager) {
        guard fileManager.fileExists(atPath: source.path) else { return }
        try? fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
        let items = (try? fileManager.contentsOfDirectory(at: source, includingPropertiesForKeys: [.isDirectoryKey])) ?? []
        for item in items {
            let target = destination.appendingPathComponent(item.lastPathComponent)
            let isDirectory = (try? item.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if !fileManager.fileExists(atPath: target.path) {
                try? fileManager.moveItem(at: item, to: target)
            } else if isDirectory {
                moveRemainingItems(from: item, to: target, fileManager: fileManager)
            }
        }
        if ((try? fileManager.contentsOfDirectory(atPath: source.path)) ?? []).isEmpty {
            try? fileManager.removeItem(at: source)
        }
    }
}

public extension URL {
    var fileName: String {
        var path = relativePath
        if let index = path.lastIndex(of: "/") {
            path = String(path[path.index(index, offsetBy: 1)...])
        }
        return path
    }
}
