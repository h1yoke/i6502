import i6502Assembler
import SwiftUI

struct ContentView: View {
    @AppStorage("AppTheme") private var appTheme: AppTheme = .defaultDark
    @AppStorage("ForcedDarkMode") private var forcedDarkMode: Bool = false

    var body: some View {
        TabView {
            Tab("Editor", systemImage: "pencil") {
                NavigationStack {
                    EditorView()
                }
            }
            if UIDevice.current.userInterfaceIdiom == .phone {
                Tab("Hexdump", systemImage: "number") {
                    HexdumpTabView(originalText: "lda $10")
                }
            }
            Tab("Emulator", systemImage: "display") {
                Text("TBD!")
            }
        }
        .background(appTheme.palette.backgroundPrimary.ignoresSafeArea())
    }
}

#Preview {
    ContentView()
}
