import i6502Assembler
import SwiftUI

struct ContentView: View {
    @AppStorage("AppTheme") private var appTheme: AppTheme = .defaultDark
    let codeStorage = CodeStorage()

    var body: some View {
        TabView {
            Tab("Editor", systemImage: "pencil") {
                NavigationStack {
                    EditorView(codeStorage: codeStorage)
                }
            }
            Tab("Emulator", systemImage: "display") {
                NavigationStack {
                    EmulatorView(codeStorage: codeStorage)
                }
            }
        }
        .background(appTheme.palette.backgroundPrimary.ignoresSafeArea())
    }
}
