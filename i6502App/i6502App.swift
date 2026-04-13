import SwiftUI

@main
struct i6502App: App {
    @AppStorage("FontSize") private var fontSize: Double = 14

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(after: .textEditing) {
                Menu("Font Size", systemImage: "textformat.size") {
                    Button("Increase", systemImage: "textformat.size.larger") { fontSize = min(64, fontSize + 1) }
                        .keyboardShortcut("+", modifiers: .command)

                    Button("Decrease", systemImage: "textformat.size.smaller") { fontSize = max(8, fontSize - 1) }
                        .keyboardShortcut("-", modifiers: .command)
                }
            }
        }
    }
}
