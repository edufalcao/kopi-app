import SwiftUI
import SwiftData
import KeyboardShortcuts
import LaunchAtLogin

struct SettingsView: View {
    @AppStorage("purgeDays") private var purgeDays: Int = 30
    @Environment(\.modelContext) private var modelContext
    @State private var showClearConfirmation = false

    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            shortcutsTab
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }

            storageTab
                .tabItem {
                    Label("Storage", systemImage: "internaldrive")
                }
        }
        .frame(width: 420, height: 260)
    }

    private var generalTab: some View {
        Form {
            LaunchAtLogin.Toggle("Launch at login")

            Section("About") {
                LabeledContent("Version") {
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var shortcutsTab: some View {
        Form {
            Section("Global Shortcut") {
                LabeledContent("Toggle Quick Panel") {
                    KeyboardShortcuts.Recorder(for: .toggleQuickPanel)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var storageTab: some View {
        Form {
            Section("Auto-Purge") {
                Picker("Delete items older than", selection: $purgeDays) {
                    Text("7 days").tag(7)
                    Text("14 days").tag(14)
                    Text("30 days").tag(30)
                    Text("60 days").tag(60)
                    Text("90 days").tag(90)
                }
            }

            Section("Danger Zone") {
                Button("Clear All History", role: .destructive) {
                    showClearConfirmation = true
                }
                .confirmationDialog(
                    "Clear all clipboard history?",
                    isPresented: $showClearConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Clear All", role: .destructive) {
                        clearAllHistory()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will delete all clipboard history including pinned items. This cannot be undone.")
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func clearAllHistory() {
        let imageStorage = ImageStorageService()
        let store = ClipboardStore(modelContext: modelContext, imageStorage: imageStorage)
        try? store.clearAll()
    }
}
