import Foundation
import CoreServices

final class FileMonitor: @unchecked Sendable {
    typealias ChangeHandler = @Sendable ([FileChange]) async -> Void
    
    struct FileChange: Sendable, Equatable {
        let url: URL
        let type: ChangeType
        
        enum ChangeType: Sendable, Equatable {
            case created, modified, deleted
        }
    }
    
    private var eventStream: FSEventStreamRef?
    private let changeHandler: ChangeHandler
    private let watchedURL: URL
    
    init(url: URL, changeHandler: @escaping ChangeHandler) {
        self.watchedURL = url
        self.changeHandler = changeHandler
    }
    
    func start() {
        guard eventStream == nil else { return }
        
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        
        eventStream = FSEventStreamCreate(
            nil,
            { (_, contextInfo, numEvents, eventPaths, eventFlags, _) in
                let monitor = Unmanaged<FileMonitor>
                    .fromOpaque(contextInfo!)
                    .takeUnretainedValue()
                
                let paths = unsafeBitCast(eventPaths, to: NSArray.self) as! [String]
                let changes = monitor.processEvents(paths: paths, flags: eventFlags, count: numEvents)
                
                if !changes.isEmpty {
                    Task { await monitor.changeHandler(changes) }
                }
            },
            &context,
            [watchedURL.path] as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            Constants.fileMonitorLatency,
            FSEventStreamCreateFlags(
                kFSEventStreamCreateFlagUseCFTypes |
                kFSEventStreamCreateFlagFileEvents |
                kFSEventStreamCreateFlagWatchRoot |
                kFSEventStreamCreateFlagNoDefer
            )
        )
        
        FSEventStreamSetDispatchQueue(eventStream!, DispatchQueue.global(qos: .utility))
        FSEventStreamStart(eventStream!)
    }
    
    deinit {
        if let stream = eventStream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
        }
    }
    
    private func processEvents(
        paths: [String],
        flags: UnsafePointer<FSEventStreamEventFlags>,
        count: Int
    ) -> [FileChange] {
        (0..<count).compactMap { i in
            let url = URL(fileURLWithPath: paths[i])
            let filename = url.lastPathComponent
            
            // Skip system files
            guard filename != ".DS_Store" && filename != ".localized" else { 
                return nil 
            }
            
            // Filter dotfiles
            if filename.hasPrefix(".") && !Constants.allowedDotfiles.contains(filename) {
                return nil
            }
            
            // Parse change type
            let flag = flags[i]
            let type: FileChange.ChangeType? = 
                if flag & UInt32(kFSEventStreamEventFlagItemCreated) != 0 { .created }
                else if flag & UInt32(kFSEventStreamEventFlagItemModified) != 0 { .modified }
                else if flag & UInt32(kFSEventStreamEventFlagItemRemoved) != 0 { .deleted }
                else { nil }
            
            return type.map { FileChange(url: url, type: $0) }
        }
    }
    
    // Test helper
    func shouldIncludeFile(_ filename: String) -> Bool {
        guard filename != ".DS_Store" && filename != ".localized" else { 
            return false 
        }
        if filename.hasPrefix(".") && !Constants.allowedDotfiles.contains(filename) {
            return false
        }
        return true
    }
}