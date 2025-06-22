import SwiftUI

@main
struct DropfilesApp: App {
    @State private var syncManager = FileSyncManager()
    
    var body: some Scene {
        MenuBarExtra("dropfiles", systemImage: syncManager.statusIcon) {
            MenuContentView()
                .environment(syncManager)
        }
        .menuBarExtraStyle(.window)
    }
}