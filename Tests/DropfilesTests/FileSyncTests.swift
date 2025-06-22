import Testing
import Foundation
@testable import Dropfiles

@Suite("Sync State Management")
struct SyncStateTests {
    
    @Test("State transitions are immutable")
    func test_syncState_transitions_areImmutable() {
        let initial = SyncState(status: .idle, lastSyncDate: nil)
        
        let syncing = initial.startingSync()
        #expect(initial.status == .idle) // Original unchanged
        #expect(syncing.status == .syncing)
        
        let completed = syncing.completedSync(at: Date())
        #expect(syncing.status == .syncing) // Original unchanged
        #expect(completed.lastSyncDate != nil)
        
        let failed = completed.failedSync(with: .networkUnavailable)
        #expect(completed.lastSyncDate != nil) // Preserved
        #expect(failed.lastSyncDate != nil)
    }
    
    @Test("Status computed properties")
    func test_syncState_statusProperties_computeCorrectly() {
        let states: [(SyncState, String, String)] = [
            (SyncState(status: .idle, lastSyncDate: nil),
             "icloud", "Ready to sync"),
            (SyncState(status: .syncing, lastSyncDate: nil),
             "icloud.and.arrow.up.and.arrow.down", "Syncing..."),
            (SyncState(status: .failure(.networkUnavailable), lastSyncDate: nil),
             "icloud.slash", "Network connection required")
        ]
        
        for (state, icon, text) in states {
            #expect(state.statusIcon == icon)
            #expect(state.statusText == text)
        }
    }
}

@Suite("File Filtering")  
struct FileFilterTests {
    
    @Test("Dotfile filtering")
    func test_fileFilter_dotfiles_correctlyFiltered() {
        let monitor = FileMonitor(url: URL(fileURLWithPath: "/tmp")) { _ in }
        
        // Allowed dotfiles
        #expect(monitor.shouldIncludeFile(".vimrc"))
        #expect(monitor.shouldIncludeFile(".zshrc"))
        #expect(monitor.shouldIncludeFile(".gitconfig"))
        
        // System files excluded
        #expect(!monitor.shouldIncludeFile(".DS_Store"))
        #expect(!monitor.shouldIncludeFile(".localized"))
    }
}

@Suite("Error Handling")
struct ErrorTests {
    
    @Test("Error descriptions")
    func test_syncError_descriptions_areHelpful() {
        let errors: [(SyncError, String)] = [
            (.networkUnavailable, "Network connection required"),
            (.iCloudUnavailable, "iCloud Drive not available"),
            (.accessDenied(URL(fileURLWithPath: "/test")), "Cannot access test")
        ]
        
        for (error, expected) in errors {
            #expect(error.localizedDescription == expected)
        }
    }
}