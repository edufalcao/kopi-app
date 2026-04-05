import SwiftUI
import SwiftData
import KeyboardShortcuts
import LaunchAtLogin

struct SettingsView: View {
    private static let donateURL = URL(string: "https://buymeacoffee.com/wilii5u96y")!

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

            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }

            donateTab
                .tabItem {
                    Label("Donate", systemImage: "heart")
                }
        }
        .frame(width: 500, height: 260)
    }

    private var generalTab: some View {
        Form {
            Section("Startup") {
                LaunchAtLogin.Toggle("Launch at login")
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

    private var aboutTab: some View {
        Form {
            Section("Application") {
                LabeledContent("Version") {
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                }
            }

            Section("Links") {
                Link(destination: URL(string: "https://edufalcao.com")!) {
                    Label("edufalcao.com", systemImage: "globe")
                }
                Link(destination: URL(string: "https://github.com/edufalcao/kopi-app")!) {
                    Label("GitHub Repository", systemImage: "chevron.left.forwardslash.chevron.right")
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var donateTab: some View {
        Form {
            Section("Support Kopi") {
                Link(destination: Self.donateURL) {
                    Label("Buy Me a Coffee", systemImage: "cup.and.saucer.fill")
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
