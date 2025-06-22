import SwiftUI

struct MenuContentView: View {
    @Environment(FileSyncManager.self) private var syncManager
    @State private var showPreferences = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            statusSection
            Divider()
            actionSection  
            Divider()
            utilitySection
        }
        .frame(width: Constants.menuWidth)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .sheet(isPresented: $showPreferences) {
            PreferencesView()
        }
    }
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: syncManager.statusIcon)
                    .foregroundStyle(syncManager.statusColor)
                    .symbolEffect(.bounce, value: syncManager.syncState.status)
                
                Text(syncManager.statusText)
                    .font(.headline)
                
                Spacer()
            }
            
            HStack {
                Image(systemName: syncManager.isConnected ? "wifi" : "wifi.slash")
                    .foregroundStyle(syncManager.isConnected ? .green : .red)
                Text(syncManager.isConnected ? "Connected" : "No connection")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
            if !syncManager.iCloudAvailable {
                HStack {
                    Image(systemName: "exclamationmark.icloud")
                        .foregroundStyle(.orange)
                    Text("iCloud Drive unavailable")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            
            if let firstChange = syncManager.recentChanges.first {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(.secondary)
                    Text("Recent: \(firstChange.url.lastPathComponent)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var actionSection: some View {
        Button("Sync Now") {
            Task { await syncManager.performSync() }
        }
        .disabled(!syncManager.canSync)
        .buttonStyle(.borderedProminent)
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }
    
    private var utilitySection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button("Preferences...") { 
                showPreferences = true 
            }
            .buttonStyle(.plain)
            
            Button("Quit") { 
                NSApplication.shared.terminate(nil) 
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
    }
}

struct PreferencesView: View {
    @Environment(FileSyncManager.self) private var syncManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Preferences")
                .font(.title2)
                .fontWeight(.semibold)
            
            GroupBox("Watched Folder") {
                VStack(alignment: .leading, spacing: 8) {
                    Button("Choose Folder...") {
                        let panel = NSOpenPanel()
                        panel.canChooseDirectories = true
                        panel.canChooseFiles = false
                        panel.message = "Choose a folder to sync to iCloud"
                        
                        if panel.runModal() == .OK, let url = panel.url {
                            try? syncManager.setWatchedFolder(url)
                        }
                    }
                }
            }
            
            GroupBox("Sync Settings") {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Auto Sync", isOn: Binding(
                        get: { syncManager.autoSyncEnabled },
                        set: { syncManager.autoSyncEnabled = $0 }
                    ))
                    
                    HStack {
                        Text("Sync Interval:")
                        Slider(
                            value: Binding(
                                get: { syncManager.syncInterval / 60 },
                                set: { syncManager.syncInterval = $0 * 60 }
                            ),
                            in: 1...60,
                            step: 1
                        )
                        Text("\(Int(syncManager.syncInterval / 60))m")
                            .monospacedDigit()
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}