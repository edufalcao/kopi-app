//
//  KopiApp.swift
//  Kopi
//
//  Created by Eduardo Falcão Lima on 31/03/26.
//

import SwiftUI
import SwiftData

@main
struct KopiApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([ClipboardItem.self])
            let config = ModelConfiguration(
                "KopiStore",
                schema: schema
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [config]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        Settings {
            Text("Kopi Settings")
                .frame(width: 300, height: 200)
        }
        .modelContainer(modelContainer)
    }
}
