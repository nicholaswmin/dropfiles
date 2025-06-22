import Foundation
import SwiftUI
import OSLog
@preconcurrency import Network

@MainActor
@Observable
final class FileSyncManager: NSObject, NSFilePresenter {
    // MARK: - State Properties
    
    private var bookmarkData: Data? {
        didSet { 
            UserDefaults.standard.set(bookmarkData, forKey: "watchedFolderBookmark")
        }
    }
    
    var autoSyncEnabled = true {
        didSet {
            UserDefaults.standard.set(autoSyncEnabled, forKey: "autoSyncEnabled")
            if autoSyncEnabled { setupSyncTimer() }
        }
    }
    
    var syncInterval = Constants.syncInterval {
        didSet {
            UserDefaults.standard.set(syncInterval, forKey: "syncInterval")
            setupSyncTimer()
        }
    }
    
    // MARK: - Dependencies
    
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.dropfiles",
        category: "sync"
    )
    private let monitor = NWPathMonitor()
    private var fileMonitor: FileMonitor?
    private var syncTimer: Timer?
    
    // MARK: - State
    
    private(set) var syncState = SyncState(status: .idle, lastSyncDate: nil)
    private(set) var isConnected = false
    private(set) var iCloudAvailable = false
    var recentChanges: [FileMonitor.FileChange] = []
    
    // MARK: - Computed Properties
    
    var statusIcon: String { syncState.statusIcon }
    var statusText: String { syncState.statusText }
    var statusColor: Color { syncState.statusColor }
    
    var canSync: Bool {
        isConnected && watchedFolderURL != nil && iCloudAvailable
    }
    
    private var watchedFolderURL: URL? {
        guard let data = bookmarkData else { return nil }
        var isStale = false
        return try? URL(
            resolvingBookmarkData: data,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
    }
    
    // MARK: - NSFilePresenter
    
    nonisolated var presentedItemURL: URL? { 
        MainActor.assumeIsolated {
            watchedFolderURL
        }
    }
    let presentedItemOperationQueue = OperationQueue()
    
    // MARK: - Initialization
    
    override init() {
        // Load saved values
        self.bookmarkData = UserDefaults.standard.data(forKey: "watchedFolderBookmark")
        self.autoSyncEnabled = UserDefaults.standard.bool(forKey: "autoSyncEnabled")
        if !UserDefaults.standard.dictionaryRepresentation().keys.contains("autoSyncEnabled") {
            self.autoSyncEnabled = true // Default value
        }
        let savedInterval = UserDefaults.standard.double(forKey: "syncInterval")
        self.syncInterval = savedInterval > 0 ? savedInterval : Constants.syncInterval
        
        super.init()
        
        NSFileCoordinator.addFilePresenter(self)
        updateiCloudAvailability()
        startNetworkMonitoring()
        startFileMonitoring()
        setupSyncTimer()
        
        logger.info("Sync manager initialized")
    }
    
    deinit {
        NSFileCoordinator.removeFilePresenter(self)
        monitor.cancel()
        // Timer cleanup happens automatically via ARC
    }
    
    // MARK: - Public Methods
    
    func setWatchedFolder(_ url: URL) throws {
        bookmarkData = try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        startFileMonitoring()
        logger.info("Watched folder set: \(url.lastPathComponent)")
    }
    
    func performSync() async {
        guard canSync, let sourceURL = watchedFolderURL else {
            logger.info("Sync skipped: prerequisites not met")
            return
        }
        
        syncState = syncState.startingSync()
        logger.info("Sync started")
        
        do {
            guard sourceURL.startAccessingSecurityScopedResource() else {
                throw SyncError.accessDenied(sourceURL)
            }
            defer { sourceURL.stopAccessingSecurityScopedResource() }
            
            let destURL = try destinationURL()
            try createDirectoryIfNeeded(at: destURL)
            
            let files = try collectFiles(from: sourceURL)
            try await syncFiles(files, to: destURL)
            
            let completionDate = Date()
            syncState = syncState.completedSync(at: completionDate)
            recentChanges = []
            logger.info("Sync completed: \(files.count) files")
        } catch {
            let syncError = (error as? SyncError) ?? .syncFailed(error.localizedDescription)
            syncState = syncState.failedSync(with: syncError)
            logger.error("Sync failed: \(error)")
        }
    }
    
    // MARK: - NSFilePresenter Methods
    
    nonisolated func presentedItemDidChange() {
        Task { @MainActor in
            guard autoSyncEnabled else { return }
            logger.info("External change detected")
            await performSync()
        }
    }
    
    // MARK: - Internal Methods
    
    internal func collectFiles(from url: URL) throws -> [FileItem] {
        let keys: [URLResourceKey] = [.isRegularFileKey, .contentModificationDateKey]
        
        let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: keys,
            options: [.skipsPackageDescendants] // Removed .skipsHiddenFiles
        )
        
        return enumerator?.compactMap { item in
            guard let url = item as? URL,
                  let values = try? url.resourceValues(forKeys: Set(keys)),
                  values.isRegularFile == true else { return nil }
            
            let filename = url.lastPathComponent
            
            // Skip system files
            if filename == ".DS_Store" || filename == ".localized" {
                return nil
            }
            
            // For dotfiles, only include allowed ones
            if filename.hasPrefix(".") && !Constants.allowedDotfiles.contains(filename) {
                return nil
            }
            
            return FileItem(
                url: url,
                lastModified: values.contentModificationDate ?? Date()
            )
        } ?? []
    }
    
    internal func setupSyncTimer() {
        let existingTimer = syncTimer
        existingTimer?.invalidate()
        
        guard autoSyncEnabled else { 
            syncTimer = nil
            return 
        }
        
        let newTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { _ in
            Task { @MainActor [weak self] in
                await self?.performSync()
            }
        }
        
        syncTimer = newTimer
        logger.info("Sync timer configured: \(Int(self.syncInterval))s interval")
    }
    
    // MARK: - Private Methods
    
    private func destinationURL() throws -> URL {
        guard let iCloudURL = FileManager.default.url(
            forUbiquityContainerIdentifier: nil
        ) else {
            throw SyncError.iCloudUnavailable
        }
        
        return iCloudURL
            .appendingPathComponent("Documents")
            .appendingPathComponent(Constants.appName)
    }
    
    private func updateiCloudAvailability() {
        let wasAvailable = iCloudAvailable
        iCloudAvailable = FileManager.default.url(
            forUbiquityContainerIdentifier: nil
        ) != nil
        
        if wasAvailable != iCloudAvailable {
            logger.info("iCloud availability changed: \(self.iCloudAvailable)")
        }
    }
    
    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { path in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let wasConnected = self.isConnected
                self.isConnected = path.status == .satisfied
                
                if wasConnected != self.isConnected {
                    self.logger.info("Network status changed: \(self.isConnected ? "connected" : "disconnected")")
                }
            }
        }
        monitor.start(queue: .global(qos: .utility))
    }
    
    private func startFileMonitoring() {
        fileMonitor = nil
        
        guard let url = watchedFolderURL else {
            logger.info("File monitoring skipped: no watched folder")
            return
        }
        
        fileMonitor = FileMonitor(url: url) { changes in
            Task { @MainActor [weak self] in
                guard let self, self.autoSyncEnabled else { return }
                
                self.recentChanges = Array(changes.suffix(10))
                self.logger.info("File changes detected: \(changes.count)")
                await self.performSync()
            }
        }
        
        fileMonitor?.start()
        logger.info("File monitoring started")
    }
    
    private func syncFiles(_ files: [FileItem], to destination: URL) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for file in files {
                group.addTask { [weak self] in
                    guard let self else { return }
                    let destFile = destination.appendingPathComponent(file.url.lastPathComponent)
                    try await self.copyFile(from: file.url, to: destFile)
                }
            }
            try await group.waitForAll()
        }
    }
    
    private func copyFile(from source: URL, to destination: URL) async throws {
        try await withCheckedThrowingContinuation { continuation in
            let coordinator = NSFileCoordinator(filePresenter: self)
            var error: NSError?
            
            coordinator.coordinate(
                readingItemAt: source,
                options: [],
                writingItemAt: destination,
                options: .forReplacing,
                error: &error
            ) { readingURL, writingURL in
                do {
                    if FileManager.default.fileExists(atPath: writingURL.path) {
                        try FileManager.default.removeItem(at: writingURL)
                    }
                    try FileManager.default.copyItem(at: readingURL, to: writingURL)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            
            if let error {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func createDirectoryIfNeeded(at url: URL) throws {
        guard !FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.createDirectory(
            at: url, 
            withIntermediateDirectories: true
        )
    }
}