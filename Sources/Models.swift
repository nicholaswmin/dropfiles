import Foundation
import SwiftUI

// MARK: - Constants

enum Constants {
    // Business logic
    static let appName = "dropfiles"
    static let syncInterval = 300.0
    static let fileMonitorLatency = 0.5
    static let allowedDotfiles = Set([
        ".vimrc", ".zshrc", ".bashrc", ".gitconfig",
        ".tmux.conf", ".profile", ".bash_profile",
        ".zprofile", ".zshenv", ".gitignore", 
        ".editorconfig", ".npmrc"
    ])
    
    // UI
    static let menuWidth: CGFloat = 280
}

// MARK: - Errors

enum SyncError: LocalizedError, Equatable {
    case accessDenied(URL)
    case networkUnavailable
    case iCloudUnavailable
    case syncFailed(String) // Simplified for Equatable
    
    var errorDescription: String? {
        switch self {
        case .accessDenied(let url): 
            "Cannot access \(url.lastPathComponent)"
        case .networkUnavailable: 
            "Network connection required"
        case .iCloudUnavailable:
            "iCloud Drive not available"
        case .syncFailed(let message): 
            "Sync failed: \(message)"
        }
    }
}

// MARK: - Models

struct FileItem: Identifiable, Sendable {
    let id = UUID()
    let url: URL
    let lastModified: Date
    
    var name: String { url.lastPathComponent }
}

struct SyncState: Sendable {
    let status: SyncStatus
    let lastSyncDate: Date?
    
    enum SyncStatus: Sendable, Equatable {
        case idle
        case syncing
        case success(Date)
        case failure(SyncError)
    }
    
    func startingSync() -> SyncState {
        SyncState(status: .syncing, lastSyncDate: lastSyncDate)
    }
    
    func completedSync(at date: Date) -> SyncState {
        SyncState(status: .success(date), lastSyncDate: date)
    }
    
    func failedSync(with error: SyncError) -> SyncState {
        SyncState(status: .failure(error), lastSyncDate: lastSyncDate)
    }
    
    var statusIcon: String {
        switch status {
        case .idle: "icloud"
        case .syncing: "icloud.and.arrow.up.and.arrow.down"
        case .success: "icloud.fill"
        case .failure: "icloud.slash"
        }
    }
    
    var statusText: String {
        switch status {
        case .idle:
            "Ready to sync"
        case .syncing:
            "Syncing..."
        case .success(let date):
            "Last sync: \(date.formatted(.relative(presentation: .numeric)))"
        case .failure(let error):
            error.localizedDescription
        }
    }
    
    var statusColor: Color {
        switch status {
        case .idle: .primary
        case .syncing: .blue
        case .success: .green
        case .failure: .red
        }
    }
}