import SwiftUI
import SwiftData

@main
struct KopiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([ClipboardItem.self])
            let config = ModelConfiguration("KopiStore", schema: schema)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        appDelegate.modelContainer = modelContainer
    }

    var body: some Scene {
        Settings {
            SettingsView()
                .modelContainer(modelContainer)
        }
    }
}
